# frozen_string_literal: true
# typed: true

require 'csv'


class Api02Controller < ApplicationController
  def base_url
    "https://#{request.host_with_port}"
  end

  def projects
    row_projects = query_json('projects($1, $2, $3)', [base_url, nil, nil])
    puts row_projects.inspect

    projects = row_projects.nil? ? [] : JSON.parse(row_projects)
    projects = projects.transform_values { |project|
      project['themes'].transform_values { |theme|
        theme.except('articles')
      }
      project
    }
    respond_to do |format|
      format.json { render json: projects }
    end
  end

  def project
    project_slug, theme_slug = project_theme_params

    row_project = query_json('projects($1, $2, $3)', [base_url, project_slug, theme_slug])

    if row_project.nil?
      render status: :not_found
      return
    end

    project = JSON.parse(row_project).values.first
    if !project['themes']
      render status: :not_found
      return
    end
    project['themes'] = project['themes'].transform_values { |theme|
      theme.except('articles')
    }
    respond_to do |format|
      format.json { render json: project }
    end
  end

  def articles
    project_slug, theme_slug = project_theme_params

    row_project = query_json('project($1, $2)', [base_url, project_slug])

    if row_project.nil?
      render status: :not_found
      return
    end

    articles = (JSON.parse(row_project)['themes'] || []).find{ |theme| theme['slug'] == theme_slug }&.[]('articles') || []
    respond_to do |format|
      format.json {
        render json: articles
      }
    end
  end

  def article
    project_slug, _theme, article_slug = params.require(%i[project theme slug])

    puts [project_slug, article_slug].inspect
    article = query_json('article($1, $2)', [project_slug, article_slug])
    puts article.inspect

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

  def menu
    project_slug, theme_slug = project_theme_params

    menu_items = query_json('menu($1, $2)', [project_slug, theme_slug])

    if menu_items.nil?
      render status: :not_found
      return
    end

    respond_to do |format|
      format.json { render plain: menu_items }
    end
  end

  def poi
    project_slug, theme_slug = project_theme_params
    ref_id = id_to_ref(params.require(:id))

    pois = query_pois(
      base_url,
      project_slug,
      theme_slug,
      nil,
      ref_id[:id].nil? ? nil : PG::TextEncoder::Array.new.encode([ref_id[:id]]),
      ref_id[:ref].nil? ? nil : [ref_id[:ref]].to_json,
      params[:geometry_as],
      params[:short_description],
      nil,
      nil,
      params[:deps] == 'true',
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
    end
  end

  def pois
    project_slug, theme_slug = project_theme_params
    category_id = (params[:category_id] || params[:idmenu])&.to_i # idmenu is deprecated
    ref_ids = params[:ids]&.split(',')&.collect{ |ref_id|
      id_to_ref(ref_id)
    }

    pois = query_pois(
      base_url,
      project_slug,
      theme_slug,
      category_id,
      ref_ids.nil? ? nil : PG::TextEncoder::Array.new.encode(ref_ids.pluck(:id).compact),
      ref_ids.nil? ? nil : ref_ids.pluck(:ref).compact.to_json,
      params[:geometry_as],
      ActiveModel::Type::Boolean.new.cast(params[:short_description]),
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

  def pois_category
    params.require(%i[project theme category_id])
    pois
  end

  def attribute_translations
    params.require(%i[project theme lang])
    project_slug, theme_slug = project_theme_params
    lang = params[:lang]

    attribute_translations = query_json('attribute_translations($1, $2, $3)', [project_slug, theme_slug, lang]) || {}
    respond_to do |format|
      format.json {
        render plain: attribute_translations
      }
    end
  end

  private

  def id_to_ref(ref_id)
    if ref_id.start_with?('ref:')
      ref = ref_id.split(':', 2).last.rpartition(':')
      { ref: { ref[0] => ref[-1] } }
    else
      { id: ref_id.to_i }
    end
  end

  def query_json(subject, params)
    PG.connect(host: ENV.fetch('POSTGRES_HOST', nil), dbname: ENV['RAILS_ENV'] == 'test' ? 'test' : 'postgres', user: ENV.fetch('POSTGRES_USER', nil), password: ENV.fetch('POSTGRES_PASSWORD', nil)) { |conn|
      conn.exec('SET search_path TO api02,public')
      conn.exec_params("SELECT * FROM #{subject}", params) { |result|
        result.first&.[]('d')
      }
    }
  end

  def query_rows(subject, params)
    PG.connect(host: ENV.fetch('POSTGRES_HOST', nil), dbname: ENV['RAILS_ENV'] == 'test' ? 'test' : 'postgres', user: ENV.fetch('POSTGRES_USER', nil), password: ENV.fetch('POSTGRES_PASSWORD', nil)) { |conn|
      conn.exec('SET search_path TO api01,public')
      conn.exec_params("SELECT * FROM #{subject}", params) { |results|
        results.to_a
      }
    }
  end

  def query_pois(base_url, project_slug, theme_slug, category_id, ids, refs, geometry_as, short_description, start_date, end_date, deps, cliping_polygon_slug)
    query_rows('pois($1, $2, $3, $4, $5::bigint[], $6::jsonb, $7, $8, $9, $10, $11, $12)', [
      base_url,
      project_slug,
      theme_slug,
      category_id,
      ids,
      refs,
      geometry_as,
      short_description,
      start_date,
      end_date,
      deps,
      cliping_polygon_slug,
    ]).collect{ |poi|
      poi['feature']
    }
  end

  def project_theme_params
    params.require(%i[project theme])
  end

  def hash_path(hash, path = [])
    hash.collect{ |key, value|
      if value.is_a?(Hash)
        hash_path(value, path + [key])
      else
        [path + [key]]
      end
    }.flatten(1)
  end
end
