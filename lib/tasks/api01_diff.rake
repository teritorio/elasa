# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'
require 'hash_diff'
require 'damerau-levenshtein'


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
      # Only filename
      %w[logo_url favicon_url].each{ |k|
        theme[k] = theme[k].split('/').last if theme[k]
      }
      theme['site_url'].each{ |lang, site_url|
        if site_url[-1] == '/'
          theme['site_url'][lang] = site_url[..-2]
        end
      }
    }
    hash['polygon'] = nil # Ignore polygons
    hash['bbox_line'] = nil # Ignore polygons
    hash['polygons_extra'] = nil # Ignore polygons
    hash['icon_font_css_url'] = nil # Ignore remote changes
    hash['datasources_slug'] = nil # Ignore, only on Elasa side
    hash['api_key'] = nil # Ignore, only on Elasa side
    hash['attributions'] = nil

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

  hashes[0] = hashes[0].collect{ |v|
    v['url'] = v['url'].split('/')[5]
    v
  }
  hashes[1] = hashes[1].collect{ |v|
    v['url'] = v['url'].split('/')[8].gsub(/\.html$/, '')
    v
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
      menu['menu_group']&.delete('style_class') # Buggy WP, menu_group have no style_class attribute
      menu['menu_group']&.delete('icon') if !menu['parent_id'] || menu.dig('menu_group', 'name', 'fr') =~ /[Bb]loc |Recherche/ # WP, not configured
      menu['menu_group']&.delete('color_fill') if !menu['parent_id'] || menu.dig('menu_group', 'name', 'fr') =~ /[Bb]loc |Recherche/ # WP, not configured
      menu['menu_group']&.delete('color_line') if !menu['parent_id'] || menu.dig('menu_group', 'name', 'fr') =~ /[Bb]loc |Recherche/ # WP, not configured
      menu.delete('parent_id') if menu['parent_id'] == 0 # WP, not configured
      menu['category']&.delete('id')
      menu['link']&.delete('id')

      %w[menu_group category link].each{ |k|
        menu[k]&.delete('icon') if menu[k]&.delete('icon') == 'teritorio teritorio-beef00' # Values added as default on import from WP
        menu[k]&.delete('color_fill') if menu[k]&.delete('color_fill') == '#beef00' # Values added as default on import from WP
        menu[k]&.delete('color_line') if menu[k]&.delete('color_line') == '#beef00' # Values added as default on import from WP
      }

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

  ids = hashes.collect{ |h|
    h.collect{ |poi|
      poi['id']
    }
  }
  only_in_0 = ids[0] - ids[1]
  only_in_1 = ids[1] - ids[0]
  puts "Category ids only on 0\n#{only_in_0.inspect}" if !only_in_0.empty?
  puts "Category ids only on 1\n#{only_in_1.inspect}" if !only_in_1.empty?

  common_ids = Set.new(ids[0] & ids[1])
  hashes = hashes.collect{ |h| h.select{ |menu| common_ids.include?(menu['id']) } }

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

# From WP pois.geojson, pois in multiple categories are missing.
# Use menu_sources.json to get missing categories fields.
def missing_category_ids(menu_sources, pois)
  menu_sources_multi = menu_sources.collect{ |menu_id, sources|
    sources.collect{ |source| [menu_id, source] }
  }.flatten(1).group_by(&:last).select{ |_source, source_menu_ids|
    source_menu_ids.size > 1
  }.transform_values{ |source_menu_ids|
    source_menu_ids.collect(&:first).collect(&:to_i)
  }

  category_ids_all = pois.collect{ |poi|
    poi.dig('properties', 'metadata', 'category_ids')
  }.flatten.uniq

  menu_sources_multi.values.flatten - category_ids_all
end

def clean_pois(pois, category_id)
    array = pois&.select{ |poi|
      if category_id.nil?
        true
      else
        !(poi['properties']['metadata']['category_ids'] & category_id).empty? && poi['properties']['metadata']['id'] / 10_000 != 654_65
      end
    }&.collect{ |poi|
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

      poi['properties']['metadata'] = {'id' => poi['properties'].delete('id') } if poi['properties']['metadata'].nil?

      if !poi['properties']['metadata']['osm_id'].nil?
        poi['properties']['metadata']['osm_id'] = poi['properties']['metadata']['osm_id'].to_i
      end
      poi['properties'] = poi['properties'].transform_values{ |v|
        v.is_a?(String) ? v.strip : v
      }
      poi['properties']['metadata']['dep_ids'] = poi['properties'].delete('dep_ids') if poi['properties'].key?('dep_ids') # Buggy WP
      if poi['properties']['metadata'].key?('dep_ids')
        poi['properties']['metadata']['dep_ids'] = poi['properties']['metadata']['dep_ids'].compact.presence
        poi['properties']['metadata'].delete('dep_ids') if poi['properties']['metadata']['dep_ids'].nil?
      end
      poi['properties']['metadata']&.delete('source_id')
      poi['properties']['metadata']&.delete('updated_at')
      poi['properties']['editorial']&.delete('hasfiche')
      poi['properties']&.delete('tis_id')

      poi['properties']['editorial']&.delete('class_label')
      poi['properties']['editorial']&.delete('class_label_popup')
      poi['properties']['editorial']&.delete('class_label_details')

      poi['properties']['editorial']&.delete('label')
      poi['properties']['editorial']&.delete('label_fiche')
      poi['properties']['editorial']&.delete('label_infobulle')
      poi['properties']['editorial']&.delete('PopupListField')
      poi['properties']['editorial']&.delete('ficheBlocs')

      poi['properties']['display']&.delete('color_fill') # Not constant Elasa/WP on POI in multiple categories
      poi['properties']['display']&.delete('color_line') # Not constant Elasa/WP on POI in multiple categories

      poi['properties']['metadata']&.delete('natives') # Buggy WP
      poi['properties'].delete('website:details') # Buggy WP
      poi['properties'].delete('custom_details') # Buggy WP
      poi['properties'].delete('osm_galerie_images') # Buggy WP
      poi['properties'].delete('sources') # Buggy WP
      poi['properties']['metadata']&.delete('source') # Buggy WP
      poi['properties'] = poi['properties'].select{ |k, _v| !k.start_with?('name:') } # API change
      poi['properties'] = poi['properties'].select{ |k, _v| !k.start_with?('description:') } # API change
      poi['properties']['name'] = poi['properties']['name']['fr'] if poi.dig('properties', 'name').is_a?(Hash) && !poi.dig('properties', 'name', 'fr').nil? # WP waypoint
      poi['properties']['name'] = poi['properties']['name'].strip if !poi['properties']['name'].nil?
      poi['properties']['description'] = poi['properties']['description']['fr'] if poi.dig('properties', 'description').is_a?(Hash) && !poi.dig('properties', 'description', 'fr').nil? # WP waypoint

      poi['properties'].delete('partenaire_fiche') # Buggy WP
      poi['properties'].delete('partenaire_url') # Buggy WP
      poi['properties'].delete('classic-editor-remember')

      poi['properties'].delete('website') # Buggy WP, wrong values including ";"

      poi['properties']['display'].delete('icon') if poi['properties']['display']&.delete('icon') == 'teritorio teritorio-beef00' # Values added as default on import from WP
      poi['properties']['display'].delete('color_fill') if poi['properties']['display']&.delete('color_fill') == '#beef00' # Values added as default on import from WP
      poi['properties']['display'].delete('color_line') if poi['properties']['display']&.delete('color_line') == '#beef00' # Values added as default on import from WP

      poi['properties']['metadata']&.delete('refs') # WP does not support refs

      poi['properties'].delete('colour') # Elasa remove the colour to avoid conflict with the category colour

      poi.delete('geometry') # TMP, approx commp are 0.0001, and WP geom not the same
      poi.delete('bbox') # Only Elasa

      poi['properties']['route:bicycle:duration'] = poi['properties']['route:bicycle:duration']&.to_i # Buggy WP
      poi['properties']['route:road:duration'] = poi['properties']['route:road:duration']&.to_i # Buggy WP
      poi['properties']['route:hiking:duration'] = poi['properties']['route:hiking:duration']&.to_i # Buggy WP
      poi['properties']['duration_cycle'] = poi['properties']['duration_cycle']&.to_i # Buggy WP
      poi['properties']['maxlength'] = poi['properties']['maxlength']&.to_i # Buggy WP
      poi['properties']['capacity:disabled'] = poi['properties']['capacity:disabled']&.to_i # Buggy WP
      poi['properties']['assmat_nb_places_agrees'] = poi['properties']['assmat_nb_places_agrees']&.to_i # Buggy WP
      poi['properties']['assmat_nb_places_libres'] = poi['properties']['assmat_nb_places_libres']&.to_i # Buggy WP
      poi['properties']['assmat_nb_places_bientot_dispo'] = poi['properties']['assmat_nb_places_bientot_dispo']&.to_i # Buggy WP
      poi['properties']['az_voir_listes_donnees'] = poi['properties']['az_voir_listes_donnees']&.to_i # Imported as integer
      poi['properties']['az_has_data_liste'] = poi['properties']['az_has_data_liste']&.to_i # Imported as integer
      poi['properties']['zpj_zones_1_activer_dessin'] = poi['properties']['zpj_zones_1_activer_dessin']&.to_i # Imported as integer
      poi['properties']['zpj_zones_2_activer_dessin'] = poi['properties']['zpj_zones_2_activer_dessin']&.to_i # Imported as integer
      poi['properties']['zpj_date_debut_annee'] = poi['properties']['zpj_date_debut_annee']&.to_i # Imported as integer
      poi['properties']['zpj_date_fin_annee'] = poi['properties']['zpj_date_fin_annee']&.to_i # Imported as integer

      # Buggy WP with 0 and "no" values
      [
        'min_age',
        'level', 'building:levels', 'roof:levels',
        'addr:floor',
        'capacity', 'capacity:caravans', 'capacity:cabins', 'capacity:rooms', 'capacity:disabled',
        'covered',
        'isced:level',
        'height', 'maxlength',
      ].each{ |k|
        if [0, '0', 'no', nil].include?(poi['properties'][k])
          poi['properties'].delete(k)
        end
      }

      {
        'duration' => 'unlimited',
        'name:signed' => 'no',
        'maxlength' => 'none',
      }.each{ |k, v|
        if poi['properties'][k] == v
          poi['properties'].delete(k)
        end
      }

      # Only image filename
      if poi['properties']['image']
        poi['properties']['image'] = poi['properties']['image'].collect{ |i|
          i.split('/').last.gsub(/\.jpg$/, '.jpeg')
        }
      end

      # Only filename
      ['route:gpx_trace', 'route:pdf'].each{ |k|
        poi['properties'][k] = poi['properties'][k].split('/').last if poi['properties'][k]
      }
      poi['properties']['editorial']['website:details'] = poi['properties']['editorial']['website:details'].split('/')[3..].join('/') if !poi.dig('properties', 'editorial', 'website:details').nil?

      poi
    } || []
    array.collect{ |poi|
      poi['properties']['metadata']['category_ids'] = poi['properties']['metadata']['category_ids']&.sort
      poi
    }.uniq{ |poi|
      poi['properties']['metadata']['id']
    }.sort_by{ |poi|
      poi['properties']['metadata']['id']
    }
end

def compare_pois(pois_old, pois_new)
  hashes = [pois_old, pois_new]

  # From WP pois.geojson, pois in multiple categories are missing.
  # Use menu_sources.json to get missing categories fields.
  # remove_category_ids = missing_category_ids(fetch_json("#{url_old}/menu_sources.json"), hashes[0])
  # hashes[1] = hashes[1].select{ |poi| (remove_category_ids & poi['properties']['metadata']['category_ids']).empty? }

  puts "Diff POI size: #{hashes[0].size} != #{hashes[1].size}" if hashes[0].size != hashes[1].size

  ids = hashes.collect{ |h|
    h.collect{ |poi|
      [poi['properties']['metadata']['id'], poi['properties']['metadata']['category_ids']]
    }.to_h
  }
  only_in_0 = ids[0].keys - ids[1].keys
  only_in_1 = ids[1].keys - ids[0].keys

  only_in_0 = only_in_0.select{ |poi_id|
    poi = hashes[0].find{ |poi| poi_id == poi['properties']['metadata']['id'] }
    if poi['properties']['metadata']['osm_id'].nil?
      true
    else
      source_id = "#{poi['properties']['metadata']['osm_type'][0]}#{poi['properties']['metadata']['osm_id']}"
      if source_id.nil?
        true
      else
        hashes[1].find{ |poi| source_id == "#{poi['properties']['metadata']['osm_type']&.[](0)}#{poi['properties']['metadata']['osm_id']}" }.nil?
      end
    end
  }
  if !only_in_0.empty?
    puts "POI ids only on 0\n#{only_in_0.inspect}"
    puts "    by category ids #{only_in_0.collect{ |id| ids[0][id] }.tally.inspect}"
  end
  if !only_in_1.empty?
    puts "POI ids only on 1\n#{only_in_1.inspect}"
    puts "    by category ids #{only_in_1.collect{ |id| ids[1][id] }.tally.inspect}"
  end

  common_ids = Set.new(ids[0].keys & ids[1].keys)
  hashes = hashes.collect{ |h| h.select{ |poi| common_ids.include?(poi['properties']['metadata']['id']) } }

  dep_ids = hashes[0].zip(hashes[1]).each{ |h|
    # Ignore few changes on names
    a, b = h.collect{ |poi|
      poi.dig('properties', 'name')&.gsub('\\', '') # WP lost some \
    }
    if a.presence && b.presence && a.size > 5 && b.size > 5
      d = DamerauLevenshtein.distance(a, b)
      if d <= 3
        h[0]['properties']['name'] = h[1]['properties']['name']
      end
    end

    # No name, filled by API with diffrent rule from WP
    if a.presence && b.presence && (a == h[0]['properties']['classe'])
      h[0]['properties'].delete('name')
      h[1]['properties'].delete('name')
    end

    a, b = h.collect{ |poi|
      poi.dig('properties', 'description')&.gsub('\\', '') # WP lost some \
    }
    if a.presence && b.presence
      h[0]['properties']['description'] = h[1]['properties']['description']
    end

    # categories_ids
    if !(
      (h[0]['properties']['metadata']['category_ids'] || []) |
      (h[1]['properties']['metadata']['category_ids'] || [])
    ).empty?
      # Force WP categories_ids to contains all categories_ids
      h[1]['properties']['metadata']['category_ids'] = h[0]['properties']['metadata']['category_ids']
    end

    if !h[0]['properties']['metadata']['category_ids']&.empty?
      # Has it have multiple category_ids, could have different values, force to be the same
      h[0]['properties']['display']['style_class'] = h[1]['properties']['display']['style_class'] if !h[1].dig('properties', 'display', 'style_class').nil?
      h[0]['properties']['display']['details_fields'] = h[1]['properties']['display']['details_fields'] if !h[1].dig('properties', 'display', 'details_fields').nil?
      h[0]['properties']['display']['list_fields'] = h[1]['properties']['display']['list_fields'] if !h[1].dig('properties', 'display', 'list_fields').nil?
    end

    if h[0]['properties']['source:image'] == 'local'
      h[0]['properties'].delete('source:image')
    end
    if h[0].dig('properties', 'editorial', 'source:website:details') == 'local'
      h[0]['properties']['editorial']&.delete('source:website:details')
    end

    dep_ids = h.collect{ |hh| hh['properties']['metadata']['dep_ids'] }.flatten.uniq

    # dep_ids is missing on WP for object from datasources
    if h[0]['properties']['metadata']['dep_ids'].nil?
      h[1]['properties']['metadata'].delete('dep_ids')
    end

    if h[0]['properties']['metadata']['dep_ids'].present?
      h[0]['properties']['metadata']['dep_ids'] -= [-1]
    end
    if h[1]['properties']['metadata']['dep_ids'].present?
      h[1]['properties']['metadata']['dep_ids'] = h[1]['properties']['metadata']['dep_ids'].select{ |id| id / 10_000 != 654_65 }
    end

    h.each{ |poi|
      poi['properties']['metadata'].delete('cartocode')
      poi['properties'].delete('classe')
    }

    dep_ids
  }.flatten.uniq

  hashes_by_category_ids = hashes.collect{ |hash|
    hash.group_by{ |poi| poi['properties']['metadata']['category_ids'] || [] }
  }
  puts "Diff POI's Category size: #{hashes_by_category_ids[0].size} != #{hashes_by_category_ids[1].size}" if hashes_by_category_ids[0].size != hashes_by_category_ids[1].size
  if hashes_by_category_ids[0].keys.sort != hashes_by_category_ids[1].keys.sort
    puts [hashes_by_category_ids[0].keys.sort, hashes_by_category_ids[1].keys.sort].inspect
    p0 = hashes_by_category_ids[0].keys.collect(&:first)
    intersect = hashes_by_category_ids[1].keys.select{ |pp1| pp1.intersection(p0).empty? }
    if !intersect.empty?
      puts "Diff POI's Category #{intersect.join(' ')}"
    end
  end

  diff = HashDiff::Comparison.new(hashes[0], hashes[1])
  diff = diff.diff.transform_keys{ |i| hashes.dig(0, i, 'properties', 'metadata', 'id') }
  puts JSON.dump(diff) if !diff.empty?

  dep_ids
end

def compare_pois_geojson(url_old, url_new, category_ids)
  hashes = [
    "#{url_old}/pois.geojson",
    "#{url_new}/pois.geojson",
  ].each_with_index.collect{ |url, index|
    pois = fetch_json(url)['features']&.compact_blank_deep
    clean_pois(pois, category_ids[index])
  }
  dep_ids = compare_pois(hashes[0], hashes[1])

  poi_ids_with_deps = hashes.collect{ |pois|
    pois.select{ |poi|
      !poi['properties']['metadata']['dep_ids'].nil?
    }.collect{ |poi|
      poi['properties']['metadata']['id']
    }
  }.flatten.uniq
  poi_ids_with_deps.each{ |poi_id|
    begin
      hashes = [
        "#{url_old}/poi/#{poi_id}/deps.geojson",
        "#{url_new}/poi/#{poi_id}/deps.geojson",
      ].each_with_index.collect{ |url, index|
        pois = fetch_json(url)['features'].compact_blank_deep
        pois = clean_pois(pois, nil)
        pois.sort_by{ |poi|
          "#{poi['properties'].key?('route:point:type')}-%04d" % poi['properties']['metadata']['id']
        }.each_with_index.collect{ |poi, i|
          poi['properties']['metadata']['id'] = i
          poi
        }
      }
      hashes = compare_pois(hashes[0], hashes[1])
    rescue StandardError => e
      puts "POIS deps #{poi_id} FAILS ^^^"
    end
  }
end

def compare_attribute_translations(url_old, url_new)
  hashes = [
    "#{url_old}/attribute_translations/fr.json",
    "#{url_new}/attribute_translations/fr.json",
  ].collect{ |url|
    hash = fetch_json(url).except('id', 'slug')
    hash.transform_values{ |v|
      if v['label'] == v['label_popup']
        v.delete('label_popup')
      end
      if v['label'] == v['label_details']
        v.delete('label_details')
      end

      %w[label label_popup label_details].each{ |k|
        v[k]['fr'] = v[k]['fr'].strip.capitalize if !v.dig(k, 'fr').nil?
      }
      if v['values']
        v['values'] = v['values'].transform_values{ |vv|
          vv['label']['fr'] = vv['label']['fr'].strip.capitalize if !vv.dig('label', 'fr').nil?
        }
      end
    }
    hash
  }

  prune = lambda { |obj|
    return nil if obj.is_a?(Array) && obj[0].to_s == 'HashDiff::NO_VALUE'

    if obj.is_a?(Hash)
      obj.transform_values{ |v| prune.call(v) }.compact_blank
    elsif obj.is_a?(Array)
      obj.collect{ |o| prune.call(o) }.compact_blank
    else
      obj
    end
  }

  diff = HashDiff::Comparison.new(hashes[0], hashes[1])
  json_diff = prune.call(diff.diff)
  puts JSON.dump(json_diff) if !json_diff.empty?
end

namespace :api do
  desc 'Validate API JSON with Swagger Schema'
  task :diff, [] => :environment do
    url_old, url_new = ARGV[2..]
    compare_settings(url_old, url_new)
    compare_articles(url_old, url_new)
    category_ids = compare_menu(url_old, url_new)
    compare_pois_geojson(url_old, url_new, category_ids)
    compare_attribute_translations(url_old, url_new)

    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
