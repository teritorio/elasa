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
    collect(&:compact_blank_deep).compact_blank.presence
  end
end

class Hash
  def compact_blank_deep
    transform_values(&:compact_blank_deep).compact_blank.presence
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
    puts url
    JSON.parse(fetch_json(url).to_json
      .gsub(url_old_base, url_new_base)
      .gsub('https://cdt87.media.tourinsoft.eu', 'https://cdt40.media.tourinsoft.eu'))
  }.each_with_index.collect{ |hash, index|
    block&.call(hash, index) || hash
  }.collect(&:compact_blank_deep)

  return if hashes[0].nil? && hashes[1].nil?

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

I18N = [
  'name', 'official_name', 'loc_name', 'alt_name',
  'website:details',
  'description', 'short_description',
].freeze
LONG = %w[description short_description].freeze

def compare_pois_clean_old(poi)
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
  poi['properties'].delete('route') if poi['properties']['route'] == 'bus'

  poi['properties']['award:epi'] = poi['properties']['award:epi'].to_i if !poi['properties']['award:epi'].nil?
  poi['properties']['award:cle'] = poi['properties']['award:cle'].to_i if !poi['properties']['award:cle'].nil?
  poi
end

def compare_pois_clean_new(poi)
  poi['properties']['metadata'].delete('report_issue_url')
  poi['properties'].delete('addr')
  poi['properties'].delete('route')

  poi['properties']['award:epi'] = poi['properties'].delete('award:epi_gite') if !poi['properties']['award:epi_gite'].nil?
  poi['properties']['award:epi'] = poi['properties'].delete('award:epi_locatif') if !poi['properties']['award:epi_locatif'].nil?
  poi
end

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

      poi = index == 0 ? compare_pois_clean_old(poi) : compare_pois_clean_new(poi)

      LONG.each{ |key|
        if !poi.dig('properties', 'description', 'fr-FR').nil?
          poi['properties'][key] = { 'fr-FR' => '.' }
        end
      }
      poi['properties']['metadata']['category_ids'].sort!
      poi['properties']['produce']&.sort!

      I18N.each{ |key|
        if !poi['properties'][key].nil?
          poi['properties'][key].delete_if{ |k, _v| /[a-z]{2}/.match(k) || /[a-z]{2}-[A-Z]{2}/.match(k) }
          poi['properties'][key].delete('en-US')
          poi['properties'][key].delete('etymology:wikidata')
        end
      }

      poi['properties'].delete('labels')

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
    url_api_old, url_api_new = ARGV[2..4].map{ |url| "#{url}/api/0.1/" }
    project_slug, theme_slug = ARGV[4..6]
    projects = fetch_json(url_api_old)
    projects.each{ |project_key, projet|
      next if !(project_slug.nil? || project_slug == project_key)

      projet['themes'].each_key{ |theme_key|
        next if !(theme_slug.nil? || theme_slug == theme_key)

        url_old, url_new = [url_api_old, url_api_new].map{ |url| "#{url}#{project_key}/#{theme_key}" }
        compare_settings(url_old, url_new)
        compare_articles(url_old, url_new)
        compare_menu(url_old, url_new)
        compare_pois(url_old, url_new)
        compare_attribute_translations(url_old, url_new)
      }
    }

    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
