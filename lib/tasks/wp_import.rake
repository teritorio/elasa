# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'
require 'pg'
require 'cgi'

require_relative 'sources_load'


def fetch_json(url)
  response = HTTP.follow.get(url)
  raise "[ERROR] #{url} => #{response.status}" if !response.status.success?

  JSON.parse(response)
end

def load_settings(project_slug, theme_slug, url, url_articles)
  settings = fetch_json(url)
  articles = fetch_json(url_articles)

  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    project_id = conn.exec(
      '
      INSERT INTO projects(slug, name, icon_font_css_url, polygon, polygons_extra, articles, default_country, default_country_state_opening_hours)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      ON CONFLICT (slug)
      DO UPDATE SET
        name = $2,
        icon_font_css_url = $3,
        polygon = $4,
        polygons_extra = $5,
        articles = $6,
        default_country = $7,
        default_country_state_opening_hours = $8
      RETURNING
        id
      ',
      [
        project_slug,
        { fr: settings['name'] }.to_json,
        settings['icon_font_css_url'],
        settings['polygon']['data'].to_json,
        settings['polygons_extra'].to_json,
        articles.collect{ |article|
          {
            title: { fr: article['title'] },
            url: { fr: article['url'] },
          }
        }.to_json,
        settings['default_country'],
        settings['default_country_state_opening_hours'],
      ]
    ) { |result|
      result.first['id'].to_i
    }

    theme = settings['themes'].first
    theme_id = conn.exec(
      '
      INSERT INTO themes(project_id, slug, name, description, site_url, main_url, logo_url, favicon_url, keywords, favorites_mode, explorer_mode)
      VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
      )
      ON CONFLICT (project_id, slug)
      DO UPDATE SET
        name = $3,
        description = $4,
        site_url = $5,
        main_url = $6,
        logo_url = $7,
        favicon_url = $8,
        keywords = $9,
        favorites_mode = $10,
        explorer_mode = $11
      RETURNING
        id
        ',
      [
        project_id,
        theme_slug,
        theme['title'].to_json,
        theme['description'].to_json,
        theme['site_url'].transform_values{ |url| url.end_with?('/') ? url[0..-2] : url }.transform_values{ |url| url.start_with?('http') ? url : "https://#{url}" }.to_json,
        theme['main_url'].to_json,
        theme['logo_url'],
        theme['favicon_url'],
        { fr: theme['keywords'] || '' }.to_json,
        theme['favorites_mode'] != false,
        theme['explorer_mode'] != false,
      ]
    ) { |result|
      result.first['id'].to_i
    }

    [project_id, theme_id]
  }
end

def menu_type(menu)
  if menu['category']
    'category'
  elsif menu['menu_group']
    'menu_group'
  elsif menu['link']
    'link'
  else
    'search'
  end
end

def menu_dig_all(menu, property)
  menu.dig('category', property) || menu.dig('menu_group', property) || menu.dig('link', property)
end

@fields = {}

def load_field_group(conn, project_id, group)
  group_key = group.except('group')
  if @fields[group_key]
    @fields[group_key]
  else
    if group['group']
      ids = (group['fields'] || []).collect{ |f|
        load_field_group(conn, project_id, f)
      }
    end

    id = conn.exec(
      '
    INSERT INTO fields(
      project_id,
      type,
      field,
      label,
      "group", display_mode, icon
    )
    VALUES (
      $1, $2, $3, $4, $5, $6, $7
    )
    RETURNING
      id
    ', [
        project_id,
        group['group'] ? 'group' : 'field',
        group['field'],
        group['label'],
        group['group'],
        group['display_mode'],
        group['icon'],
      ]
    ) { |result|
      @fields[group_key] = result.first['id'].to_i
    }

    if group['group']
      ids.each_with_index { |i, index|
        conn.exec('INSERT INTO fields_fields(fields_id, related_fields_id, index) VALUES ($1, $2, $3)', [id, i, index])
      }
    end

    id
  end
end

def load_fields(conn, project_id, pois)
  fields = pois.collect{ |poi|
    [
      poi.dig('properties', 'metadata', 'category_ids')&.select{ |id| id != 0 }, # 0 from buggy WP
      poi.dig('properties', 'editorial', 'popup_fields'),
      poi.dig('properties', 'editorial', 'details_fields'),
      poi.dig('properties', 'editorial', 'list_fields'),
    ]
  }.uniq

  fields = fields.collect{ |y|
    y[0].collect{ |yy|
      [yy] + y[1..]
    }
  }.flatten(1)

  multiple_config = fields.group_by(&:first).select{ |_id, g| g.size != 1 }.collect(&:first)
  if !multiple_config.empty?
    puts "[ERROR] Mutiple fields configuration for categrories #{multiple_config} - IGNORED"
  end

  puts "fields: #{fields.size}"
  fields.select{ |field|
    !multiple_config.include?(field[0])
  }.collect{ |field|
    [field[0]] + field[1..].collect{ |f|
      load_field_group(conn, project_id, {
        'group' => '',
        'fields' => f,
      })
    }
  }
end

def menu_from_poi(pois, object)
  labels = pois.collect{ |poi|
    [
      poi.dig('properties', 'metadata', 'category_ids')&.select{ |id| id != 0 }, # 0 from buggy WP
      yield(poi)
    ]
  }.uniq

  labels = labels.collect{ |y|
    y[0].collect{ |yy|
      [yy] + y[1..]
    }
  }.flatten(1)

  labels = labels.group_by(&:first)
  multiple_config = labels.select{ |_id, g| g.size != 1 }.collect(&:first)
  if !multiple_config.empty?
    puts "[ERROR] Mutiple configuration for #{object}: #{multiple_config} - IGNORED"
  end

  labels.select{ |_id, g| g.size == 1 }.transform_values(&:last).transform_values(&:last)
end

def load_class_labels(pois)
  menu_from_poi(pois, 'editorial.class_label_popup') { |poi|
    poi.dig('properties', 'editorial', 'class_label_popup')
  }
end

def load_use_details_link(pois)
  menu_from_poi(pois, 'editorial.website:details') { |poi|
    !poi.dig('properties', 'editorial', 'website:details').nil?
  }
end

def load_icon(pois)
  menu_from_poi(pois, 'display.icon') { |poi|
    poi.dig('properties', 'display', 'icon')
  }
end

def load_style_class(pois)
  menu_from_poi(pois, 'display.style_class') { |poi|
    poi.dig('properties', 'display', 'style_class')
  }
end

def load_color_fill(pois)
  menu_from_poi(pois, 'display.color_fill') { |poi|
    poi.dig('properties', 'display', 'color_fill')
  }
end

def load_color_line(pois)
  menu_from_poi(pois, 'display.color_line') { |poi|
    poi.dig('properties', 'display', 'color_line')
  }
end

def load_menu(project_id, theme_id, url, url_pois, url_menu_sources)
  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    conn.exec('DELETE FROM menu_items WHERE theme_id = $1', [theme_id])
    conn.exec('DELETE FROM filters WHERE project_id = $1', [project_id])
    conn.exec('DELETE FROM fields WHERE project_id = $1', [project_id])

    pois = fetch_json(url_pois)['features']
    fields = load_fields(conn, project_id, pois)
    fields_ids = fields.index_by(&:first)

    menu_sources = fetch_json(url_menu_sources)

    menu_items = fetch_json(url)

    # Insert root menu
    menu_items.each{ |menu|
      menu['parent_id'] = 0 if menu['parent_id'].nil?
    }
    menu_items.unshift({
      'id' => 0,
      'parent_id' => nil,
      'selected_by_default' => false,
      'hidden' => false,
      'index_order' => 0,
      'menu_group' => {
        'id' => 0,
        'name' => {
          'en' => 'Root',
          'fr' => 'Racine',
        },
        'icon' => '',
        'color_fill' => '',
        'color_line' => '',
        'style_class' => nil,
        'display_mode' => 'compact'
      },
    })

    labels = load_class_labels(pois)
    use_details_link = load_use_details_link(pois)
    icon = load_icon(pois)
    style_class = load_style_class(pois)
    color_fill = load_color_fill(pois)
    color_line = load_color_line(pois)
    catorgry_ids_map = {}
    puts "menu_items: #{menu_items.size}"
    menu_entries = menu_items.reverse
    until menu_entries.empty?
      menu = menu_entries.pop
      if !menu['parent_id'].nil? && !catorgry_ids_map.key?(menu['parent_id'])
        # parent_id not mapped yet
        menu_entries.unshift(menu)
        next
      end

      fields_id = fields_ids[menu['id']]
      conn.exec(
        '
        INSERT INTO menu_items(
          theme_id,
          slugs, index_order, hidden, parent_id, selected_by_default,
          type,
          name, name_singular, icon, color_fill, color_line, style_class_string, display_mode,
          search_indexed, style_merge, zoom, popup_fields_id, details_fields_id, list_fields_id,
          href, use_details_link
        )
        VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22
        )
        RETURNING
          id
        ', [
          theme_id,
          { original_id: menu['id'] }.to_json, # Use original id as slug
          menu['index_order'],
          menu['hidden'],
          catorgry_ids_map[menu['parent_id']],
          menu['selected_by_default'],
          menu_type(menu),
          menu_dig_all(menu, 'name').to_json,
          labels[menu['id']]&.to_json,
          menu_dig_all(menu, 'icon').presence || icon[menu['id']] || 'teritorio teritorio-services',
          menu_dig_all(menu, 'color_fill').presence || color_fill[menu['id']] || '#ff0000',
          menu_dig_all(menu, 'color_line').presence || color_line[menu['id']] || '#ff0000',
          (menu_dig_all(menu, 'style_class')&.compact_blank || style_class[menu['id']])&.join(','),
          menu_dig_all(menu, 'display_mode') || 'compact',
          menu.dig('category', 'search_indexed'),
          menu.dig('category', 'style_merge'),
          Integer(menu.dig('category', 'zoom'), exception: false),
          fields_id.nil? ? nil : fields_id[1],
          fields_id.nil? ? nil : fields_id[2],
          fields_id.nil? ? nil : fields_id[3],
          menu.dig('link', 'href'),
          use_details_link[menu['id']],
        ]
      ) { |result|
        catorgry_ids_map[menu['id']] = result.first['id']
      }
    end

    menu_sources.each{ |menu_id, sources|
      category_id = catorgry_ids_map[menu_id.to_i]
      next if category_id.nil?

      sources.each{ |source|
        source_slug = CGI.unescape(source.split('/')[-1].split('.')[0])
        id = conn.exec(
          '
          INSERT INTO menu_items_sources(menu_items_id, sources_id)
          SELECT
            $2,
            sources.id
          FROM
            sources
          WHERE
            sources.project_id = $1 AND
            sources.slug = $3
          RETURNING
            id
          ',
          [project_id, category_id, source_slug]
        ) { |result|
          result&.first
        }
        if id.nil?
          puts "[ERROR] Fails link source to menu_item: #{source} (#{source_slug})"
        end
      }
    }

    filters = Hash.new { |h, k| h[k] = [] }
    menu_items.select{ |menu_item| !menu_item.dig('category', 'filters').nil? }.each{ |category|
      category['category']['filters'].each{ |filter|
        filters[filter] << category['category']['id']
      }
    }

    puts "filters: #{filters.size}"
    filters = filters.each{ |filter, category_ids|
      filter_id = conn.exec(
        '
        INSERT INTO filters(
          project_id,
          type,
          name,
          -- date_range
          property_begin,
          property_end,
          -- number_range
          number_range_property,
          min,
          max,
          -- multiselection
          multiselection_property,
          -- checkboxes_list
          checkboxes_list_property,
          -- boolean
          boolean_property
        )
        VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
        )
        RETURNING
          id
        ', [
          project_id,
          filter['type'],
          filter['name'].to_json,
          # date_range
          filter['property_begin'],
          filter['property_end'],
          # number_range
          filter['property'],
          filter['min'],
          filter['max'],
          # multiselection
          filter['property'],
          # checkboxes_list
          filter['property'],
          # boolean
          filter['property'],
        ]
      ) { |result|
        result.first['id']
      }

      category_ids.each{ |category_id|
        conn.exec(
          '
          INSERT INTO menu_items_filters(menu_items_id, filters_id)
          VALUES ($1, $2)
          ',
          [catorgry_ids_map[category_id], filter_id]
        )
      }
    }

    # Set theme root menu
    conn.exec(
      '
      UPDATE
        themes
      SET
        root_menu_item_id = $3
      FROM
        projects
      WHERE
        projects.id = $1 AND
        themes.project_id = projects.id AND
        themes.id = $2
      ',
      [project_id, theme_id, catorgry_ids_map[0]]
    )

    puts "pois slug update: #{pois.size}"
    slugs = pois.select{ |poi|
      poi.dig('properties', 'metadata', 'source') != 'zone' && poi.dig('properties', 'metadata', 'source') != 'tis'
    }.collect{ |poi|
      id = poi.dig('properties', 'metadata', 'id')
      ref = poi.dig('properties', 'tis_id') || poi.dig('properties', 'metadata', 'source_id')
      if ref.nil? && !poi.dig('properties', 'metadata', 'osm_type').nil? && !poi.dig('properties', 'metadata', 'osm_id').nil?
        ref = poi.dig('properties', 'metadata', 'osm_type')[0] + poi.dig('properties', 'metadata', 'osm_id').to_s
      end
      if ref.nil? && !poi.dig('properties', 'osm_poi_type').nil? && !poi.dig('properties', 'idosm').nil?
        ref = poi.dig('properties', 'osm_poi_type')[0] + poi.dig('properties', 'idosm').to_s
      end

      if id.nil? || ref.nil?
        puts "nil ref/id on #{JSON.dump(poi)}"
        nil
      else
        [id, ref]
      end
    }.compact_blank.collect{ |id, ref|
      [project_id, ref, { original_id: id.to_s }.to_json]
    }

    conn.exec("
      CREATE TEMP TABLE pois_slug_import(
        project_id varchar NOT NULL,
        ref varchar NOT NULL,
        original_id json NOT NULL
      )
    ")
    enco = PG::BinaryEncoder::CopyRow.new
    conn.copy_data('COPY pois_slug_import FROM STDIN (FORMAT binary)', enco) {
      slugs.each { |i|
        conn.put_copy_data(i)
      }
    }

    conn.exec_params(
      "
      UPDATE
        pois
      SET
        slugs = (coalesce(slugs::jsonb, '{}'::jsonb) || pois_slug_import.original_id::jsonb)::json
      FROM
        sources,
        pois_slug_import
      WHERE
        sources.project_id = pois_slug_import.project_id::integer AND
        pois.source_id = sources.id AND
        pois.properties->>'id' = pois_slug_import.ref
      "
    )
  }
end

def load_i18n(project_id, url)
  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    conn.exec('DELETE FROM translations WHERE project_id = $1', [project_id])

    i18ns = fetch_json(url)
    puts "i18n: #{i18ns.size}"
    i18ns.each{ |key, i18n|
      conn.exec(
        '
        INSERT INTO translations(project_id, key, key_translations, values_translations)
        VALUES (
          $1, $2, $3, $4
        )
        ',
        [project_id, key, i18n.except('values').to_json, i18n['values']&.to_json]
      )
    }
  }
end

namespace :wp do
  desc 'Import data from API'
  task :import, [] => :environment do
    url, project_slug, theme_slug, datasource_url, datasource_project = ARGV[2..]
    datasource_project ||= project_slug
    puts "\n====\n#{project_slug}\n====\n\n"
    base_url = "#{url}/#{project_slug}/#{theme_slug}"
    project_id, theme_id = load_settings(project_slug, theme_slug, "#{base_url}/settings.json", "#{base_url}/articles.json?slug=non-classe")
    load_from_source("#{datasource_url}/data", project_slug, datasource_project)
    load_menu(project_id, theme_id, "#{base_url}/menu.json", "#{base_url}/pois.json", "#{base_url}/menu_sources.json")
    load_i18n(project_id, "#{datasource_url}/data/#{datasource_project}/i18n.json")
    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
