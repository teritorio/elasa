# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'
require 'css_parser'
include CssParser

require_relative 'sources_load'


def fetch_json(url)
  response = HTTP.follow.get(url)
  raise "[ERROR] #{url} => #{response.status}" if !response.status.success?

  JSON.parse(response)
end

def new_project(slug, osm_id, theme, css, website)
  osm_tags = fetch_json("https://www.openstreetmap.org/api/0.6/relation/#{osm_id}.json").dig('elements', 0, 'tags')
  geojson = fetch_json("http://polygons.openstreetmap.fr/get_geojson.py?id=#{osm_id}&params=0.004000-0.001000-0.001000")

  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    project_id = conn.exec('
      INSERT INTO projects(icon_font_css_url, polygon, name, slug, articles, default_country, default_country_state_opening_hours, polygons_extra)
      VALUES (
        $1,
        ST_GeomFromGeoJSON($2),
        $3, $4, $5, $6, $7, $8
      )
      ON CONFLICT (slug)
      DO UPDATE SET
        icon_font_css_url = $1,
        polygon = ST_GeomFromGeoJSON($2),
        name = $3,
        articles = $5,
        default_country = $6,
        default_country_state_opening_hours = $7,
        polygons_extra = $8
      RETURNING id
    ', [
      css,
      geojson.to_json,
      { fr: osm_tags['name'] }.to_json,
      slug,
      [].to_json,
      'fr',
      'Nouvelle-Aquitaine',
      nil,
    ]) { |result|
      result.first['id'].to_i
    }

    theme_id = conn.exec('
      INSERT INTO themes(project_id, slug, name, description, logo_url, favicon_url, root_menu_item_id, site_url, main_url, keywords, favorites_mode, explorer_mode)
      VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
      )
      ON CONFLICT (project_id, slug)
      DO UPDATE SET
        name = $3,
        description = $4,
        logo_url = $5,
        favicon_url = $6,
        root_menu_item_id = $7,
        site_url = $8,
        main_url = $9,
        keywords = $10,
        favorites_mode = $11,
        explorer_mode = $12
      RETURNING
        id
    ', [
      project_id,
      theme,
      { fr: osm_tags['name'] }.to_json,
      { fr: osm_tags['name'] }.to_json,
      'https://www.teritorio.fr/wp-content/uploads/2022/10/favicon-194x194-1.png', # logo
      'https://www.teritorio.fr/wp-content/uploads/2022/10/favicon-194x194-1.png', # favico
      nil, # root menu
      { fr: website }.to_json,
      { fr: website }.to_json,
      nil, # keyword
      true, # favorite
      true # explorer
    ]) { |result|
      result.first['id'].to_i
    }

    [project_id, theme_id]
  }
end

def insert_menu_item(conn, **args)
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
     args[:theme_id],
     args[:slugs], args[:index_order], args[:hidden].nil? ? false : args[:hidden], args[:parent_id], args[:selected_by_default].nil? ? false : args[:selected_by_default],
     args[:type],
     args[:name], args[:name_singular], args[:icon], args[:color_fill], args[:color_line], args[:style_class_string], args[:display_mode],
     args[:search_indexed].nil? ? true : args[:search_indexed], args[:style_merge].nil? ? true : args[:style_merge], args[:zoom], args[:popup_fields_id], args[:details_fields_id], args[:list_fields_id],
     args[:href], args[:use_details_link].nil? ? true : args[:use_details_link],
    ]
  ) { |result|
    result.first['id']
  }
end

def insert_menu_group(conn, theme_id, parent_id, class_path, css_parser, classs, index)
  insert_menu_item(
    conn,
    theme_id: theme_id,
    slugs: { en: classs['label']['en']&.slugify, fr: classs['label']['fr']&.slugify }.compact.to_json,
    index_order: index,
    parent_id: parent_id,
    type: 'menu_group',
    ###### TODO recup trad fr
    name: { en: classs['label']['en']&.upcase_first, fr: classs['label']['fr']&.upcase_first || classs['label']['en']&.upcase_first }.compact.to_json,
    icon: 'teritorio teritorio-' + (css_parser.find_rule_sets([".teritorio-#{class_path[-1]}:before"]).first ? class_path[-1] : css_parser.find_rule_sets([".teritorio-#{class_path[-2]}:before"]).first ? class_path[-2] : class_path[-3]),
    color_fill: classs['color_fill'],
    color_line: classs['color_line'],
    style_class_string: class_path.join(','),
    display_mode: classs['display_mode'],
  )
end

def insert_menu_category(conn, project_id, theme_id, parent_id, class_path, css_parser, classs, index, group_fields_ids)
  group_ids = classs['osm_tags_extra'].collect{ |group|
    begin
      group_fields_ids[group].first
    rescue StandardError
      puts "Reference non existing group field #{group}"
      raise
    end
  }
  field_ids = classs['osm_tags_extra'].collect{ |group| group_fields_ids[group].last }.flatten

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

  category_id = insert_menu_item(
    conn,
    theme_id: theme_id,
    slugs: { en: classs['label']['en']&.slugify, fr: classs['label']['fr']&.slugify }.compact.to_json,
    index_order: index,
    parent_id: parent_id,
    type: 'category',
    ###### TODO recup trad fr
    name: { en: classs['label']['en']&.upcase_first, fr: classs['label']['fr']&.upcase_first || classs['label']['en']&.upcase_first }.compact.to_json,
    icon: 'teritorio teritorio-' + (css_parser.find_rule_sets([".teritorio-#{class_path[-1]}:before"]).first ? class_path[-1] : css_parser.find_rule_sets([".teritorio-#{class_path[-2]}:before"]).first ? class_path[-2] : class_path[-3]),
    color_fill: classs['color_fill'],
    color_line: classs['color_line'],
    style_class_string: class_path.join(','),
    display_mode: classs['display_mode'],
    zoom: classs['zoom'],
    popup_fields_id: popup_fields_id,
    details_fields_id: details_fields_id,
    list_fields_id: popup_fields_id,
  )

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

    field_ids = fields.each_with_index.collect{ |field, index|
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

      field_id
    }

    [group_id, [group_field_id, field_ids]]
  }
end

def new_menu(project_id, theme_id, theme, css)
  ontology = fetch_json("https://vecto.teritorio.xyz/data/teritorio-#{theme}-ontology-latest.json")

  css_parser = CssParser::Parser.new
  css_parser.load_uri!(css)

  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    conn.exec('DELETE FROM menu_items WHERE theme_id = $1', [theme_id])
    conn.exec('DELETE FROM filters WHERE project_id = $1', [project_id])
    conn.exec('DELETE FROM fields WHERE project_id = $1', [project_id])

    root_menu_id = insert_menu_item(
      conn,
      theme_id: theme_id,
      slugs: { en: 'root', fr: 'racine', es: 'raiz' }.to_json,
      index_order: 1,
      type: 'menu_group',
      name: { en: 'Root Menu', fr: 'Menu racine', es: 'Menú raíz' }.compact.to_json,
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
      slugs: { en: 'search', fr: 'search', es: 'búsqueda' }.to_json,
      parent_id: root_menu_id,
      index_order: 1,
      type: 'menu_group',
      name: { en: 'Search', fr: 'Recherche', es: 'Búsqueda' }.compact.to_json,
      display_mode: 'compact',

      icon: 'teritorio teritorio-services',
      color_fill:	'#ff0000',
      color_line:	'#ff0000',
    )

    poi_menu_id = insert_menu_item(
      conn,
      theme_id: theme_id,
      slugs: { en: 'pois', fr: 'poi', es: 'poi' }.to_json,
      parent_id: root_menu_id,
      index_order: 2,
      type: 'menu_group',
      name: { en: 'POIs', fr: 'POI', es: 'PDI' }.compact.to_json,
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
            insert_menu_category(conn, project_id, theme_id, class_menu_id, [superclass_id, class_id, subclass_id], css_parser, subclass, subclass_index, group_fields_ids)
          }
        else
          insert_menu_category(conn, project_id, theme_id, superclass_menu_id, [superclass_id, class_id], css_parser, classs, class_index, group_fields_ids)
        end
      }
    }
  }
end


namespace :project do
  desc 'Create a new project'
  task :new, [] => :environment do
    slug, osm_id, theme, website = ARGV[2..]
    datasource_url = 'https://datasources.teritorio.xyz/0.1'

    css = 'https://gpv-rive-droite.appcarto.teritorio.xyz/content/wp-content/plugins/font-teritorio/dist/teritorio.css?ver=2.7.0'
    project_id, theme_id = new_project(slug, osm_id, theme, css, website)
    load_from_source("#{datasource_url}/data", slug, slug)
    load_i18n(project_id, "#{datasource_url}/data/#{slug}/i18n.json")
    new_menu(project_id, theme_id, theme, css)

    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
