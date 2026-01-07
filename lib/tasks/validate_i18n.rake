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
  pois = fetch_json("#{url_base}/pois.geojson")
  i18n = fetch_json("#{url_base}/attribute_translations/fr.json")

  fields = pois['features'].collect{ |poi|
    poi.dig('properties', 'editorial', 'popup_fields')&.collect{ |field| field }&.compact
  }.flatten(1).compact.uniq

  fields_keys = fields.pluck('field')
  missing_keys = fields_keys - i18n.keys

  if !missing_keys.empty?
    puts "[ERROR] Missing keys in i18n: #{missing_keys.inspect}"
  end

  missing_keys_labels = (fields_keys - missing_keys).select{ |field| field['label'] }.select { |key|
    i18n.dig(key, 'label').nil?
  }

  return if missing_keys_labels.empty?

  puts "[ERROR] Missing labels in i18n: #{missing_keys_labels.inspect}"
end

namespace :api02 do
  desc 'Validate API i18n'
  task :validate_i18n, [] => :environment do
    url_base, = ARGV[2..]
    validate(url_base)
    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
