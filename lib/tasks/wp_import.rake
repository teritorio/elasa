# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'
require 'pg'
require 'cgi'

require_relative 'sources_load'


def uncapitalize(string)
  if string[0].match(/\p{Upper}/) && !string[1].match(/\p{Upper}/)
    string[0].downcase + string[1..]
  else
    string
  end
end

def fetch_json(url)
  response = HTTP.follow.get(url)
  return [] if response.status.code == 404
  raise "[ERROR] #{url} => #{response.status}" if !response.status.success?

  JSON.parse(response)
end

def load_settings(project_slug, theme_slug, url, url_articles)
  settings = fetch_json(url)
  articles = fetch_json(url_articles)

  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    project_id = conn.exec(
      '
      INSERT INTO projects(slug, icon_font_css_url, polygon, polygons_extra, articles, default_country, default_country_state_opening_hours)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (slug)
      DO UPDATE SET
        icon_font_css_url = $2,
        polygon = $3,
        polygons_extra = $4,
        articles = $5,
        default_country = $6,
        default_country_state_opening_hours = $7
      RETURNING
        id
      ',
      [
        project_slug,
        settings['icon_font_css_url'],
        settings['polygon']['data'].to_json,
        settings['polygons_extra']&.transform_values{ |polygon| polygon['data'].split('/')[-1].split('.')[0].to_i }&.to_json,
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

    if project_id
      conn.exec(
        '
        INSERT INTO projects_translations(projects_id, languages_code, name)
        VALUES ($1, $2, $3)
        ON CONFLICT (projects_id, languages_code)
        DO UPDATE SET
          name = $3
        ',
        [
          project_id,
          'fr-FR',
          settings['name'],
        ]
      )
    end


    theme = settings['themes'].first
    theme_id = conn.exec(
      '
      INSERT INTO themes(project_id, slug, logo_url, favicon_url, favorites_mode, explorer_mode)
      VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (project_id, slug)
      DO UPDATE SET
        logo_url = $3,
        favicon_url = $4,
        favorites_mode = $5,
        explorer_mode = $6
      RETURNING
        id
      ',
      [
        project_id,
        theme_slug,
        theme['logo_url'],
        theme['favicon_url'],
        theme['favorites_mode'] != false,
        theme['explorer_mode'] != false,
      ]
    ) { |result|
      result.first['id'].to_i
    }

    if theme_id
      conn.exec(
        '
        INSERT INTO themes_translations(themes_id, languages_code, name, description, site_url, main_url, keywords)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        ON CONFLICT (themes_id, languages_code)
        DO UPDATE SET
          name = $3,
          description = $4,
          site_url = $5,
          main_url = $6,
          keywords = $7
        ',
        [
          theme_id,
          'fr-FR',
          theme['title']['fr'],
          theme['description']['fr'],
          theme['site_url'].transform_values{ |site_url| site_url.end_with?('/') ? site_url[0..-2] : site_url }.transform_values{ |site_url| site_url.start_with?('http') ? site_url : "https://#{site_url}" }['fr'],
          theme['main_url']['fr'],
          theme['keywords'] || '',
        ]
      )
    end

    [project_id, theme_id, theme['site_url']['fr']]
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
      duplicate_fields = (group['fields'] || []).pluck('field').compact.tally.select{ |k, v| v > 1 }.keys
      if duplicate_fields.size > 0
        puts "[ERROR] Duplicate field in group #{group['group']}: #{duplicate_fields.join(', ')}"
      end
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

def load_fields(conn, project_id, pois, menu_items)
  menu_items = menu_items.index_by{ |menu| menu['id'] }

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
    [field[0]] + %w[popup details list].zip(field[1..]).collect{ |mode, f|
      load_field_group(conn, project_id, {
        'group' => "#{menu_items[field[0]]&.dig('category', 'name', 'fr')} #{mode}",
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

def load_use_internal_details_link(pois, host)
  pois.select { |poi|
    poi.dig('properties', 'editorial', 'website:details')&.start_with?(host)
  }.collect{ |poi|
    poi.dig('properties', 'metadata', 'category_ids')&.select{ |id| id != 0 } # 0 from buggy WP
  }.flatten.uniq.collect{ |id| [id, true] }.to_h
end

def load_use_external_details_link(pois, host)
  pois.select { |poi|
    website_details = poi.dig('properties', 'editorial', 'website:details')
    !website_details.nil? && !website_details.start_with?(host)
  }.collect{ |poi|
    poi.dig('properties', 'metadata', 'category_ids')&.select{ |id| id != 0 } # 0 from buggy WP
  }.flatten.uniq.collect{ |id| [id, true] }.to_h
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

# From WP pois.geojson, pois in multiple categories are missing.
# Use menu_sources.json to get missing categories fields.
def add_missing_pois(menu_sources, pois)
  menu_sources_multi = menu_sources.collect{ |menu_id, sources|
    sources.collect{ |source| [menu_id, source] }
  }.flatten(1).group_by(&:last).select{ |_source, source_menu_ids|
    source_menu_ids.size > 1
  }.transform_values{ |source_menu_ids|
    source_menu_ids.collect(&:first).collect(&:to_i)
  }

  poi_by_category = pois.collect{ |poi|
    [poi.dig('properties', 'metadata', 'category_ids'), poi]
  }.collect{ |category_ids, poi|
    category_ids.collect{ |category_id| [category_id, poi] }
  }.flatten(1).group_by(&:first).transform_values{ |category_ids_poi|
    category_ids_poi.first.last
  }.to_h

  category_ids_all = pois.collect{ |poi|
    poi.dig('properties', 'metadata', 'category_ids')&.select{ |id| id != 0 } # 0 from buggy WP
  }.flatten.uniq

  missing_category_ids = menu_sources_multi.values.flatten - category_ids_all
  puts "missing_category_ids: #{missing_category_ids.inspect}"
  equiv_pois = menu_sources_multi.collect{ |_source, menu_ids|
    equiv = menu_ids - missing_category_ids
    (menu_ids & missing_category_ids).collect{ |menu_id| [menu_id, equiv] }
  }.flatten(1).collect{ |menu_id, equiv|
    if equiv.empty?
      puts "[ERROR] Missing POI from category #{menu_id} without equivalence - IGNORED"
    else
      puts "Missing POI from WP. Fields configuration equivalence for category #{menu_id} from #{equiv[0]}."
      equiv_poi = poi_by_category[equiv[0]]
      equiv_poi['properties']['metadata']['category_ids'] = [menu_id]
      equiv_poi
    end
  }

  pois + equiv_pois
end

def load_menu(project_slug, project_id, theme_id, url, url_pois, url_menu_sources, i18ns, role_uuid, url_base)
  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    conn.exec('DELETE FROM menu_items WHERE theme_id = $1', [theme_id])
    conn.exec('DELETE FROM filters WHERE project_id = $1', [project_id])
    conn.exec('DELETE FROM fields WHERE project_id = $1', [project_id])

    menu_sources = fetch_json(url_menu_sources)
    if menu_sources.empty?
      menu_sources = {} # Buggy WP, replace empty [] by {}
    end

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

    pois = fetch_json(url_pois)['features']
    # Missing poi from buggy WP pois.geojson
    pois = add_missing_pois(menu_sources, pois)

    fields = load_fields(conn, project_id, pois, menu_items)
    fields_ids = fields.index_by(&:first)

    labels = load_class_labels(pois)
    use_internal_details_link = load_use_internal_details_link(pois, url.split('/')[0..2].join('/'))
    use_external_details_link = load_use_external_details_link(pois, url.split('/')[0..2].join('/'))
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
      menu_item_id = conn.exec(
        '
        INSERT INTO menu_items(
          theme_id,
          index_order, hidden, parent_id, selected_by_default,
          type,
          icon, color_fill, color_line, style_class_string, display_mode,
          search_indexed, style_merge, zoom, popup_fields_id, details_fields_id, list_fields_id,
          href, use_internal_details_link, use_external_details_link
        )
        VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20
        )
        RETURNING
          id
        ', [
          theme_id,
          menu['index_order'],
          menu['hidden'],
          catorgry_ids_map[menu['parent_id']],
          menu['selected_by_default'],
          menu_type(menu),
          menu_dig_all(menu, 'icon').presence || icon[menu['id']] || 'teritorio teritorio-beef00',
          menu_dig_all(menu, 'color_fill').presence || color_fill[menu['id']] || '#beef00',
          menu_dig_all(menu, 'color_line').presence || color_line[menu['id']] || '#beef00',
          menu_dig_all(menu, 'style_class')&.compact_blank&.join(','),
          menu_dig_all(menu, 'display_mode') || 'compact',
          menu.dig('category', 'search_indexed'),
          menu.dig('category', 'style_merge'),
          Integer(menu.dig('category', 'zoom'), exception: false),
          fields_id.nil? ? nil : fields_id[1],
          fields_id.nil? ? nil : fields_id[2],
          fields_id.nil? ? nil : fields_id[3],
          menu.dig('link', 'href'),
          use_internal_details_link[menu['id']],
          use_external_details_link[menu['id']],
        ]
      ) { |result|
        catorgry_ids_map[menu['id']] = result.first['id']
      }

      if menu_item_id
        conn.exec(
          '
          INSERT INTO menu_items_translations(menu_items_id, languages_code, slug, name, name_singular)
          VALUES ($1, $2, $3, $4, $5)
          ', [
            menu_item_id,
            'fr-FR',
            menu['id'],
            menu_dig_all(menu, 'name')&.dig('fr'),
            labels[menu['id']]&.dig('fr'),
          ]
        )
      end
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
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING
          id
        ', [
          project_id,
          filter['type'],
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

      if filter_id
        conn.exec(
          '
          INSERT INTO filters_translations(filters_id, languages_code, name)
          VALUES ($1, $2, $3)
          ', [
            filter_id,
            'fr-FR',
            filter['name']['fr'],
          ]
        )
      end


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
        [id, ref, poi.dig('properties', 'metadata', 'category_ids').min]
      end
    }.compact_blank.collect{ |id, ref, category_id|
      [project_id, ref, { original_id: id.to_s }.to_json, category_id]
    }

    conn.exec("
      CREATE TEMP TABLE pois_slug_import(
        project_id varchar NOT NULL,
        ref varchar NOT NULL,
        original_id json NOT NULL,
        category_id varchar NOT NULL
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
        menu_items_sources,
        menu_items,
        menu_items_translations,
        pois_slug_import
      WHERE
        sources.project_id = pois_slug_import.project_id::integer AND
        menu_items_sources.sources_id = sources.id AND
        menu_items.id = menu_items_sources.menu_items_id AND
        menu_items_translations.menu_items_id = menu_items.id AND
        menu_items_translations.languages_code = 'fr-FR' AND
        menu_items_translations.slug = category_id AND
        pois.source_id = sources.id AND
        pois.properties->>'id' = pois_slug_import.ref
      "
    )

    # Categories not linked to datasource
    local_poi = pois.select{ |poi| ['tis', 'zone'].include?(poi['properties']['metadata']['source']) }
    local_category_ids = local_poi.collect{ |poi| poi['properties']['metadata']['category_ids'] }.flatten.uniq
    categories_local = menu_items.select{ |menu| menu['category'] && local_category_ids.include?(menu['id']) }
    source_ids = load_local_pois(conn, project_slug, project_id, categories_local, local_poi, i18ns, role_uuid, url_base)

    source_ids.zip(categories_local).each{ |source_id, categorie|
      id = conn.exec(
        '
        INSERT INTO menu_items_sources(menu_items_id, sources_id)
        SELECT DISTINCT ON(menu_items.id)
          menu_items.id,
          $3
        FROM
          menu_items
          JOIN menu_items_translations ON
            menu_items_translations.menu_items_id = menu_items.id
        WHERE
          menu_items.theme_id = $1 AND
          menu_items_translations.slug = $2
        ORDER BY
          menu_items.id
        RETURNING
          id
        ',
        [theme_id, categorie['id'], source_id]
      ) { |result|
        result&.first
      }
      if id.nil?
        puts "[ERROR] Fails link _local_ source to menu_item: #{source_id}"
      end
    }

    # POI from datasource with local addon
    conn.exec("
      CREATE TEMP TABLE local_addon_raw(
        poi_id text,
        website_details text,
        image json
      )
    ")
    customs = 0
    enco = PG::BinaryEncoder::CopyRow.new
    conn.copy_data('COPY local_addon_raw FROM STDIN (FORMAT binary)', enco) {
      pois.each{ |poi|
        website_details = nil
        image = nil
        if poi.dig('properties', 'editorial', 'source:website:details') == 'local'
          website_details = poi['properties']['editorial']['website:details']
        end
        if poi.dig('properties', 'source:image') == 'local'
          image = poi['properties']['image']
        end
        if website_details || image
          conn.put_copy_data([poi['properties']['metadata']['id'].to_s, website_details, image.nil? ? nil : image.to_json])
          customs += 1
        end
      }
    }
    pois_custom_poi_ids = conn.exec_params("
      WITH a AS (
        SELECT
          pois.id AS poi_id,
          local_addon_raw.website_details,
          local_addon_raw.image
        FROM
          local_addon_raw
          JOIN pois ON
            (pois.slugs->>'original_id')::bigint = local_addon_raw.poi_id::bigint
          JOIN sources ON
            sources.id = pois.source_id AND
            sources.project_id = $1
      )
      MERGE INTO
        pois
      USING
        a AS local_addon_raw
      ON
        pois.id = local_addon_raw.poi_id
      WHEN MATCHED THEN
        UPDATE SET
          website_details = local_addon_raw.website_details,
          image = local_addon_raw.image::jsonb
      RETURNING
        pois.id
    ", [project_id]) { |result|
      result.collect{ |row| row['poi_id'] }
    }
    if pois_custom_poi_ids.size != customs
      puts "[ERROR] Fails to insert custom POI : #{customs} != #{pois_custom_poi_ids.size}"
    end
  }
end

def load_local_table(conn, source_name, name, table, fields, ps, i18ns, role_uuid)
  create_table = fields.collect(&:last).join(",\n")
  conn.exec('SET client_min_messages TO WARNING')
  conn.exec("DROP TABLE IF EXISTS \"t_#{table}\"")
  conn.exec("CREATE TEMP TABLE \"t_#{table}\" (#{create_table})".gsub(' bigint', 'text'))

  enco = PG::BinaryEncoder::CopyRow.new
  conn.copy_data("COPY \"t_#{table}\"(\"#{fields.collect(&:first).join('", "')}\") FROM STDIN (FORMAT binary)", enco) {
    ps.each{ |p|
      begin
        values = fields.collect{ |field, t, _, _|
          begin
            if ['id', "#{source_name}_id"[..62]].include?(field)
              p['properties']['metadata']['id']
            elsif field == 'geom'
              if p['geometry']['type'] == 'Feature'
                p['geometry'] = p['geometry']['geometry']
              end
              p['geometry'].to_json
            elsif field == 'languages_code'
              'fr-FR'
            else
              r = t.call(p['properties'][field], p['properties'])
              r = r.strip if r.is_a?(String)
              r
            end
          rescue StandardError => e
            puts p.inspect
            puts "ERROR: getting value for field \"#{field}\", #{e.message}"
            raise
          end
        }
        conn.put_copy_data(values)
      rescue StandardError
      end
    }
  }

  create_table = create_table
                 .gsub('id varchar', 'id SERIAL PRIMARY KEY')
                 .gsub("\"#{source_name}_id\" varchar", "\"#{source_name}_id\" SERIAL")
                 .gsub('geom json', 'geom geometry(Geometry,4326)')
                 .gsub(' json', ' jsonb')
  conn.exec("DROP TABLE IF EXISTS \"#{table}\"")
  conn.exec("CREATE TABLE \"#{table}\" (#{create_table})")
  conn.exec("
    INSERT INTO \"#{table}\"(\"#{fields.collect(&:first).join('", "')}\")
    SELECT
    " + fields.collect { |field, _, _, type|
      if ['id', "#{source_name}_id"[..62]].include?(field) || type.include?(' bigint')
        "\"#{field}\"::bigint"
      elsif field == 'geom'
        'ST_Force2D(ST_GeomFromGeoJSON(geom))'
      else
        "\"#{field}\""
      end
    }.join(', ') + "
    FROM
      \"t_#{table}\"
  ")
  conn.exec("SELECT setval('#{table[..55]}_id_seq', (SELECT max(id) FROM \"#{table}\")+1)")

  conn.exec('DELETE FROM directus_collections WHERE collection = $1', [table[..62]])
  conn.exec('
    INSERT INTO directus_collections(collection, translations, hidden, icon, "group") VALUES ($1, $2, $3, $4, $5)
    ON CONFLICT (collection)
    DO UPDATE SET
      translations = $2
  ', [
    table[..62],
    [{ language: 'fr-FR', translation: uncapitalize(name) }].to_json,
    table.end_with?('_t'),
    'pin_drop',
    'local_sources',
  ])
  conn.exec('DELETE FROM directus_fields WHERE collection = $1', [table[..62]])
  fields.each{ |key, _, interface, _|
    # TODO: It does not support other types of labels like label_details
    name = i18ns.dig(key, 'label', 'fr')

    conn.exec('
      INSERT INTO directus_fields(collection, field, translations, hidden, interface) VALUES ($1, $2, $3, $4, $5)
    ', [
      table[..62],
      key[..62],
      nil.nil? ? nil : [{ language: 'fr-FR', translation: uncapitalize(name) }].to_json,
      table.end_with?('_t') && ['id', "#{source_name}_id"[..62], 'languages_code'].include?(key),
      interface,
    ])
  }

  conn.exec('DELETE FROM directus_permissions WHERE collection = $1', [table[..62]])
  %w[create read update delete].each{ |action|
    conn.exec('
      INSERT INTO directus_permissions(role, collection, action, permissions, fields)
      VALUES ($1, $2, $3, $4, $5)
    ', [
      role_uuid,
      table[..62],
      action,
      {}.to_json,
      '*'
    ])
  }
end

def load_local_pois(conn, project_slug, project_id, categories_local, pois, i18ns, role_uuid, url_base)
  slugs = []
  categories_local.collect{ |category_local|
    name = category_local['category']['name']['fr']
    category_slug = ActiveSupport::Inflector.transliterate(name).slugify.gsub('-', '_').gsub(/_+/, '_')
    source_name = category_slug
    table = "local-#{project_slug}-#{source_name}"
    ps = pois.select{ |poi| poi['properties']['metadata']['category_ids'].include?(category_local['id']) }
    # puts [category_local['category']['name']['fr'], table, category_local['id'], ps.size].inspect

    if slugs.include?(source_name)
      puts "[ERROR] Duplicate local table slug: #{source_name} (#{name})"
      next
    else
      slugs << source_name
    end

    next if ps.empty?

    conn.exec('DELETE FROM sources WHERE project_id = $1 AND slug = $2', [project_id, source_name])
    source_id = conn.exec(
      '
      INSERT INTO sources(project_id, slug, attribution)
      VALUES ($1, $2, NULL)
      RETURNING id
      ', [
        project_id,
        source_name,
      ]
    ) { |result|
      result.first['id']
    }

    if source_id
      conn.exec(
        '
        INSERT INTO sources_translations(sources_id, languages_code, name)
        VALUES ($1, $2, $3)
        RETURNING id
        ', [
          source_id,
          'fr-FR',
          name,
        ]
      )
    end

    value_stats = ps.collect{ |p|
      website_details = p.dig('properties', 'editorial', 'website:details')
      if website_details && !website_details.start_with?(url_base)
        p['properties']['website:details'] = website_details
      end

      p['properties'].compact.except('metadata', 'display', 'editorial', 'classe', 'custom_details', 'sources', 'osm_galerie_images').collect{ |k, v|
        if v.is_a?(Array)
          [k, Array]
        elsif v.is_a?(Hash)
          [k, Hash]
        elsif v.is_a?(Integer) || v.to_i.to_s == v
          [k, Integer]
        elsif v.is_a?(String) && v.include?('</')
          [k, :html]
        else
          [k, v.is_a?(String) ? v.size <= 15 ? v : v.size >= 255 ? '...' : nil : v.presence]
        end
      }
    }.flatten(1).group_by(&:first).transform_values{ |key_values|
      key_values.collect(&:last).tally
    }.transform_values{ |stats|
      (stats.size != 1 || stats.to_a[0][0].is_a?(String)) && stats.size > ps.size / 10 ? { nil => stats.size } : stats
    }
    fields = []
    fields_translations = []
    value_stats.sort_by{ |_key, stats| -stats.values.sum }.each{ |key, stats|
      interface = nil
      i = if %w[name description].include?(key)
            f = ->(i, _j) { i }
            interface = 'input-rich-text-html' if stats&.keys&.include?(:html)
            "\"#{key}\" text"
          elsif ['addr:postcode', 'addr:housenumber', 'maxlength', 'ref', 'start_date', 'end_date', 'ref:fr:siret'].include?(key)
            f = ->(i, _j) { i }
            "\"#{key}\" varchar"
          elsif key == 'website:details'
            f = ->(_i, j) { j['editorial']['website:details'] }
            "\"#{key}\" varchar"
          elsif stats&.keys&.include?(Array) || stats&.keys&.include?(Hash)
            f = ->(i, _j) { i&.to_json }
            "\"#{key}\" json"
          elsif stats&.keys&.size == 1 && stats&.keys&.include?(Integer)
            f = ->(i, _j) { i&.to_i }
            "\"#{key}\" bigint"
          elsif stats&.keys&.include?(:html)
            f = ->(i, _j) { i }
            interface = 'input-rich-text-html'
            "\"#{key}\" text"
          elsif stats&.keys&.include?('...')
            f = ->(i, _j) { i }
            "\"#{key}\" text"
          else
            f = ->(i, _j) { i }
            "\"#{key}\" varchar"
          end
      if !stats.keys.include?(nil) && stats.keys.size == ps.size
        i += ' NOT NULL'
      end
      if %w[name description].include?(key)
        fields_translations << [key, f, interface, i]
      else
        fields << [key, f, interface, i]
      end
    }

    fields += [['id', nil, nil, 'id varchar'], ['geom', nil, nil, 'geom json NOT NULL']]
    load_local_table(conn, source_name, name, table, fields, ps, i18ns, role_uuid)

    if !fields_translations.empty?
      fields_translations += [['id', nil, nil, 'id varchar'], ["#{source_name}_id"[..62], nil, nil, "\"#{source_name}_id\" varchar NOT NULL"], ['languages_code', nil, nil, ' languages_code varchar(255)']]
      load_local_table(conn, source_name, name, "#{table}_t"[..62], fields_translations, ps, i18ns, role_uuid)
      conn.exec("ALTER TABLE \"#{table}_t\" ADD CONSTRAINT \"#{table}_t_fk\" FOREIGN KEY (\"#{source_name}_id\") REFERENCES \"#{table}_t\"(id);")
      conn.exec('DELETE FROM directus_relations WHERE many_collection = $1', ["#{table}_t"[..62]])
      conn.exec('
        INSERT INTO directus_fields(collection, field, special, interface, options, display) VALUES ($1, $2, $3, $4, $5, $6)
      ', [
        table[..62],
        "#{source_name}_translations"[..62],
        'translations',
        'translations',
        '{"languageField":"name","defaultLanguage":"en-US","defaultOpenSplitView":true,"userLanguage":true}',
        'translations',
      ])
      conn.exec('
        INSERT INTO directus_relations(many_collection, many_field, one_collection, one_field, junction_field, one_deselect_action) VALUES ($1, $2, $3, $4, $5, $6)
      ', [
        "#{table}_t"[..62],
        'languages_code',
        'languages',
        nil,
        "#{source_name}_id"[..62],
        'nullify',
      ])
      conn.exec('
        INSERT INTO directus_relations(many_collection, many_field, one_collection, one_field, junction_field, one_deselect_action) VALUES ($1, $2, $3, $4, $5, $6)
      ', [
        "#{table}_t"[..62],
        "#{source_name}_id"[..62],
        table[..62],
        "#{source_name}_translations"[..62],
        'languages_code',
        'nullify',
      ])
    end

    source_id
  }
end

namespace :wp do
  desc 'Import data from API'
  task :import, [] => :environment do
    set_default_languages

    url, project_slug, theme_slug, datasource_url, datasource_project = ARGV[2..]
    datasource_project ||= project_slug
    puts "\n====\n#{project_slug}\n====\n\n"
    base_url = "#{url}/#{project_slug}/#{theme_slug}"
    project_id, theme_id, url_base = load_settings(project_slug, theme_slug, "#{base_url}/settings.json", "#{base_url}/articles.json?slug=non-classe")

    role_uuid = create_role(project_slug)
    create_user(project_id, project_slug, role_uuid)

    loaded_from_datasource = load_from_source("#{datasource_url}/data", project_slug, datasource_project)
    i18ns = fetch_json("#{base_url}/attribute_translations/fr.json")
    load_menu(project_slug, project_id, theme_id, "#{base_url}/menu.json", "#{base_url}/pois.json", "#{base_url}/menu_sources.json", i18ns, role_uuid, url_base)
    i18ns = fetch_json("#{datasource_url}/data/#{project_slug}/i18n.json")

    load_i18n(project_slug, i18ns) if !loaded_from_datasource.empty?

    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
