# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'
require 'sentry-ruby'
require 'json-schema'


if ENV['SENTRY_DSN_TOOLS'].present?
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN_TOOLS']
    # enable performance monitoring
    config.enable_tracing = true
    # get breadcrumbs from logs
    config.breadcrumbs_logger = [:http_logger]
  end
end

def fetch_json(url)
  puts url.inspect
  JSON.parse(HTTP.follow.get(url))
end

def schema_for(path)
  path = "/{project}/{theme}/#{path}".gsub('/', '~1')
  "#/paths/#{path}/get/responses/200/content/application~1json/schema"
end

def validate_schema(url_base)
  schema = YAML.safe_load_file('public/static/elasa-0.2.swagger.yaml')
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/settings.json"), fragment: schema_for('settings.json')) and puts 'settings.json [valid]'
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/articles.json"), fragment: schema_for('articles.json')) and puts 'articles.json [valid]'
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/menu.json"), fragment: schema_for('menu.json')) and puts 'menu.json [valid]'
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/pois.geojson"), fragment: schema_for('pois.{format}')) and puts 'pois.geojson [valid]'
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/attribute_translations/fr.json"), fragment: schema_for('attribute_translations/{lang}.json')) and puts 'attribute_translations/fr.json [valid]'
end

def validate_pois(conn, pois_json_schema, project_slug, theme_slug)
  pois = conn.exec_params('SELECT * FROM pois(\'\', $1, $2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)', [project_slug, theme_slug]) { |results|
    results.collect{ |poi| poi['feature'] }
  }
  pois_geojson = "{\"type\": \"FeatureCollection\", \"features\": [#{pois.join(',')}]}"
  errors = JSON::Validator.fully_validate(pois_json_schema, JSON.parse(pois_geojson))
  errors.each{ |error|
    puts error
  }
  raise "POIs JSON validation failed for project=#{project_slug} theme=#{theme_slug}" if !errors.empty?
end

namespace :api02 do
  desc 'Validate API JSON with Swagger Schema'
  task :validate, [] => :environment do
    url_base, = ARGV[2..]
    validate_schema(url_base)
    exit 0 # Beacause of manually deal with rake command line arguments
  end

  desc 'Validate API POIs JSON with API JSON Schema'
  task :validate_poi, [] => :environment do
    project_slug, = ARGV[2..]
    PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres').transaction { |conn|
      conn.exec('SET search_path TO api01,public')
      pois_json_schema = conn.exec_params('SELECT * FROM pois_json_schema($1)', [project_slug]) { |results|
        JSON.parse(results.first&.[]('d'))
      }
      conn.exec_params('SELECT themes.slug AS theme_slug FROM projects JOIN themes ON themes.project_id = projects.id WHERE $1::text IS NULL OR projects.slug = $1', [project_slug]) { |results|
        results.each{ |row|
          theme_slug = row.fetch('theme_slug')

          begin
            validate_pois(conn, pois_json_schema, project_slug, theme_slug)
          rescue StandardError => e
            Sentry.capture_exception(e, extra: { project_slug: project_slug, theme_slug: theme_slug })
            puts e.message
          end
        }
      }
    }
    exit 0 # Beacause of manually deal with rake command line arguments
  rescue StandardError => e
    Sentry.capture_exception(e)
    raise
  end
end
