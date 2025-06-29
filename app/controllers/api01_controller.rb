# frozen_string_literal: true
# typed: true

require 'csv'


class Api01Controller < ApplicationController
  def base_url
    "https://#{request.host_with_port}"
  end

  def settings
    project_slug, = project_theme_params

    row_project = query('project($1, $2)', [base_url, project_slug])

    if row_project.nil?
      render status: :not_found
      return
    end

    project = JSON.parse(row_project)
    respond_to do |format|
      format.json { render json: project.except('articles') }
    end
  end

  def articles
    project_slug, = project_theme_params

    row_project = query('project($1, $2)', [base_url, project_slug])

    if row_project.nil?
      render status: :not_found
      return
    end

    articles = JSON.parse(row_project)['articles'] || []
    respond_to do |format|
      format.json {
        render json: articles
      }
    end
  end

  def article
    project_slug, _theme, article_slug = params.require(%i[project theme slug])

    puts [project_slug, article_slug].inspect
    article = query('article($1, $2)', [project_slug, article_slug])
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

    menu_items = query('menu($1, $2)', [project_slug, theme_slug])

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
    if params.require(:id).start_with?('ref:')
      ref = params.require(:id).split(':', 2).last.rpartition(':')
      ref[0] = 'FR:CRTA' if ref[0] == 'sirtaqui'
      ref = [ref[0], ref[-1]]
    else
      id = params.require(:id).to_i
    end

    pois = query('pois($1, $2, $3, $4, $5::bigint[], $6::text[], $7, $8, $9, $10, $11, $12)', [
      base_url,
      project_slug,
      theme_slug,
      nil,
      id.nil? ? nil : PG::TextEncoder::Array.new.encode([id]),
      PG::TextEncoder::Array.new.encode(ref),
      params[:geometry_as],
      params[:short_description],
      nil,
      nil,
      params[:deps] == 'true',
      nil,
    ])

    if pois.nil?
      render status: :not_found
      return
    end

    respond_to do |format|
      format.geojson {
        if params[:deps] == 'true'
          render plain: pois
        else
          render json: JSON.parse(pois)['features'][0]
        end
      }
    end
  end

  def pois
    project_slug, theme_slug = project_theme_params
    category_id = (params[:category_id] || params[:idmenu])&.to_i # idmenu is deprecated
    ids = params[:ids]&.split(',')&.collect(&:to_i)

    pois = query('pois($1, $2, $3, $4, $5::bigint[], $6::text[], $7, $8, $9, $10, $11, $12)', [
      base_url,
      project_slug,
      theme_slug,
      category_id,
      PG::TextEncoder::Array.new.encode(ids),
      nil,
      params[:geometry_as],
      ActiveModel::Type::Boolean.new.cast(params[:short_description]),
      params[:start_date],
      params[:end_date],
      nil,
      params[:cliping_polygon_slug],
    ]) || {}

    respond_to do |format|
      format.geojson { render plain: pois }
      format.csv {
        features = JSON.parse(pois)['features']
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

    attribute_translations = query('attribute_translations($1, $2, $3)', [project_slug, theme_slug, lang]) || {}
    render json: attribute_translations
  end

  private

  def query(subject, params)
    PG.connect(host: ENV.fetch('POSTGRES_HOST', nil), dbname: ENV['RAILS_ENV'] == 'test' ? 'test' : 'postgres', user: ENV.fetch('POSTGRES_USER', nil), password: ENV.fetch('POSTGRES_PASSWORD', nil)) { |conn|
      conn.exec('SET search_path TO api01,public')
      conn.exec_params("SELECT * FROM #{subject}", params) { |result|
        row = result.first&.[]('d')
      }
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
