# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'
require 'hash_diff'
require 'damerau-levenshtein'


def fetch_json(url)
  JSON.parse(HTTP.follow.get(url))
end

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

def compare_settings(url_old, url_new)
  hashes = [
    "#{url_old}/settings.json",
    "#{url_new}/settings.json",
  ].collect{ |url|
    hash = fetch_json(url).except('id', 'slug')
    hash['themes'].each{ |theme|
      theme.delete('id')
      theme.delete('slug') # Ignore
      theme['site_url'].each{ |lang, site_url|
        if site_url[-1] == '/'
          theme['site_url'][lang] = site_url[..-2]
        end
      }
    }
    hash['polygon'] = nil # Ignore polygons
    hash['bbox_line'] = nil # Ignore polygons
    hash['icon_font_css_url'] = nil # Ignore remote changes
    hash['attributions'] = (hash['attributions']&.sort || []).collect{ |a| a.gsub('&copy;', '©') }

    hash
  }

  diff = HashDiff::Comparison.new(hashes[0], hashes[1])
  puts JSON.dump(diff.diff) if !diff.diff.empty?
end

def compare_articles(url_old, url_new)
  hashes = [
    "#{url_old}/articles.json?slug=non-classe",
    "#{url_new}/articles.json",
  ].collect{ |url|
    array = fetch_json(url)
    array.collect{ |article|
      article.except('post_id')
    }
  }

  diff = HashDiff::Comparison.new(hashes[0], hashes[1])
  puts JSON.dump(diff.diff) if !diff.diff.empty?
end

def compare_menu(url_old, url_new)
  hashes = [
    "#{url_old}/menu.json",
    "#{url_new}/menu.json",
  ].collect{ |url|
    array = fetch_json(url).compact_blank_deep
    array.sort_by{ |menu|
      menu['id']
    }.collect{ |menu|
      menu['menu_group']&.delete('id')
      menu['menu_group']&.delete('style_class')
      menu['menu_group']&.delete('icon') if !menu['parent_id'] || menu.dig('menu_group', 'name', 'fr') == 'Recherche' # WP, ignore color on first menu level
      menu['menu_group']&.delete('color_fill') if !menu['parent_id'] || menu.dig('menu_group', 'name', 'fr') == 'Recherche' # WP, ignore color on first menu level
      menu['menu_group']&.delete('color_line') if !menu['parent_id'] || menu.dig('menu_group', 'name', 'fr') == 'Recherche' # WP, ignore color on first menu level
      menu['category']&.delete('id')
      menu['link']&.delete('id')

      if menu['category']
        menu['category']['zoom'] = Integer(menu['category']['zoom'], exception: false)
      end

      if menu.dig('category', 'filters')
        menu['category']['filters'] = menu['category']['filters'].sort_by{ |filter| filter['property'] || filter['property_begin'] }
        menu['category']['filters'] = menu['category']['filters'].collect{ |filter|
          if filter['type'] != 'multiselect' # WP, static values on WP side.
            # Empty values, as compled automatically
            filter['values'] = []
          end
          if filter['values']
            filter['values'] = filter['values'].sort_by{ |value| value['value'] }
            filter['values'] = filter['values'].collect{ |value|
              value['name'] = value['name']&.transform_values{ |v| v == value['value'] ? nil : v }&.compact_blank
              value.compact_blank
            }
          end
          filter
        }
      end

      menu
    }
  }

  diff = HashDiff::Comparison.new(hashes[0], hashes[1])
  if !diff.diff.empty?
    puts JSON.dump(diff.diff)
    if diff.diff.size < 10
      diff.diff.keys.collect(&:to_i).each{ |i|
        puts JSON.dump(hashes[1][i])
      }
    end
  end

  hashes.collect{ |menu|
    menu.select{ |entry| entry['category'] }.pluck('id')
  }
end

def compare_pois(url_old, url_new, category_ids)
  hashes = [
    "#{url_old}/pois.geojson",
    "#{url_new}/pois.geojson",
  ].each_with_index.collect{ |url, index|
    array = fetch_json(url)['features']&.compact_blank_deep&.select{ |poi|
              !(poi['properties']['metadata']['category_ids'] & category_ids[index]).empty?
            }&.collect{ |poi|
      poi['properties'].delete('classe')
      ['route:hiking:length', 'route:bicycle:length'].each{ |r|
        if poi.dig('properties', r)
          poi['properties'][r] = poi['properties'][r].to_f.round(4)
        end
      }
      ['capacity', 'capacity:persons', 'capacity:pitches', 'capacity:rooms', 'capacity:caravans', 'capacity:cabins', 'capacity:beds'].each{ |i|
        if poi['properties'][i]
          poi['properties'][i] = poi['properties'][i].to_i
        end
      }
      if !poi['properties']['metadata']['osm_id'].nil?
        poi['properties']['metadata']['osm_id'] = poi['properties']['metadata']['osm_id'].to_i
      end
      poi['properties'] = poi['properties'].transform_values{ |v|
        v.is_a?(String) ? v.strip : v
      }
      poi['properties']['metadata']&.delete('source_id')
      poi['properties']['metadata']&.delete('updated_at')
      poi['properties']['editorial']&.delete('hasfiche')
      poi['properties']&.delete('tis_id')

      poi['properties']['editorial']&.delete('class_label')
      poi['properties']['editorial']&.delete('class_label_popup')
      poi['properties']['editorial']&.delete('class_label_details')

      poi['properties']['metadata']&.delete('natives') # Buggy WP
      poi['properties'].delete('description:de') # Buggy WP
      poi['properties'].delete('description:es') # Buggy WP
      poi['properties'].delete('description:nl') # Buggy WP
      poi['properties'].delete('website:details') # Buggy WP

      poi['geometry']&.delete('coordinates') #### TMP, TODO approx commp are 0.0001

      #### TEMP before switch to clearance
      poi['properties']['metadata']&.delete('osm_id')
      poi['properties']['metadata']&.delete('osm_type')
      poi['properties']['metadata']&.delete('source')

      poi
    } || []
    array.collect{ |poi|
      poi['properties']['metadata']['category_ids'] = poi['properties']['metadata']['category_ids'].sort
      poi
    }.uniq{ |poi|
      poi['properties']['metadata']['id']
    }.sort_by{ |poi|
      poi['properties']['metadata']['id']
    }
  }

  puts "Diff size: #{hashes[0].size} != #{hashes[1].size}" if hashes[0].size != hashes[1].size

  ids = hashes.collect{ |h|
    h.collect{ |poi|
      poi['properties']['metadata']['id']
    }
  }
  diff = HashDiff::Comparison.new(ids[0], ids[1])
  puts "Diff ids\n#{JSON.dump(diff.diff)}" if !diff.diff.empty?

  common_ids = Set.new(ids[0] & ids[1])
  hashes = hashes.collect{ |h| h.select{ |poi| common_ids.include?(poi['properties']['metadata']['id']) } }

  # Ignore few changes on names
  hashes[0].zip(hashes[1]).each{ |h|
    h.each{ |poi|
      poi['properties']['metadata'].delete('cartocode')
    }
    a, b = h.collect{ |poi| poi.dig('properties', 'name') }
    if a.presence && b.presence && a.size > 5 && b.size > 5
      d = DamerauLevenshtein.distance(a, b)
      if d <= 3
        h[0]['properties']['name'] = h[1]['properties']['name']
      end
    end
  }

  diff = HashDiff::Comparison.new(hashes[0], hashes[1])
  puts JSON.dump(diff.diff) if !diff.diff.empty?
end

def compare_attribute_translations(url_old, url_new)
  hashes = [
    "#{url_old}/attribute_translations/fr.json",
    "#{url_new}/attribute_translations/fr.json",
  ].collect{ |url|
    hash = fetch_json(url).except('id', 'slug')
    hash
  }

  diff = HashDiff::Comparison.new(hashes[0], hashes[1])
  puts JSON.dump(diff.diff) if !diff.diff.empty?
end

namespace :api do
  desc 'Validate API JSON with Swagger Schema'
  task :diff, [] => :environment do
    url_old, url_new = ARGV[2..]
    compare_settings(url_old, url_new)
    compare_articles(url_old, url_new)
    category_ids = compare_menu(url_old, url_new)
    compare_pois(url_old, url_new, category_ids)
    compare_attribute_translations(url_old, url_new)

    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
