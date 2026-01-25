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

def compare(url_old, url_new, prune_diff: nil, &block)
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
  return if diff.diff.empty?

  diff = JSON.parse(diff.diff.to_json)
  diff = prune_diff.call(diff) if !prune_diff.nil?
  return if diff.empty?

  puts JSON.dump(diff)
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
        entry['category'].delete('filterable_property')

        if !entry['category']['filters'].nil?
          entry['category']['filters'] = entry['category']['filters'].collect{ |filter|
            if !filter['property_begin'].nil? || !filter['property_end'].nil?
              filter.delete('property_begin')
              filter.delete('property_end')
              filter['property'] = 'start_end_date'
            end

            if !filter['property'].nil? && !filter['property'].is_a?(Array)
              filter['property'] = filter['property'].start_with?('route:') || filter['property'].start_with?('addr:') ? filter['property'].split(':') : [filter['property']]
            end

            filter
          }
        end
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
  poi['properties'] = poi['properties'].delete_if{ |k, v| k.start_with?('addr:') || (k == 'route:gpx_trace' && v.include?('gtfs')) }
  if !poi['properties']['start_date'].nil? || !poi['properties']['end_date'].nil?
    poi['properties']['start_end_date'] = {
      'start_date' => poi['properties'].delete('start_date'),
      'end_date' => poi['properties'].delete('end_date'),
    }.compact_blank
  end
  poi['properties'].delete('route') if poi['properties']['route'] == 'bus'

  poi
end

def compare_pois_clean_new(poi)
  poi['properties']['metadata'].delete('report_issue_url')
  poi['properties'].delete('addr')
  route = poi['properties'].delete('route')
  if !route.nil?
    route = route['fr-FR']
    route.each{ |p, r|
      if r.is_a?(Hash)
        r.each{ |k, v|
          poi['properties']["route:#{p}:#{k}"] = v
        }
      else
        poi['properties']["route:#{p}"] = r
      end
    }
  end

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
          raise "#{key} should be an Hash" if !poi['properties'][key].is_a?(Hash)

          poi['properties'][key].delete_if{ |k, _v| /[a-z]{2}/.match(k) || /[a-z]{2}-[A-Z]{2}/.match(k) }
          poi['properties'][key].delete('en-US')
          poi['properties'][key].delete('etymology:wikidata')
        end
      }

      poi['properties']['route:gpx_trace'] = 'gpx' if !poi['properties']['route:gpx_trace'].nil?

      poi['properties'].delete('labels')
      poi['properties'].delete('opening_hours')
      poi['properties'].delete('source:addr')

      poi.compact_blank_deep
    }

    features
  }
end

def compare_attribute_translations(url_old, url_new)
  compare(
    "#{url_old}/attribute_translations/fr.json",
    "#{url_new}/attribute_translations/fr.json",
    prune_diff: lambda { |diff|
      diff.transform_values{ |d|
        if !d['values'].nil?
          if d['values'][0] == 'HashDiff::NO_VALUE'
            d.delete('values')
          else
            d['values'].delete_if{ |_k, v| v.is_a?(Array) && v[0] == 'HashDiff::NO_VALUE' }.compact_blank
          end
        end
        d.compact_blank
      }
      diff.compact_blank
    }
  ) { |tr, _index|
    if tr.dig('tis_TYPEACTIVSPORT', 'label', 'fr') == 'Type'
      tr['tis_TYPEACTIVSPORT']['label']['fr'] = 'Type d\'activité'
    elsif tr.dig('PrestationsServicess', 'label', 'fr') == 'Services'
      tr['PrestationsServicess']['label']['fr'] = 'Prestations services'
    elsif tr.dig('PrestationsEquipementss', 'label', 'fr') == 'Équipements'
      tr['PrestationsEquipementss']['label']['fr'] = 'Prestations équipements'
    end
    tr
  }
end

namespace :api02 do
  desc 'Diff API'
  task :diff, [] => :environment do
    url_api_old =  "#{ARGV[2]}/api/0.1/"
    url_api_new =  "#{ARGV[3]}/api/0.2/"
    project_slug, theme_slug = ARGV[4..6]
    projects = fetch_json(url_api_old)
    projects.each{ |project_key, projet|
      next if !(project_slug.nil? || project_slug == project_key)

      projet['themes'].each_key{ |theme_key|
        next if !(theme_slug.nil? || theme_slug == theme_key)

        begin
          url_old, url_new = [url_api_old, url_api_new].map{ |url| "#{url}#{project_key}/#{theme_key}" }
          compare_settings(url_old, url_new)
          compare_articles(url_old, url_new)
          compare_menu(url_old, url_new)
          compare_pois(url_old, url_new)
          compare_attribute_translations(url_old, url_new)
        rescue StandardError => e
          puts e.message
        end
      }
    }

    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
