# frozen_string_literal: true
# typed: true

class Api01Controller < ApplicationController
  def settings
    project_slug, = project_theme_params

    # ######################" FIX injection SQL
    project = JSON.parse(query("postgisftw.project('#{project_slug}')")[0]['d'])
    render json: project
  end

  def menu
    project_slug, theme_slug = project_theme_params

    # ######################" FIX injection SQL
    menu_items = JSON.parse(query("postgisftw.menu('#{project_slug}', '#{theme_slug}')")[0]['d'])
    render json: menu_items
  end

  def pois
    project_slug, theme_slug = project_theme_params

    # ######################" FIX injection SQL
    pois = JSON.parse(query("postgisftw.pois('#{project_slug}', '#{theme_slug}')")[0]['d'])
    render json: pois
  end

  private

  def query(subject)
    rows = []
    PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
      conn.exec("SELECT * FROM #{subject}") { |result|
        rows += result.to_a
      }
    }
    rows
  end

  def project_theme_params
    params.require(%i[project theme])
  end
end
