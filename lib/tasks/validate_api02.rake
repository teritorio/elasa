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
    config.traces_sample_rate = 1
    # get breadcrumbs from logs
    config.breadcrumbs_logger = [:http_logger]
  end
end

def fetch_json(url)
  puts url.inspect
  JSON.parse(HTTP.follow.get(url))
end

def schema_for_root
  path = '/'.gsub('/', '~1')
  "#/paths/#{path}/get/responses/200/content/application~1json/schema"
end

def schema_for(path)
  path = "/{project}/{theme}/#{path}".gsub('/', '~1')
  "#/paths/#{path}/get/responses/200/content/application~1json/schema"
end

def validate_schema(url_base)
  schema = YAML.safe_load_file('public/static/elasa-0.2.swagger.yaml')
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/"), fragment: schema_for_root) and puts 'settings.json [valid]'
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/settings.json"), fragment: schema_for('settings.json')) and puts 'settings.json [valid]'
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/articles.json"), fragment: schema_for('articles.json')) and puts 'articles.json [valid]'
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/menu.json"), fragment: schema_for('menu.json')) and puts 'menu.json [valid]'
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/pois.geojson"), fragment: schema_for('pois.{format}')) and puts 'pois.geojson [valid]'
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/attribute_translations/fr.json"), fragment: schema_for('attribute_translations/{lang}.json')) and puts 'attribute_translations/fr.json [valid]'
end

def fully_validate?(schema, json, name, fragment: nil)
  errors = JSON::Validator.fully_validate(schema, json, fragment: fragment)
  if errors.empty?
    puts "#{name} [valid]"
    true
  else
    errors.each{ |error|
      keys = error.match(/'(#[^']*)'/)[1][2..].split('/')
      begin
        keys = keys[..2].collect{ |k| Integer(k, exception: false) || k }
        puts "#{name} #{error} #{json.dig(*keys).to_json}"
      rescue StandardError
        puts "#{name} #{error}"
      end
    }
    puts "#{name} [#{errors.size} errors]"
    false
  end
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
    project_slug, theme_slug = ARGV[2..4]
    projects = PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres').transaction { |conn|
      conn.exec('SET search_path TO api02,public')

      schema = YAML.safe_load_file('public/static/elasa-0.2.swagger.yaml')
      projects = Api02Controller.fetch_projects(conn, '', nil, nil)
      fully_validate?(schema, projects, 'projects.json', fragment: schema_for_root) or exit 1
      projects
    }

    projects.each{ |project_key, projet|
      next if !(project_slug.nil? || project_slug == project_key)

      projet['themes'].each_key{ |theme_key|
        next if !(theme_slug.nil? || theme_slug == theme_key)

        begin
          PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres').transaction { |conn|
            puts "\n#{project_key}/#{theme_key}\n\n"

            pois_json_schema = JSON.parse(Api02Controller.fetch_pois_schema(conn, project_key))

            schema = YAML.safe_load_file('public/static/elasa-0.2.swagger.yaml')
            fully_validate?(schema, Api02Controller.fetch_projects(conn, '', project_key, theme_key), 'settings.json', fragment: schema_for('settings.json'))
            fully_validate?(schema, JSON.parse(Api02Controller.fetch_menu(conn, project_key, theme_key)), 'menu.json', fragment: schema_for('menu.json'))
            fully_validate?(schema, Api02Controller.fetch_articles(conn, '', project_key, theme_key), 'articles.json', fragment: schema_for('articles.json'))
            fully_validate?(schema, JSON.parse(Api02Controller.fetch_attribute_translations(conn, project_key, theme_key, 'fr')), 'attribute_translations/fr.json', fragment: schema_for('attribute_translations/{lang}.json'))

            pois = Api02Controller.fetch_pois(conn, '', project_key, theme_key, nil, nil, nil, nil, nil, nil, nil, nil, nil)
            pois_geojson = "{\"type\": \"FeatureCollection\", \"features\": [#{pois.join(',')}]}"
            fully_validate?(schema, pois_geojson, 'pois.geojson (generic schema)', fragment: schema_for('pois.{format}'))
            fully_validate?(pois_json_schema, pois_geojson, 'pois.geojson (project schema)')
          }
        rescue StandardError => e
          Sentry.capture_exception(e, extra: { project_slug: project_key, theme_slug: theme_key })
          puts e.message
          puts e.backtrace.join("\n")
        end
      }
    }
    exit 0 # Beacause of manually deal with rake command line arguments
  rescue StandardError => e
    Sentry.capture_exception(e)
    raise
  end
end
