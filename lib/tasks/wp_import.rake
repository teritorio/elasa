# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'
require 'pg'


def fetch_json(url)
  JSON.parse(HTTP.follow.get(url))
end

def load_settings(project_slug, _theme_slug, url, url_articles)
  settings = fetch_json(url)
  articles = fetch_json(url_articles)

  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    conn.exec(
      '
      INSERT INTO projects(slug, name, icon_font_css_url, polygon, articles)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (slug)
      DO UPDATE SET
        name = $2,
        icon_font_css_url = $3,
        polygon = $4,
        articles = $5
      ',
      [
        project_slug,
        { fr: settings['name'] }.to_json,
        'https://carte.seignanx.com/content/wp-content/plugins/font-teritorio/dist/teritorio.css?ver=2.7.0',
        settings['polygon']['data'].to_json,
        articles.collect{ |article|
          {
            title: { fr: article['title'] },
            url: { fr: article['url'] },
          }
        }.to_json,
      ]
    )

    settings['themes'].each{ |theme|
      conn.exec(
        '
        INSERT INTO themes(project_id, slug, name, description, site_url, main_url, logo_url, favicon_url)
        VALUES (
          (SELECT id FROM projects WHERE slug = $1),
          $2, $3, $4, $5, $6, $7, $8
        )
        ON CONFLICT (project_id, slug)
        DO UPDATE SET
          name = $3,
          description = $4,
          site_url = $5,
          main_url = $6,
          logo_url = $7,
          favicon_url = $8
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

def load_fields(conn, project_slug, url)
  pois = fetch_json(url)
  fields = pois['features'].collect{ |poi|
    [
      poi.dig('properties', 'metadata', 'category_ids'),
      poi.dig('properties', 'editorial', 'popup_fields'),
      poi.dig('properties', 'editorial', 'details_fields'),
      poi.dig('properties', 'editorial', 'list_fields'),
    ]
  }.uniq

  fields.each{ |category_ids, _popup_fields, _details_fields, _list_fields|
    if category_ids.size != 1
      throw 'category_ids.size != 1'
    end
  }

  fields = fields.collect{ |y| [y[0][0]] + y[1..] }

  multiple_config = fields.group_by(&:first).select{ |_id, g| g.size != 1 }.collect(&:first)
  if multiple_config.size > 0
    puts '==================='
    puts "Mutiple fields configuration for categrories #{multiple_config} - IGNORED"
    puts '==================='
  end

  fields.select{ |field|
    !multiple_config.include?(field)
  }.collect{ |field|
    ids = field[1..].collect{ |f|
      load_field_group(conn, project_slug, {
        'group' => '',
        'fields' => f,
      })
    }
  }
end

def load_menu(project_slug, theme_slug, url, url_pois)
  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    conn.exec('DELETE FROM menu_items WHERE theme_id = (SELECT themes.id FROM projects JOIN themes ON themes.slug = $2 AND projects.slug = $1)', [project_slug, theme_slug])
    conn.exec('DELETE FROM filters WHERE project_id = (SELECT id FROM projects WHERE projects.slug = $1)', [project_slug])
    conn.exec('DELETE FROM fields WHERE project_id = (SELECT id FROM projects WHERE projects.slug = $1)', [project_slug])

    fields = load_fields(conn, project_slug, url_pois)
    fields_ids = fields.index_by(&:first)

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
          index_order, hidden, parent_id, selected_by_default,
          type,
          name, icon, color_fill, color_line, style_class_string, display_mode,
          search_indexed, zoom, popup_fields_id, details_fields_id, list_fields_id,
          href
        )
        VALUES (
          (SELECT themes.id FROM projects JOIN themes ON themes.slug = $2 AND projects.slug = $1),
          $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19
        )
        RETURNING
          id
        ', [
          project_slug,
          theme_slug,
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
          menu.dig('category', 'zoom'),
          fields_id.nil? ? nil : fields_id[0],
          fields_id.nil? ? nil : fields_id[1],
          fields_id.nil? ? nil : fields_id[2],
          menu.dig('link', 'href'),
        ]
      ) { |result|
        catorgry_ids_map[menu['id']] = result.first['id']
      }
    end

    filters = Hash.new { |h, k| h[k] = [] }
    menu_items.select{ |menu| !menu.dig('category', 'filters').nil? }.each{ |menu|
      menu['category']['filters'].each{ |filter|
        filters[filter] << menu['category']['id']
      }
    }

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
  }
end

namespace :wp do
  desc 'Import data from API'
  task :import, %i[project_slug theme_slug] => :environment do |_tasks, args|
    base_url = "https://carte.seignanx.com/content/api.teritorio/geodata/v0.1/#{args[:project_slug]}/#{args[:theme_slug]}"
    load_settings(args[:project_slug], args[:theme_slug], "#{base_url}/settings.json", "#{base_url}/articles.json?slug=non-classe")
    load_menu(args[:project_slug], args[:theme_slug], "#{base_url}/menu.json", "#{base_url}/pois.json")
  end
end
