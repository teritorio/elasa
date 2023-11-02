# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'
require 'hash_diff'


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
    }
    hash['polygon'] = nil # Ignore polygons
    hash['bbox_line'] = nil # Ignore polygons
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
      menu['category']&.delete('id')
      menu['link']&.delete('id')

      if menu['category']
        menu['category']['zoom'] = Integer(menu['category']['zoom'], exception: false)
      end

      if menu.dig('category', 'filters')
        menu['category']['filters'] = menu['category']['filters'].sort_by{ |filter| filter['property'] || filter['property_begin'] }
        menu['category']['filters'] = menu['category']['filters'].collect{ |filter|
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
  puts JSON.dump(diff.diff) if !diff.diff.empty?
end

def compare_pois(url_old, url_new)
  hashes = [
    "#{url_old}/pois.json",
    "#{url_new}/pois.json",
  ].collect{ |url|
    array = fetch_json(url)['features'].compact_blank_deep.collect{ |poi|
      poi['properties'].delete('classe')
      ['route:hiking:length', 'route:bicycle:length'].each{ |r|
        if poi.dig('properties', r)
          poi['properties'][r] = poi['properties'][r].round(4)
        end
      }
      ['capacity:persons', 'capacity:pitches', 'capacity:rooms'].each{ |i|
        if poi['properties'][i]
          poi['properties'][i] = poi['properties'][i].to_i
        end
      }
      poi['properties']['metadata']&.delete('source_id')
      poi['properties']['editorial']&.delete('hasfiche')

      poi['properties']['editorial']&.delete('class_label')
      poi['properties']['editorial']&.delete('class_label_popup')
      poi['properties']['editorial']&.delete('class_label_details')

      poi['properties']['metadata']&.delete('natives') # Buggy WP
      poi['properties'].delete('description:de') # Buggy WP
      poi['properties'].delete('description:es') # Buggy WP
      poi['properties'].delete('description:nl') # Buggy WP
      poi['properties'].delete('website:details') # Buggy WP

      poi
    }
    array.collect{ |poi|
      poi['properties']['metadata']['category_ids'] = poi['properties']['metadata']['category_ids'].sort
      poi
    }.uniq{ |poi|
      [poi['properties']['metadata']['category_ids'], poi['properties']['metadata']['id']]
    }.sort_by{ |poi|
      [poi['properties']['metadata']['category_ids'], poi['properties']['metadata']['id']]
    }
  }

  ids = hashes.collect{ |h|
    h.collect{ |poi|
      [poi['properties']['metadata']['category_ids'], poi['properties']['metadata']['id']]
    }
  }
  common_ids = Set.new(ids[0] & ids[1])
  hashes = hashes.collect{ |h| h.select{ |poi| common_ids.include?([poi['properties']['metadata']['category_ids'], poi['properties']['metadata']['id']]) } }

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
    compare_menu(url_old, url_new)
    compare_pois(url_old, url_new)
    compare_attribute_translations(url_old, url_new)

    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
