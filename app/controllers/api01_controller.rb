# frozen_string_literal: true
# typed: true

class Api01Controller < ApplicationController
  def settings
    project_slug, = project_theme_params

    project = query('postgisftw.project($1)', [project_slug])
    render json: project.except('articles')
  end

  def articles
    project_slug, = project_theme_params

    project = query('postgisftw.project($1)', [project_slug])
    render json: project['articles'].collect{ |article|
      {
        url: article['url']['fr'],
        title: article['title']['fr'],
      }
    }
  end

  def menu
    project_slug, theme_slug = project_theme_params

    menu_items = query('postgisftw.menu($1, $2)', [project_slug, theme_slug])
    render json: menu_items
  end

  def poi
    project_slug, theme_slug = project_theme_params
    id = params.require(:id).to_i

    pois = query('postgisftw.pois($1, $2, $3, $4::integer[], $5, $6, $7, $8, $9)', [
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

    pois = query('postgisftw.pois($1, $2, $3, $4::integer[], $5, $6, $7, $8, $9)', [
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
    render json: pois
  end

  def pois_category
    params.require(%i[project theme category_id])
    pois
  end

  private

  def query(subject, params)
    PG.connect(host: ENV.fetch('POSTGRES_HOST', nil), dbname: ENV['RAILS_ENV'] == 'test' ? 'test' : 'postgres', user: ENV.fetch('POSTGRES_USER', nil), password: ENV.fetch('POSTGRES_PASSWORD', nil)) { |conn|
      conn.exec_params("SELECT * FROM #{subject}", params) { |result|
        row = result.first&.[]('d')
        JSON.parse(row) if !row.nil?
      }
    }
  end

  def project_theme_params
    params.require(%i[project theme])
  end
end
