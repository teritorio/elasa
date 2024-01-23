# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'


def fetch_json(url)
  puts url.inspect
  JSON.parse(HTTP.follow.get(url))
end

def schema_for(path)
  path = "/{project}/{theme}/#{path}".gsub('/', '~1')
  "#/paths/#{path}/get/responses/200/content/application~1json/schema"
end

def validate(url_base)
  schema = YAML.safe_load_file('public/elasa-0.1.swagger.yaml')
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/settings.json"), fragment: schema_for('settings.json')) and puts 'settings.json [valid]'
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/articles.json"), fragment: schema_for('articles.json')) and puts 'articles.json [valid]'
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/menu.json"), fragment: schema_for('menu.json')) and puts 'menu.json [valid]'
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/pois.json"), fragment: schema_for('pois.{format}')) and puts 'pois.egosjon [valid]'
  JSON::Validator.validate!(schema, fetch_json("#{url_base}/attribute_translations/fr.json"), fragment: schema_for('attribute_translations/{lang}.json')) and puts 'attribute_translations/fr.json [valid]'
end

namespace :api do
  desc 'Validate API JSON with Swagger Schema'
  task :validate, [] => :environment do
    url_base, = ARGV[2..]
    validate(url_base)
    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
