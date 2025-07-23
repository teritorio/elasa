# frozen_string_literal: true
# typed: true

require_relative '../../lib/tasks/sources_load'


class Api02AdminController < ApplicationController
  # Load Sources and POIs from datasource
  def sources_load
    project_slug, api_key = admin_params
    PG.connect(host: ENV.fetch('POSTGRES_HOST', nil), dbname: ENV['RAILS_ENV'] == 'test' ? 'test' : 'postgres', user: ENV.fetch('POSTGRES_USER', nil), password: ENV.fetch('POSTGRES_PASSWORD', nil)) { |conn|
      row_project = project(project_slug, api_key)
      if row_project.present?
        url_base = ENV.fetch('DATASOURCES_URL', nil)
        datasource_project = row_project.fetch('datasources_slug')

        original_stdout = $stdout
        begin
          $stdout = StringIO.new

          load_from_source(conn, "#{url_base}/data", project_slug, datasource_project)
          i18ns = fetch_json("#{url_base}/data/#{project_slug}/i18n.json")
          load_i18n(conn, project_slug, i18ns)

          stdout = $stdout.string
        ensure
          $stdout = original_stdout
        end

        render plain: stdout
      else
        render status: :not_found
      end
    }
  end

  private

  def admin_params
    params.require(%i[project api_key])
  end

  def project(conn, slug, api_key)
    conn.exec('SET search_path TO api01,public')
    conn.exec_params('SELECT * FROM projects WHERE slug = $1 AND api_key = $2', [slug, api_key]) { |result|
      result.first
    }
  end
end
