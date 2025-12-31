# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'
require 'hash_diff'

class Object
  def compact_blank_deep
    self
  end
end

class Array
  def compact_blank_deep
    r = map(&:compact_blank_deep).compact_blank

    r.presence
  end
end

class Hash
  def compact_blank_deep
    r = each_with_object({}) { |(k, v), h|
      if (v = v.compact_blank_deep)
        h[k] = v
      end
    }.compact_blank

    r.presence
  end
end

def fetch_json(url)
  response = HTTP.follow.get(url)
  raise "[ERROR] #{url} => #{response.status}" if !response.status.success?

  JSON.parse(response)
end

def compare(url_old, url_new, &block)
  url_old_base = url_old.split('/')[..2].join('/').gsub('http://', 'https://')
  url_new_base = url_new.split('/')[..2].join('/').gsub('http://', 'https://')
  hashes = [url_old, url_new].collect{ |url|
    JSON.parse(fetch_json(url).to_json.gsub(url_old_base, url_new_base))
  }.each_with_index.collect{ |hash, index|
    block&.call(hash, index) || hash
  }

  if hashes[0].is_a?(Hash)
    keys_only0 = hashes[0].keys - hashes[1].keys
    keys_only1 = hashes[1].keys - hashes[0].keys
    puts "Keys only on old: #{keys_only0.join(' ')}" if !keys_only0.empty?
    puts "Keys only on new: #{keys_only1.join(' ')}" if !keys_only1.empty?

    common_keys = hashes[0].keys & hashes[1].keys
    hashes[0] = hashes[0].slice(*common_keys)
    hashes[1] = hashes[1].slice(*common_keys)
  end

  diff = HashDiff::Comparison.new(hashes[0], hashes[1])
  puts JSON.dump(diff.diff) if !diff.diff.empty?
end

def compare_settings(url_old, url_new)
  compare(
    "#{url_old}/settings.json",
    "#{url_new}/settings.json",
  )
end

def compare_articles(url_old, url_new)
  compare(
    "#{url_old}/articles.json",
    "#{url_new}/articles.json",
  )
end

def compare_menu(url_old, url_new)
  compare(
    "#{url_old}/menu.json",
    "#{url_new}/menu.json",
  ) { |menu, _index|
    menu = menu.collect{ |entry|
      if !entry['category'].nil?
        entry['category'].delete('color_line') if entry['category']['color_fill'] == entry['category']['color_line']
        entry['category'].delete('editorial')
      end
      entry.compact_blank_deep
    }
    menu.index_by{ |entry| entry['id'] }
  }
end

I18N = ['name', 'website:details', 'description', 'official_name', 'short_description'].freeze
LONG = %w[description short_description].freeze

def compare_pois(url_old, url_new)
  compare(
    "#{url_old}/pois.geojson",
    "#{url_new}/pois.geojson",
  ) { |pois, index|
    features = pois['features'].index_by{ |poi| poi['properties']['metadata']['id'] }
    features.transform_values { |poi|
      poi.delete('geometry')
      poi.delete('bbox')
      poi['properties']['metadata'].delete('updated_at')
      poi['properties'].delete('display')
      poi['properties'].delete('editorial')

      if index == 0
        I18N.each{ |key|
          poi['properties'][key] = { 'fr-FR' => poi['properties'][key] } if !poi['properties'][key].nil?
        }
        poi['properties'] = poi['properties'].delete_if{ |k, _v| k.start_with?('addr:') || k.start_with?('route:') }
        if !poi['properties']['start_date'].nil? || !poi['properties']['end_date'].nil?
          poi['properties']['start_end_date'] = {
            'start_date' => poi['properties'].delete('start_date'),
            'end_date' => poi['properties'].delete('end_date'),
          }.compact_blank
        end
      else
        poi['properties']['metadata'].delete('report_issue_url')
        poi['properties'].delete('addr')
        poi['properties'].delete('route')
      end

      LONG.each{ |key|
        if !poi.dig('properties', 'description', 'fr-FR').nil?
          poi['properties'][key] = { 'fr-FR' => '.' }
        end
      }

      poi.compact_blank_deep
    }

    features
  }
end

def compare_attribute_translations(url_old, url_new)
  compare(
    "#{url_old}/attribute_translations/fr.json",
    "#{url_new}/attribute_translations/fr.json",
  )
end

namespace :api02 do
  desc 'Diff API'
  task :diff, [] => :environment do
    project_slug, theme_slug = ARGV[4..6]
    url_old, url_new = ARGV[2..4].map{ |url| "#{url}/api/0.1/#{project_slug}/#{theme_slug}" }
    compare_settings(url_old, url_new)
    compare_articles(url_old, url_new)
    compare_menu(url_old, url_new)
    compare_pois(url_old, url_new)
    compare_attribute_translations(url_old, url_new)

    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
