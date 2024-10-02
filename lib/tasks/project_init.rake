# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'
require 'css_parser'

require_relative 'sources_load'


LANGS = {
  'fr' => 'fr-FR',
  'en' => 'en-US',
  'es' => 'es-ES',
}

def new_project(slug, osm_id, theme, css, website)
  osm_tags = fetch_json("https://www.openstreetmap.org/api/0.6/relation/#{osm_id}.json").dig('elements', 0, 'tags')
  geojson = fetch_json("http://polygons.openstreetmap.fr/get_geojson.py?id=#{osm_id}&params=0.004000-0.001000-0.001000")

  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    conn.exec('
      INSERT INTO languages(code, name, direction)
      VALUES ($1, $2, $3), ($4, $5, $6), ($7, $8, $9)
      ON CONFLICT DO NOTHING
    ', %w[
      fr-FR French ltr
      en-US English ltr
      es-ES Spanish ltr
    ])

    project_id = conn.exec('
      INSERT INTO projects(icon_font_css_url, polygon, slug, articles, default_country, default_country_state_opening_hours, polygons_extra)
      VALUES (
        $1,
        ST_GeomFromGeoJSON($2),
        $3, $4, $5, $6, $7
      )
      ON CONFLICT (slug)
      DO UPDATE SET
        icon_font_css_url = $1,
        polygon = ST_GeomFromGeoJSON($2),
        articles = $4,
        default_country = $5,
        default_country_state_opening_hours = $6,
        polygons_extra = $7
      RETURNING id
    ', [
      css,
      geojson.to_json,
      slug,
      [].to_json,
      'fr',
      'Nouvelle-Aquitaine',
      nil,
    ]) { |result|
      result.first['id'].to_i
    }

    conn.exec('
      INSERT INTO projects_translations(projects_id, languages_code, name)
      VALUES (
        $1,
        $2,
        $3
      )
      ON CONFLICT (projects_id, languages_code)
      DO UPDATE SET
        name = $2
    ', [
      project_id,
      'fr-FR',
      osm_tags['name'],
    ])

    theme_id = conn.exec('
      INSERT INTO themes(project_id, slug, logo_url, favicon_url, root_menu_item_id, favorites_mode, explorer_mode)
      VALUES (
        $1, $2, $3, $4, $5, $6, $7
      )
      ON CONFLICT (project_id, slug)
      DO UPDATE SET
        logo_url = $3,
        favicon_url = $4,
        root_menu_item_id = $5,
        favorites_mode = $6,
        explorer_mode = $7
      RETURNING
        id
    ', [
      project_id,
      theme,
      'https://www.teritorio.fr/wp-content/uploads/2022/10/favicon-194x194-1.png', # logo
      'https://www.teritorio.fr/wp-content/uploads/2022/10/favicon-194x194-1.png', # favico
      nil, # root menu
      true, # favorite
      true # explorer
    ]) { |result|
      result.first['id'].to_i
    }

    conn.exec('
      INSERT INTO themes_translations(themes_id, languages_code, name, description, site_url, main_url, keywords)
      VALUES (
        $1, $2, $3, $4, $5, $6, $7
      )
      ON CONFLICT (themes_id, languages_code)
      DO UPDATE SET
        name = $3,
        description = $4,
        site_url = $5,
        main_url = $6,
        keywords = $7
    ', [
      theme_id,
      'fr-FR',
      osm_tags['name'],
      osm_tags['name'],
      website,
      website,
      nil, # keyword
    ])

    [project_id, theme_id]
  }
end

def insert_menu_item(conn, **args)
  menu_item_id = conn.exec(
    '
    INSERT INTO menu_items(
      theme_id,
      index_order, hidden, parent_id, selected_by_default,
      type,
      icon, color_fill, color_line, style_class_string, display_mode,
      search_indexed, style_merge, zoom, popup_fields_id, details_fields_id, list_fields_id,
      href, use_details_link
    )
    VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19
    )
    RETURNING
      id
    ', [
      args[:theme_id],
      args[:index_order], args[:hidden].nil? ? false : args[:hidden], args[:parent_id], args[:selected_by_default].nil? ? false : args[:selected_by_default],
      args[:type],
      args[:icon], args[:color_fill], args[:color_line], args[:style_class_string], args[:display_mode],
      args[:search_indexed].nil? ? true : args[:search_indexed], args[:style_merge].nil? ? true : args[:style_merge], args[:zoom], args[:popup_fields_id], args[:details_fields_id], args[:list_fields_id],
      args[:href], args[:use_details_link].nil? ? true : args[:use_details_link],
    ]
  ) { |result|
    result.first['id']
  }

  [args[:slugs]&.keys, args[:name]&.keys, args[:name_singular]&.keys].compact.flatten.uniq.each{ |lang|
    conn.exec(
      '
      INSERT INTO menu_items_translations(menu_items_id, languages_code, slug, name, name_singular)
      VALUES ($1, $2, $3, $4, $5)
      ', [
        menu_item_id,
        LANGS[lang.to_s],
        args.dig(:slugs, lang),
        args.dig(:name, lang),
        args.dig(:name_singular, lang),
      ]
    )
  }
  menu_item_id
end

def insert_menu_group(conn, theme_id, parent_id, class_path, css_parser, classs, index)
  icon = css_parser.find_rule_sets([".teritorio-#{class_path[-1]}:before"]).first ? class_path[-1] : css_parser.find_rule_sets([".teritorio-#{class_path[-2]}:before"]).first ? class_path[-2] : class_path[-3]
  insert_menu_item(
    conn,
    theme_id: theme_id,
    slugs: { en: classs['label']['en']&.slugify, fr: classs['label']['fr']&.slugify }.compact,
    index_order: index,
    parent_id: parent_id,
    type: 'menu_group',
    ###### TODO recup trad fr
    name: { en: classs['label']['en']&.upcase_first, fr: classs['label']['fr']&.upcase_first || classs['label']['en']&.upcase_first }.compact,
    icon: "teritorio teritorio-#{icon}",
    color_fill: classs['color_fill'],
    color_line: classs['color_line'],
    style_class_string: class_path.join(','),
    display_mode: classs['display_mode'],
  )
end

def insert_menu_category(conn, project_id, theme_id, parent_id, class_path, css_parser, classs, index, group_fields_ids, filters)
  group_ids = classs['osm_tags_extra'].collect{ |group|
    next if group.include?('i18n')

    begin
      group_fields_ids[group].first
    rescue StandardError
      puts "Reference non existing group field #{group}"
      raise
    end
  }.compact
  fields = classs['osm_tags_extra'].collect{ |group| group_fields_ids[group].last.keys }.compact.flatten
  field_ids = classs['osm_tags_extra'].collect{ |group| group_fields_ids[group].last.values }.compact.flatten

  popup_fields_id = conn.exec(
    'INSERT INTO fields(project_id, type, "group", display_mode) VALUES ($1, $2, $3, $4) RETURNING id',
    [project_id, 'group', 'group_popup', 'standard']
  ) { |result| result.first['id'].to_i }
  field_ids.each_with_index{ |field_id, field_index|
    conn.exec(
      'INSERT INTO fields_fields(fields_id, related_fields_id, index) VALUES ($1, $2, $3) RETURNING id',
      [popup_fields_id, field_id, field_index]
    )
  }

  # Details
  details_fields_id = conn.exec(
    'INSERT INTO fields(project_id, type, "group", display_mode) VALUES ($1, $2, $3, $4) RETURNING id',
    [project_id, 'group', 'group_details', 'standard']
  ) { |result| result.first['id'].to_i }
  group_ids.each_with_index{ |group_id, group_index|
    conn.exec(
      'INSERT INTO fields_fields(fields_id, related_fields_id, index) VALUES ($1, $2, $3) RETURNING id',
      [details_fields_id, group_id, group_index]
    )
  }

  icon = (css_parser.find_rule_sets([".teritorio-#{class_path[-1]}:before"]).first ? class_path[-1] : css_parser.find_rule_sets([".teritorio-#{class_path[-2]}:before"]).first ? class_path[-2] : class_path[-3])
  category_id = insert_menu_item(
    conn,
    theme_id: theme_id,
    slugs: { en: classs['label']['en']&.slugify, fr: classs['label']['fr']&.slugify }.compact,
    index_order: index,
    parent_id: parent_id,
    type: 'category',
    ###### TODO recup trad fr
    name: { en: classs['label']['en']&.upcase_first, fr: classs['label']['fr']&.upcase_first || classs['label']['en']&.upcase_first }.compact,
    icon: "teritorio teritorio-#{icon}",
    color_fill: classs['color_fill'],
    color_line: classs['color_line'],
    style_class_string: class_path.join(','),
    display_mode: classs['display_mode'],
    zoom: classs['zoom'],
    popup_fields_id: popup_fields_id,
    details_fields_id: details_fields_id,
    list_fields_id: popup_fields_id,
  )

  fields.each{ |field|
    filter_id = filters[field]
    if filter_id
      conn.exec(
        'INSERT INTO menu_items_filters(menu_items_id, filters_id) VALUES ($1, $2) RETURNING id',
        [category_id, filter_id]
      )
    end
  }

  source_slug = class_path.join('-')
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
  return unless id.nil?

  puts "[ERROR] Fails link source to menu_item: (#{source_slug})"
end

def insert_group_fields(conn, project_id, ontology)
  osm_tags_extra = ontology['osm_tags_extra']
  osm_tags_extra.to_h{ |group_id, fields|
    group_field_id = conn.exec(
      'INSERT INTO fields(project_id, type, "group", display_mode) VALUES ($1, $2, $3, $4) RETURNING id',
      [project_id, 'group', group_id, 'standard']
    ) { |result|
      result.first['id'].to_i
    }

    field_ids = fields.each_with_index.to_h{ |field, index|
      field = field[0]
      field_id = conn.exec(
        'INSERT INTO fields(project_id, type, field) VALUES ($1, $2, $3) RETURNING id',
        [project_id, 'field', field]
      ) { |result|
        result.first['id'].to_i
      }

      conn.exec(
        'INSERT INTO fields_fields(fields_id, related_fields_id, index) VALUES ($1, $2, $3) RETURNING id',
        [group_field_id, field_id, index]
      )

      [field, field_id]
    }

    [group_id, [group_field_id, field_ids]]
  }
end

def new_menu(project_id, theme_id, theme, css, filters)
  ontology = fetch_json("https://raw.githubusercontent.com/teritorio/ontology-builder/gh-pages/teritorio-#{theme}-ontology-1.0.json")

  css_parser = CssParser::Parser.new
  css_parser.load_uri!(css)

  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    conn.exec('DELETE FROM menu_items WHERE theme_id = $1', [theme_id])
    conn.exec('DELETE FROM fields WHERE project_id = $1', [project_id])

    root_menu_id = insert_menu_item(
      conn,
      theme_id: theme_id,
      slugs: { en: 'root', fr: 'racine', es: 'raiz' },
      index_order: 1,
      type: 'menu_group',
      name: { en: 'Root Menu', fr: 'Menu racine', es: 'Menú raíz' }.compact,
      display_mode: 'compact',
    )

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
      [project_id, theme_id, root_menu_id]
    )

    insert_menu_item(
      conn,
      theme_id: theme_id,
      slugs: { en: 'search', fr: 'search', es: 'búsqueda' },
      parent_id: root_menu_id,
      index_order: 1,
      type: 'menu_group',
      name: { en: 'Search', fr: 'Recherche', es: 'Búsqueda' }.compact,
      display_mode: 'compact',

      icon: 'teritorio teritorio-services',
      color_fill:	'#ff0000',
      color_line:	'#ff0000',
    )

    poi_menu_id = insert_menu_item(
      conn,
      theme_id: theme_id,
      slugs: { en: 'pois', fr: 'poi', es: 'poi' },
      parent_id: root_menu_id,
      index_order: 2,
      type: 'menu_group',
      name: { en: 'POIs', fr: 'POI', es: 'PDI' }.compact,
      display_mode: 'compact',

      icon: 'teritorio teritorio-services',
      color_fill:	'#ff0000',
      color_line:	'#ff0000',
    )

    group_fields_ids = insert_group_fields(conn, project_id, ontology)

    ontology['superclass'].each_with_index{ |id_superclass, superclass_index|
      superclass_id, superclass = id_superclass
      superclass['display_mode'] = 'compact'
      superclass_menu_id = insert_menu_group(conn, theme_id, poi_menu_id, [superclass_id], css_parser, superclass, superclass_index)
      superclass['class'].each_with_index{ |id_class, class_index|
        class_id, classs = id_class
        classs['color_fill'] = superclass['color_fill']
        classs['color_line'] = superclass['color_line']
        classs['display_mode'] = 'large'
        if classs.key?('subclass')
          class_menu_id = insert_menu_group(conn, theme_id, superclass_menu_id, [superclass_id, class_id], css_parser, classs, class_index)
          classs['subclass'].each_with_index{ |id_subclass, subclass_index|
            subclass_id, subclass = id_subclass
            subclass['color_fill'] = superclass['color_fill']
            subclass['color_line'] = superclass['color_line']
            subclass['display_mode'] = 'large'
            insert_menu_category(conn, project_id, theme_id, class_menu_id, [superclass_id, class_id, subclass_id], css_parser, subclass, subclass_index, group_fields_ids, filters)
          }
        else
          insert_menu_category(conn, project_id, theme_id, superclass_menu_id, [superclass_id, class_id], css_parser, classs, class_index, group_fields_ids, filters)
        end
      }
    }
  }
end

def new_filter(project_id, schema_url, i18ns)
  schema = fetch_json(schema_url)
  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    conn.exec('DELETE FROM filters WHERE project_id = $1', [project_id])

    schema['properties'].transform_values{ |spec|
      if spec['type'] == 'array'
        spec['items']['enum']
      else
        spec['enum']
      end
    }.compact.except('tactile_paving', 'pastry', 'mobile_phone:repair', 'computer:repair', 'sport', 'access', 'dispensing').collect{ |key, enum|
      name = i18ns.dig(key, '@default') || {}
      filter_id = (
        if [%w[yes no], %w[no yes]].include?(enum)
          conn.exec(
            'INSERT INTO filters(project_id, type, boolean_property) VALUES ($1, $2, $3) RETURNING id',
            [project_id, 'boolean', key]
          ) { |result| result.first['id'].to_i }
        elsif enum.size <= 1
          next
        elsif enum.size <= 5
          conn.exec(
            'INSERT INTO filters(project_id, type, checkboxes_list_property) VALUES ($1, $2, $3) RETURNING id',
            [project_id, 'checkboxes_list', key]
          ) { |result| result.first['id'].to_i }
        else
          conn.exec(
            'INSERT INTO filters(project_id, type, multiselection_property) VALUES ($1, $2, $3) RETURNING id',
            [project_id, 'multiselection', key]
          ) { |result| result.first['id'].to_i }
        end
      )
      name.keys.each{ |lang|
        conn.exec(
          'INSERT INTO filters_translations(filters_id, languages_code, name) VALUES ($1, $2, $3)',
          [filter_id, LANGS[lang], name[lang]]
        )
      }
      [key, filter_id]
    }.compact.to_h
  }
end

namespace :project do
  desc 'Create a new project'
  task :new, [] => :environment do
    slug, osm_id, theme, website = ARGV[2..]
    datasource_url = 'https://datasources.teritorio.xyz/0.1'

    css = 'https://carte.seignanx.com/content/wp-content/plugins/font-teritorio/dist/teritorio.css?ver=2.8.0'
    project_id, theme_id = new_project(slug, osm_id, theme, css, website)
    load_from_source("#{datasource_url}/data", slug, slug)
    i18ns = fetch_json("#{datasource_url}/data/#{slug}/i18n.json")
    load_i18n(slug, i18ns)
    filters = new_filter(project_id, "#{datasource_url}/data/#{slug}/schema.json", i18ns)
    new_menu(project_id, theme_id, theme, css, filters)

    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
