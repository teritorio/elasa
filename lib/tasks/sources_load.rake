# frozen_string_literal: true
# typed: true

require 'rake'
require 'sentry-ruby'

if ENV['SENTRY_DSN_TOOLS'].present?
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN_TOOLS']
    # enable performance monitoring
    config.enable_tracing = true
    # get breadcrumbs from logs
    config.breadcrumbs_logger = [:http_logger]
  end
end

namespace :sources do
  desc 'Load Sources and POIs from datasource'
  task :load, [] => :environment do
    url_base, project_slug = ARGV[2..]
    PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres').transaction { |conn|
      conn.exec_params('SELECT slug, datasources_slug FROM projects WHERE $1::text IS NULL OR slug = $1', [project_slug]) { |results|
        results.collect{ |row|
          project_slug = row.fetch('slug')
          datasource_project = row.fetch('datasources_slug')
          next if datasource_project.nil?

          puts "\n#{datasource_project}\n\n"

          load_from_source(conn, "#{url_base}/data", project_slug, datasource_project)
          i18ns = fetch_json("#{url_base}/data/#{datasource_project}/i18n.json")
          load_i18n(conn, project_slug, i18ns)
        }
      }
    }
    exit 0 # Beacause of manually deal with rake command line arguments
  rescue StandardError => e
    Sentry.capture_exception(e)
    raise
  end
end
