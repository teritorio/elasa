# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'
require 'pg'

require_relative 'sources_load'


def fetch_json(url)
  response = HTTP.follow.get(url)
  raise "#{url} => #{response.status}" if !response.status.success?

  JSON.parse(response)
end

def load_settings(project_slug, _theme_slug, url, url_articles)
  settings = fetch_json(url)
  articles = fetch_json(url_articles)

  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    conn.exec(
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
      ',
      [
        project_slug,
        { fr: settings['name'] }.to_json,
        'https://carte.seignanx.com/content/wp-content/plugins/font-teritorio/dist/teritorio.css?ver=2.7.0',
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
    )

    settings['themes'].each{ |theme|
      conn.exec(
        '
        INSERT INTO themes(project_id, slug, name, description, site_url, main_url, logo_url, favicon_url, keywords, favorites_mode, explorer_mode)
        VALUES (
          (SELECT id FROM projects WHERE slug = $1),
          $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
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
        ',
        [
          project_slug,
          theme['slug'],
          theme['title'].to_json,
          theme['description'].to_json,
          theme['site_url'].to_json,
          theme['main_url'].to_json,
          theme['logo_url'],
          theme['favicon_url'],
          { fr: theme['keywords'] || '' }.to_json,
          theme['favorites_mode'] != false,
          theme['explorer_mode'] != false,
        ]
      )
    }
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

def load_field_group(conn, project_slug, group)
  group_key = group.except('group')
  if @fields[group_key]
    @fields[group_key]
  else
    if group['group']
      ids = (group['fields'] || []).collect{ |f|
        load_field_group(conn, project_slug, f)
      }
    end

    id = conn.exec(
      '
    INSERT INTO fields(
      project_id,
      type,
      field,
      "group", display_mode, icon
    )
    VALUES (
      (SELECT id FROM projects WHERE slug = $1),
      $2, $3, $4, $5, $6
    )
    RETURNING
      id
    ', [
        project_slug,
        group['group'] ? 'group' : 'field',
        group['field'],
        group['group'],
        group['display_mode'],
        group['icon'],
      ]
    ) { |result|
      @fields[group_key] = result.first['id'].to_i
    }

    if group['group']
      ids.each { |i|
        conn.exec('INSERT INTO fields_fields(fields_id, related_fields_id) VALUES ($1, $2)', [id, i])
      }
    end

    id
  end
end

def load_fields(conn, project_slug, pois)
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
    puts '==================='
    puts "Mutiple fields configuration for categrories #{multiple_config} - IGNORED"
    puts '==================='
  end

  puts "fields: #{fields.size}"
  fields.select{ |field|
    !multiple_config.include?(field[0])
  }.collect{ |field|
    [field[0]] + field[1..].collect{ |f|
      load_field_group(conn, project_slug, {
        'group' => '',
        'fields' => f,
      })
    }
  }
end

def load_menu(project_slug, theme_slug, url, url_pois, url_menu_sources)
  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    conn.exec('DELETE FROM menu_items WHERE theme_id = (SELECT themes.id FROM projects JOIN themes ON themes.slug = $2 AND themes.project_id = projects.id WHERE projects.slug = $1)', [project_slug, theme_slug])
    conn.exec('DELETE FROM filters WHERE project_id = (SELECT id FROM projects WHERE projects.slug = $1)', [project_slug])
    conn.exec('DELETE FROM fields WHERE project_id = (SELECT id FROM projects WHERE projects.slug = $1)', [project_slug])

    pois = fetch_json(url_pois)['features']
    fields = load_fields(conn, project_slug, pois)
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
          name, icon, color_fill, color_line, style_class_string, display_mode,
          search_indexed, style_merge, zoom, popup_fields_id, details_fields_id, list_fields_id,
          href
        )
        VALUES (
          (SELECT themes.id FROM projects JOIN themes ON themes.slug = $2 AND themes.project_id = projects.id WHERE projects.slug = $1),
          $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21
        )
        RETURNING
          id
        ', [
          project_slug,
          theme_slug,
          { original_id: menu['id'] }.to_json, # Use original id as slug
          menu['index_order'],
          menu['hidden'],
          catorgry_ids_map[menu['parent_id']],
          menu['selected_by_default'],
          menu_type(menu),
          menu_dig_all(menu, 'name').to_json,
          menu_dig_all(menu, 'icon'),
          menu_dig_all(menu, 'color_fill'),
          menu_dig_all(menu, 'color_line'),
          menu_dig_all(menu, 'style_class')&.join(','),
          menu_dig_all(menu, 'display_mode'),
          menu.dig('category', 'search_indexed'),
          menu.dig('category', 'style_merge'),
          Integer(menu.dig('category', 'zoom'), exception: false),
          fields_id.nil? ? nil : fields_id[1],
          fields_id.nil? ? nil : fields_id[2],
          fields_id.nil? ? nil : fields_id[3],
          menu.dig('link', 'href'),
        ]
      ) { |result|
        catorgry_ids_map[menu['id']] = result.first['id']
      }
    end

    menu_sources.each{ |menu_id, sources|
      category_id = catorgry_ids_map[menu_id.to_i]
      next if category_id.nil?

      sources.each{ |source|
        source_slug = source.split('/')[-1].split('.')[0]
        puts [category_id, source_slug].inspect
        id = conn.exec(
          '
          INSERT INTO menu_items_sources(menu_items_id, sources_id)
          SELECT
            $2,
            sources.id
          FROM
            projects
            JOIN sources ON
              sources.project_id = projects.id AND
              sources.slug = $3
          WHERE
            projects.slug = $1
          RETURNING
            id
          ',
          [project_slug, category_id, source_slug]
        ) { |result|
          result&.first
        }
        if id.nil?
          puts '==================='
          puts "Fails link source to menu_item: #{source}"
          puts '==================='
        end
      }
    }

    filters = Hash.new { |h, k| h[k] = [] }
    menu_items.select{ |menu| !menu.dig('category', 'filters').nil? }.each{ |menu|
      menu['category']['filters'].each{ |filter|
        filters[filter] << menu['category']['id']
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
          (SELECT id FROM projects WHERE projects.slug = $1),
          $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
        )
        RETURNING
          id
        ', [
          project_slug,
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
        projects.slug = $1 AND
        themes.project_id = projects.id AND
        themes.slug = $2
      ',
      [project_slug, theme_slug, catorgry_ids_map[0]]
    )

    pois.select{ |poi|
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
    }.compact_blank.each{ |id, ref|
      conn.exec(
        '
        UPDATE
          pois
        SET
          slugs = $3
        FROM
          projects
          JOIN sources ON
            sources.project_id = projects.id
        WHERE
          projects.slug = $1 AND
          pois.properties->>\'id\' = $2
        ',
        [project_slug, ref, { original_id: id.to_s }.to_json]
      )
    }
  }
end

def load_i18n(project_slug, url)
  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    conn.exec('DELETE FROM translations WHERE project_id = (SELECT id FROM projects WHERE projects.slug = $1)', [project_slug])

    i18ns = fetch_json(url)
    i18ns.each{ |key, i18n|
      id = conn.exec(
        '
        INSERT INTO translations(project_id, key, key_translations, values_translations)
        VALUES (
          (SELECT id FROM projects WHERE projects.slug = $1),
          $2, $3, $4
        )
        ',
        [project_slug, key, i18n.except('values').to_json, i18n['values']&.to_json]
      )
    }
  }
end

namespace :wp do
  desc 'Import data from API'
  task :import, [] => :environment do
    url, project_slug, theme_slug, datasource_url = ARGV[2..]
    base_url = "#{url}/#{project_slug}/#{theme_slug}"
    load_settings(project_slug, theme_slug, "#{base_url}/settings.json", "#{base_url}/articles.json?slug=non-classe")
    load_sources("#{datasource_url}/data", project_slug)
    load_menu(project_slug, theme_slug, "#{base_url}/menu.json", "#{base_url}/pois.json", "#{base_url}/menu_sources.json")
    load_i18n(project_slug, "#{datasource_url}/data/#{project_slug}/i18n.json")
    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
