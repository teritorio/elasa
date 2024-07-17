# frozen_string_literal: true
# typed: true

require 'csv'


class Api01Controller < ApplicationController
  def settings
    project_slug, = project_theme_params

    project = query('project($1)', [project_slug])
    render json: project.except('articles')
  end

  def articles
    project_slug, = project_theme_params

    project = query('project($1)', [project_slug])
    render json: project['articles'].collect{ |article|
      {
        url: article['url']['fr'],
        title: article['title']['fr'],
      }
    }
  end

  def menu
    project_slug, theme_slug = project_theme_params

    menu_items = query('menu($1, $2)', [project_slug, theme_slug])
    render json: menu_items
  end

  def poi
    project_slug, theme_slug = project_theme_params
    id = params.require(:id).to_i

    pois = query('pois($1, $2, $3, $4::bigint[], $5, $6, $7, $8, $9)', [
      project_slug,
      theme_slug,
      nil,
      PG::TextEncoder::Array.new.encode([id]),
      params[:geometry_as],
      params[:short_description],
      nil,
      nil,
      params[:deps] == 'true',
    ])
    render json: params[:deps] == 'true' ? pois : pois['features'][0]
  end

  def pois
    project_slug, theme_slug = project_theme_params
    category_id = (params[:category_id] || params[:idmenu])&.to_i # idmenu is deprecated
    ids = params[:ids]&.split(',')&.collect(&:to_i)

    pois = query('pois($1, $2, $3, $4::bigint[], $5, $6, $7, $8, $9)', [
      project_slug,
      theme_slug,
      category_id,
      PG::TextEncoder::Array.new.encode(ids),
      params[:geometry_as],
      ActiveModel::Type::Boolean.new.cast(params[:short_description]),
      params[:start_date],
      params[:end_date],
      nil,
    ])

    respond_to do |format|
      format.geojson { render json: pois }
      format.csv {
        features = pois['features']
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

    attribute_translations = query('attribute_translations($1, $2, $3)', [project_slug, theme_slug, lang])
    render json: attribute_translations
  end

  private

  def query(subject, params)
    PG.connect(host: ENV.fetch('POSTGRES_HOST', nil), dbname: ENV['RAILS_ENV'] == 'test' ? 'test' : 'postgres', user: ENV.fetch('POSTGRES_USER', nil), password: ENV.fetch('POSTGRES_PASSWORD', nil)) { |conn|
      conn.exec('SET search_path TO api01,public')
      conn.exec_params("SELECT * FROM #{subject}", params) { |result|
        row = result.first&.[]('d')
        JSON.parse(row) if !row.nil?
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
