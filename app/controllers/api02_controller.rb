# frozen_string_literal: true
# typed: strict

require 'csv'
require 'active_storage/filename'

class Api02Controller < ApplicationController
  extend T::Sig

  sig { returns(String) }
  def base_url
    "https://#{request.host_with_port}"
  end

  sig { void }
  def projects
    projects = self.class.fetch_projects(@db, base_url, nil, nil)
    respond_to do |format|
      format.json { render json: projects }
    end
  end

  sig { void }
  def project
    project_slug, theme_slug = project_theme_params

    projects = self.class.fetch_projects(@db, base_url, project_slug, theme_slug)

    if projects.dig(project_slug, 'themes', theme_slug).nil?
      render status: :not_found
      return
    end

    respond_to do |format|
      format.json { render json: projects[project_slug] }
    end
  end

  sig { params(conn: PG::Connection, base_url: String, project_slug: T.nilable(String), theme_slug: T.nilable(String)).returns(T::Hash[String, T.untyped]) }
  def self.fetch_projects(conn, base_url, project_slug, theme_slug)
    q = query_json(conn, 'projects($1, $2, $3)', [base_url, project_slug, theme_slug])
    return {} if q.nil?

    projects = JSON.parse(q) || []
    projects.transform_values { |project|
      project['themes'].transform_values { |theme|
        theme.except!('articles')
      }
      project
    }
  end

  sig { void }
  def articles
    project_slug, theme_slug = project_theme_params

    articles = self.class.fetch_articles(@db, base_url, project_slug, theme_slug)

    if articles.nil?
      render status: :not_found
      return
    end

    respond_to do |format|
      format.json {
        render json: articles
      }
    end
  end

  sig { params(conn: PG::Connection, base_url: String, project_slug: String, theme_slug: String).returns(T.nilable(T::Array[T::Hash[String, T.untyped]])) }
  def self.fetch_articles(conn, base_url, project_slug, theme_slug)
    q = query_json(conn, 'projects($1, $2, $3)', [base_url, project_slug, theme_slug])
    return if q.nil?

    projects = JSON.parse(q)
    return if projects.nil?

    theme = projects.first[1]['themes'].first[1]
    theme['articles'] || []
  end

  sig { void }
  def article
    project_slug, _theme, article_slug = params.require(%i[project theme slug])

    article = self.class.fetch_article(@db, project_slug, article_slug)

    if article.nil?
      render status: :not_found
      return
    end

    respond_to do |format|
      format.html {
        render body: article
      }
    end
  end

  sig { params(conn: PG::Connection, project_slug: String, article_slug: String).returns(T.nilable(String)) }
  def self.fetch_article(conn, project_slug, article_slug)
    query_json(conn, 'article($1, $2)', [project_slug, article_slug])
  end

  sig { void }
  def menu
    project_slug, theme_slug = project_theme_params

    menu_items = self.class.fetch_menu(@db, project_slug, theme_slug)

    if menu_items.nil?
      render status: :not_found
      return
    end

    respond_to do |format|
      format.json { render plain: menu_items }
    end
  end

  sig { params(conn: PG::Connection, project_slug: String, theme_slug: String).returns(T.nilable(String)) }
  def self.fetch_menu(conn, project_slug, theme_slug)
    query_json(conn, 'menu($1, $2)', [project_slug, theme_slug])
  end

  sig { void }
  def poi
    project_slug, theme_slug = project_theme_params
    ref_id = id_to_ref(params.require(:id))

    pois = self.class.fetch_pois(
      @db,
      base_url,
      project_slug,
      theme_slug,
      nil,
      ref_id[:id].nil? ? nil : [ref_id[:id]],
      ref_id[:ref].nil? ? nil : [ref_id[:ref]],
      params[:geometry_as],
      params[:short_description],
      nil,
      nil,
      params[:deps],
      nil,
    )

    if pois.empty?
      render status: :not_found
      return
    end

    respond_to do |format|
      format.geojson {
        if params[:deps] == 'true'
          render plain: "{\"type\": \"FeatureCollection\", \"features\": [
#{pois.join(",\n")}
]}"
        else
          render plain: pois
        end
      }
      format.gpx {
        name, gpx = poi_deps_as_gpx(pois)
        if gpx.nil?
          render status: :not_acceptable
          return
        end

        send_data gpx, filename: ActiveStorage::Filename.new("#{name || params.require(:id)}.gpx").sanitized
      }
    end
  end

  sig { void }
  def pois
    project_slug, theme_slug = project_theme_params
    category_id = (params[:category_id] || params[:idmenu])&.to_i # idmenu is deprecated
    ref_ids = params[:ids]&.split(',')&.collect{ |ref_id|
      id_to_ref(ref_id)
    }

    pois = self.class.fetch_pois(
      @db,
      base_url,
      project_slug,
      theme_slug,
      category_id,
      ref_ids&.pluck(:id)&.compact,
      ref_ids&.pluck(:ref)&.compact,
      params[:geometry_as],
      params[:short_description],
      params[:start_date],
      params[:end_date].presence || Time.zone.today.iso8601,
      nil,
      params[:cliping_polygon_slug],
    )

    respond_to do |format|
      format.geojson {
        render plain: "{\"type\": \"FeatureCollection\", \"features\": [
#{pois.join(",\n")}
]}"
      }
      format.csv {
        features = pois.collect{ |poi| JSON.parse(poi) }
        pois_hash_path = features.collect{ |poi| hash_path(poi['properties'].except('display', 'editorial')) }.flatten(1).uniq.sort

        # UTF-8 BOM + CSV content
        csv_string = "\xEF\xBB\xBF"
        csv_string += CSV.generate(col_sep: ';') { |csv|
          csv << pois_hash_path.collect{ |path| path.join(':') } + %w[lon lat]
          features.each{ |poi|
            csv << pois_hash_path.collect{ |path| poi['properties'].dig(*path) }.collect{ |value|
              value.is_a?(Array) ? value.join(';') : value
            } + (poi['geometry']['type'] == 'Point' ? poi['geometry']['coordinates'] : [nil, nil])
          }
        }
        send_data(csv_string, filename: "#{project_slug}-#{theme_slug}-#{category_id || ''}-#{DateTime.now.strftime('%Y%m%d')}.csv")
      }
    end
  end

  sig { void }
  def pois_schema
    project_slug, _theme_slug = project_theme_params

    pois_json_schema = self.class.fetch_pois_schema(@db, project_slug)
    respond_to do |format|
      format.json {
        render plain: pois_json_schema
      }
    end
  end

  sig { params(conn: PG::Connection, project_slug: String).returns(String) }
  def self.fetch_pois_schema(conn, project_slug)
    query_json(conn, 'pois_json_schema($1)', [project_slug]) || '{}'
  end

  sig { void }
  def pois_category
    params.require(%i[project theme category_id])
    pois
  end

  sig { void }
  def attribute_translations
    params.require(%i[project theme lang])
    project_slug, theme_slug = project_theme_params
    lang = params[:lang]

    attribute_translations = self.class.fetch_attribute_translations(@db, project_slug, theme_slug, lang)
    respond_to do |format|
      format.json {
        render plain: attribute_translations
      }
    end
  end

  sig { params(conn: PG::Connection, project_slug: String, theme_slug: String, lang: String).returns(String) }
  def self.fetch_attribute_translations(conn, project_slug, theme_slug, lang)
    query_json(conn, 'attribute_translations($1, $2, $3)', [project_slug, theme_slug, lang]) || '{}'
  end

  sig { params(conn: PG::Connection, subject: String, params: T::Array[T.untyped]).returns(T.nilable(String)) }
  def self.query_json(conn, subject, params)
    conn.exec('SET search_path TO api02,public')
    conn.exec_params("SELECT * FROM #{subject}", params) { |result|
      result.first&.[]('d')
    }
  end

  sig { params(conn: PG::Connection, subject: String, params: T::Array[T.untyped]).returns(T::Array[T::Hash[String, T.untyped]]) }
  def self.query_rows(conn, subject, params)
    conn.exec('SET search_path TO api02,public')
    conn.exec_params("SELECT * FROM #{subject}", params, &:to_a)
  end

  sig {
    params(
      conn: PG::Connection,
      base_url: String,
      project_slug: String,
      theme_slug: String,
      category_id: T.nilable(Integer),
      ids: T.nilable(T::Array[Integer]),
      refs: T.nilable(T::Array[String]),
      geometry_as: T.nilable(String),
      short_description: T.nilable(String),
      start_date: T.nilable(String),
      end_date: T.nilable(String),
      deps: T.nilable(String),
      cliping_polygon_slug: T.nilable(String),
    ).returns(T::Array[String])
  }
  def self.fetch_pois(conn, base_url, project_slug, theme_slug, category_id, ids, refs, geometry_as, short_description, start_date, end_date, deps, cliping_polygon_slug)
    query_rows(conn, 'pois($1, $2, $3, $4, $5::bigint[], $6::jsonb, $7, $8, $9, $10, $11, $12)', [
      base_url,
      project_slug,
      theme_slug,
      category_id,
      ids.nil? ? nil : PG::TextEncoder::Array.new.encode(ids),
      refs&.to_json,
      geometry_as,
      short_description,
      start_date,
      end_date,
      deps,
      cliping_polygon_slug,
    ]).collect{ |poi|
      feature = poi['feature']
      report_issue_url_template = poi['report_issue_url_template']
      if !report_issue_url_template.nil?
        report_issue_values = JSON.parse(poi['report_issue_values'])
        report_issue_url = URITemplate.new(report_issue_url_template).expand(report_issue_values)
        feature = feature.gsub('__report_issue_url_template__', report_issue_url)
      end
      feature
    }
  end

  private

  sig { params(ref_id: String).returns(T::Hash[Symbol, T.untyped]) }
  def id_to_ref(ref_id)
    if ref_id.start_with?('ref:')
      ref = (ref_id.split(':', 2).last || '').rpartition(':')
      { ref: { ref[0] => ref[-1] } }
    else
      { id: ref_id.to_i }
    end
  end

  sig { returns([String, String]) }
  def project_theme_params
    T.cast(params.require(%i[project theme]), [String, String])
  end

  sig { params(hash: T::Hash[String, T.untyped], path: T::Array[String]).returns(T::Array[T::Array[String]]) }
  def hash_path(hash, path = [])
    hash.collect{ |key, value|
      if value.is_a?(Hash)
        hash_path(value, path + [key])
      else
        [path + [key]]
      end
    }.flatten(1)
  end

  sig { params(geojson: T::Hash[String, T.untyped], xml: T.untyped).returns([T.nilable(String), T.nilable(String), T.nilable(String)]) }
  def poi_meta(geojson, xml)
    name = geojson.dig('properties', 'name', 'fr-FR')
    desc = geojson.dig('properties', 'description', 'fr-FR', 'value')
    link = geojson.dig('properties', 'editorial', 'website:details', 'fr-FR')
    xml.name(name) if name.present?
    xml.desc(desc) if desc.present?
    xml.link(link) if link.present?
    [name, desc, link]
  end

  sig { params(pois: T::Array[String]).returns(T.nilable([T.nilable(String), String])) }
  def poi_deps_as_gpx(pois)
    pois = pois.collect{ |poi| JSON.parse(poi) }

    geojson, deps = pois.partition{ |poi| !poi.dig('properties', 'metadata', 'dep_ids').nil? }
    geojson = pois if geojson.empty?
    geojson = geojson.first
    geometry = geojson['geometry']
    if geometry.nil? || !%w[LineString MultiLineString].include?(geometry['type'])
      return
    end

    waypoints, deps = deps.partition{ |poi|
      poi.dig('properties', 'route', 'fr-FR', 'waypoint:type').nil?
    }
    deps_index = deps.index_by{ |poi| poi.dig('properties', 'metadata', 'id') }.compact
    waypoints_index = waypoints.index_by{ |poi| poi.dig('properties', 'metadata', 'id') }.compact
    dep_ids = geojson.dig('properties', 'metadata', 'dep_ids')

    name = T.let(nil, T.nilable(String))
    xml = T.let(Builder::XmlMarkup.new, T.untyped) # Avoid typing error on builder
    xml.instruct!(:xml, version: '1.0')
    xml.gpx(xmlns: 'http://www.topografix.com/GPX/1/1', version: '1.1') {
      xml.metadata {
        name, = poi_meta(geojson, xml)
        # <author><name>Author name</name></author>
      }
      dep_ids.each { |dep_id|
        dep = deps_index[dep_id]
        next if dep.nil? || dep.dig('geometry', 'type') != 'Point'

        point = dep['geometry']['coordinates']
        xml.wpt(lon: point[0], lat: point[1]) { poi_meta(dep, xml) }
      }
      if !waypoints_index.empty?
        xml.rte {
          # <type>
          dep_ids.each { |waypoint_id|
            waypoint = waypoints_index[waypoint_id]
            next if waypoint.nil? || waypoint.dig('geometry', 'type') != 'Point'

            point = waypoint['geometry']['coordinates']
            xml.rtept(lon: point[0], lat: point[1]) { poi_meta(waypoint, xml) }
          }
        }
      end
      xml.trk {
        coordinates = geometry['type'] == 'MultiLineString' ? geometry['coordinates'] : [geometry['coordinates']]
        coordinates.each{ |segement|
          xml.trkseg {
            segement.each{ |point| xml.trkpt(lon: point[0], lat: point[1]) }
          }
        }
      }
    }

    [name, T.cast(xml.target!, String)]
  end
end
