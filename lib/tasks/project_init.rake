# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'
require 'css_parser'

require_relative 'commons'
require_relative 'sources_load'


def new_project(conn, slug, datasources_slug, osm_id, theme, css, website, map_apikey)
  if !osm_id.nil?
    osm_tags = fetch_json("https://www.openstreetmap.org/api/0.6/relation/#{osm_id}.json").dig('elements', 0, 'tags')
    osm_name = osm_tags['name']
    geojson = fetch_json("http://polygons.openstreetmap.fr/get_geojson.py?id=#{osm_id}&params=0.004000-0.001000-0.001000")
  end

  project_id = conn.exec('
    INSERT INTO projects(icon_font_css_url, polygon, bbox_line, slug, datasources_slug, default_country, default_country_state_opening_hours, polygons_extra)
    VALUES (
      $1,
      ST_Force2D(ST_GeomFromGeoJSON($2)),
      st_makeline(st_makepoint(st_xmin(ST_GeomFromGeoJSON($2)), st_ymin(ST_GeomFromGeoJSON($2))), st_makepoint(st_xmax(ST_GeomFromGeoJSON($2)), st_ymax(ST_GeomFromGeoJSON($2)))),
      $3, $4, $5, $6, $7
    )
    ON CONFLICT (slug)
    DO UPDATE SET
      icon_font_css_url = $1,
      polygon = ST_Force2D(ST_GeomFromGeoJSON($2)),
      bbox_line = st_makeline(st_makepoint(st_xmin(ST_GeomFromGeoJSON($2)), st_ymin(ST_GeomFromGeoJSON($2))), st_makepoint(st_xmax(ST_GeomFromGeoJSON($2)), st_ymax(ST_GeomFromGeoJSON($2)))),
      datasources_slug = $4,
      default_country = $5,
      default_country_state_opening_hours = $6,
      polygons_extra = $7
    RETURNING id
  ', [
    css,
    geojson&.to_json,
    slug,
    datasources_slug,
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
      name = $3
  ', [
    project_id,
    'fr-FR',
    osm_name,
  ])

  theme_id = conn.exec('
    INSERT INTO themes(project_id, slug, logo, favicon, root_menu_item_id, favorites_mode, explorer_mode, map_style_base_url, map_style_satellite_url, map_bicycle_style_url)
    VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10
    )
    ON CONFLICT (project_id, slug)
    DO UPDATE SET
      logo = $3,
      favicon = $4,
      root_menu_item_id = $5,
      favorites_mode = $6,
      explorer_mode = $7,
      map_style_base_url = $8,
      map_style_satellite_url = $9,
      map_bicycle_style_url = $10
    RETURNING
      id
  ', [
    project_id,
    theme,
    nil, # logo
    nil, # favicon
    nil, # root menu
    true, # favorite
    true, # explorer
    "https://merge-proxy.teritorio.xyz/styles/teritorio-city-1.0/style.json?key=#{map_apikey}",
    "https://merge-proxy.teritorio.xyz/styles/satellite-hybrid/style.json?key=#{map_apikey}",
    "https://merge-proxy.teritorio.xyz/styles/teritorio-bicycle-city/style.json?key=#{map_apikey}",
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
    osm_name,
    osm_name,
    website,
    website,
    nil, # keyword
  ])

  [project_id, theme_id]
end

def insert_menu_item(conn, **args)
  menu_item_id = conn.exec(
    '
    INSERT INTO menu_items(
      project_id,
      index_order, hidden, parent_id, selected_by_default,
      type,
      icon, color_fill, color_line, style_class, display_mode,
      search_indexed, style_merge, zoom, popup_fields_id, details_fields_id, list_fields_id,
      href, use_internal_details_link, use_external_details_link
    )
    VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20
    )
    RETURNING
      id
    ', [
      args[:project_id],
      args[:index_order], args[:hidden].nil? ? false : args[:hidden], args[:parent_id], args[:selected_by_default].nil? ? false : args[:selected_by_default],
      args[:type],
      args[:icon], args[:color_fill], args[:color_line], args[:style_class], args[:display_mode],
      args[:search_indexed].nil? || args[:search_indexed], args[:style_merge].nil? || args[:style_merge], args[:zoom], args[:popup_fields_id], args[:details_fields_id], args[:list_fields_id],
      args[:href],
      args[:use_internal_details_link].nil? || args[:use_internal_details_link],
      args[:use_external_details_link].nil? || args[:use_external_details_link],
    ]
  ) { |result|
    result.first['id']
  }

  [args[:slugs]&.keys, args[:name]&.keys, args[:name_singular]&.keys].compact.flatten.uniq.each{ |lang|
    conn.exec(
      '
      INSERT INTO menu_items_translations(menu_items_id, languages_code, slug, name, name_singular)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (menu_items_id, languages_code)
      DO UPDATE SET
        slug = $3,
        name = $4,
        name_singular = $5
      ', [
        menu_item_id,
        lang.to_s,
        args.dig(:slugs, lang),
        args.dig(:name, lang),
        args.dig(:name_singular, lang),
      ]
    )
  }
  menu_item_id
end

def find_icon(css_parser, icons)
  return if icons.nil?

  icons.compact.reverse.find{ |icon| css_parser.find_rule_sets([".teritorio-#{icon}:before"]).first }
end

def insert_menu_group(conn, project_id, parent_id, class_path, icons, css_parser, classs, index)
  icon = find_icon(css_parser, icons)
  insert_menu_item(
    conn,
    project_id: project_id,
    slugs: { 'en-US' => classs['label']['en-US']&.slugify, 'fr-FR' => classs['label']['fr-FR']&.slugify }.compact,
    index_order: index,
    parent_id: parent_id,
    type: 'menu_group',
    ###### TODO recup trad fr
    name: { 'en-US' => classs['label']['en-US']&.upcase_first, 'fr-FR' => classs['label']['fr-FR']&.upcase_first || classs['label']['en-US']&.upcase_first }.compact,
    icon: "teritorio teritorio-#{icon}",
    color_fill: classs['color_fill'],
    color_line: classs['color_line'],
    style_class: class_path,
    display_mode: classs['display_mode'],
  )
end

def insert_fields_group(conn, project_id, slug, fields, group_fields_ids, fields_ids, filters)
  fields_id = conn.exec(
    '
    INSERT INTO
      fields(project_id, type, "group", display_mode)
    VALUES
      ($1, $2, $3, $4)
    ON CONFLICT (project_id, "group", field)
    DO UPDATE SET
      display_mode = EXCLUDED.display_mode
    RETURNING id
    ', [project_id, 'group', "group_#{slug}_default", 'standard']
  ) { |result| result.first['id'].to_i }
  fields.each_with_index{ |field, field_index|
    field_id = fields_ids[field]
    if field_id.nil?
      puts "[WARNING] No field id for #{field}"
      next
    end

    conn.exec(
      '
      INSERT INTO
        fields_fields(fields_id, related_fields_id, index)
      VALUES
        ($1, $2, $3)
      ON CONFLICT (fields_id, related_fields_id)
      DO NOTHING
      RETURNING id
      ', [fields_id, field_id, field_index]
    )
  }

  fields_id
end

def insert_fields_groups(conn, project_id, group_fields_ids, fields_ids, filters)
  popup_fields_id = insert_fields_group(conn, project_id, 'popup', %w[opening_hours phone website addr], group_fields_ids, fields_ids, filters)
  list_fields_id = insert_fields_group(conn, project_id, 'list', %w[name opening_hours phone website addr], group_fields_ids, fields_ids, filters)

  # Details
  details_fields_id = conn.exec(
    '
    INSERT INTO
      fields(project_id, type, "group", display_mode)
    VALUES
      ($1, $2, $3, $4)
    ON CONFLICT (project_id, "group", field)
    DO UPDATE SET
      display_mode = EXCLUDED.display_mode
    RETURNING id
    ', [project_id, 'group', 'group_details_default', 'standard']
  ) { |result| result.first['id'].to_i }
  [
    group_fields_ids['contact']&.first,
    fields_ids['description'],
    group_fields_ids['opening']&.first,
    group_fields_ids['location']&.first,
  ].compact.each_with_index{ |id, index|
    conn.exec(
      '
      INSERT INTO
        fields_fields(fields_id, related_fields_id, index)
      VALUES
        ($1, $2, $3)
      ON CONFLICT (fields_id, related_fields_id)
      DO NOTHING
      RETURNING id
      ', [details_fields_id, id, index]
    )
  }

  [popup_fields_id, details_fields_id, list_fields_id]
end

def insert_menu_category(conn, project_id, parent_id, class_path, icons, source_slug, css_parser, classs, index, popup_fields_id, details_fields_id, list_fields_id)
  slug = classs['label']&.to_h{ |lang, value| [lang.to_sym, value.slugify] }
  conn.exec("SAVEPOINT \"#{source_slug}\"")

  icon = find_icon(css_parser, icons)
  category_id = insert_menu_item(
    conn,
    project_id: project_id,
    slugs: slug,
    index_order: index,
    parent_id: parent_id,
    type: 'category',
    ###### TODO recup trad fr
    name: { 'en-US' => classs['label']['en-US']&.upcase_first, 'fr-FR' => classs['label']['fr-FR']&.upcase_first || classs['label']['en-US']&.upcase_first }.compact,
    icon: "teritorio teritorio-#{icon}",
    color_fill: classs['color_fill'],
    color_line: classs['color_line'],
    style_class: class_path,
    display_mode: classs['display_mode'],
    zoom: classs['zoom'],
    popup_fields_id: popup_fields_id,
    details_fields_id: details_fields_id,
    list_fields_id: list_fields_id,
  )

  # Disable, to much work to remove filters everywhere
  # fields.each{ |field|
  #   filter_id = filters[field]
  #   if filter_id
  #     conn.exec(
  #       'INSERT INTO menu_items_filters(menu_items_id, filters_id) VALUES ($1, $2) RETURNING id',
  #       [category_id, filter_id]
  #     )
  #   end
  # }

  id = conn.exec(
    '
      WITH
      sources AS ( -- Filter on sources with POIs
        SELECT DISTINCT ON (sources.id)
          sources.id,
          sources.project_id,
          sources.slug
        FROM
          sources
          JOIN pois ON
            pois.source_id = sources.id
        ORDER BY
          sources.id
      )
      INSERT INTO menu_items_sources(menu_items_id, sources_id)
      SELECT
        $2,
        sources.id
      FROM
        sources
        LEFT JOIN menu_items_sources ON
          menu_items_sources.sources_id = sources.id
      WHERE
        menu_items_sources.sources_id IS NULL AND -- Only insert if not already linked
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
    conn.exec("ROLLBACK TO SAVEPOINT \"#{source_slug}\"")
    puts "[WARNING] Source already linked to menu_item or empty: (#{source_slug})"
    false
  else
    true
  end
end

def insert_group_fields(conn, project_id, ontology)
  properties_extra = ontology['properties_extra'] || {}
  properties_extra['location'] = {
    'addr' => {
      'label' => { 'fr-FR' => 'Adresse', 'en-US' => 'Address' },
    },
    'coordinates' => {
      'label' => { 'fr-FR' => 'Coordonnées', 'en-US' => 'Coordinates' },
    },
  }
  fields_ids = {}
  group_fields_ids = properties_extra.to_h{ |group_id, fields|
    group_field_id = conn.exec(
      '
      INSERT INTO
        fields(project_id, type, "group", display_mode)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (project_id, "group", field)
      DO UPDATE SET
        display_mode = EXCLUDED.display_mode
      RETURNING id
      ', [project_id, 'group', group_id, 'standard']
    ) { |result|
      result.first['id'].to_i
    }

    field_ids = fields.each_with_index.to_h{ |field, index|
      field = field[0]
      field_id = conn.exec(
        'INSERT INTO fields(project_id, type, field)
        VALUES ($1, $2, $3)
        ON CONFLICT (project_id, "group", field)
        DO UPDATE SET
          field = EXCLUDED.field -- Do nothing, but helps to return the id
        RETURNING id',
        [project_id, 'field', field]
      ) { |result|
        result.first['id'].to_i
      }

      conn.exec(
        '
        INSERT INTO
          fields_fields(fields_id, related_fields_id, index)
        VALUES
          ($1, $2, $3)
        ON CONFLICT (fields_id, related_fields_id)
        DO NOTHING
        RETURNING id
        ', [group_field_id, field_id, index]
      )

      [field, field_id]
    }
    fields_ids = fields_ids.merge(field_ids)

    [group_id, [group_field_id, field_ids]]
  }

  [group_fields_ids, fields_ids]
end

def new_root_menu(conn, project_id)
  conn.exec('DELETE FROM menu_items WHERE project_id = $1', [project_id])
  conn.exec('DELETE FROM fields_fields USING fields WHERE fields.project_id = $1 AND fields_fields.fields_id = fields.id', [project_id])
  conn.exec('DELETE FROM fields WHERE project_id = $1 AND type = \'group\'', [project_id])

  root_menu_id = insert_menu_item(
    conn,
    project_id: project_id,
    slugs: { 'en-US' => 'root', 'fr-FR' => 'racine', 'es-ES' => 'raiz' },
    index_order: 1,
    type: 'menu_group',
    name: { 'en-US' => 'Root Menu', 'fr-FR' => 'Menu racine', 'es-ES' => 'Menú raíz' }.compact,
    display_mode: 'compact',
    icon: 'teritorio teritorio-extra-point',
    color_fill:	'#ff0000',
    color_line:	'#ff0000',
  )

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
  [project_id, project_id, root_menu_id]
)

  insert_menu_item(
    conn,
    project_id: project_id,
    slugs: { 'en-US' => 'search', 'fr-FR' => 'search', 'es-ES' => 'búsqueda' },
    parent_id: root_menu_id,
    index_order: 1,
    type: 'search',
    name: { 'en-US' => 'Search', 'fr-FR' => 'Recherche', 'es-ES' => 'Búsqueda' }.compact,
    display_mode: 'compact',

    icon: 'teritorio teritorio-extra-point',
    color_fill:	'#ff0000',
    color_line:	'#ff0000',
  )

  root_menu_id
end

def new_ontologies_menu(con, project_id, root_menu_id, themes, css, filters)
  themes.each{ |theme|
    new_ontology_menu(con, project_id, root_menu_id, theme, css, filters)
  }
end

def new_ontology_menu(con, project_id, root_menu_id, theme, css, filters)
  return if !theme.present?

  ontology =
    if theme == 'bpe'
      fetch_json('https://datasources.teritorio.xyz/0.1/config/insee_bpe-ontology-2023.json')
    elsif theme == 'datatourisme'
      fetch_json('https://datasources.teritorio.xyz/0.1/config/datatourism-ontology.json')
    elsif %w[tourism city].include?(theme)
      fetch_json("https://raw.githubusercontent.com/teritorio/ontology-builder/gh-pages/teritorio-#{theme}-ontology-2.0.json")
    end

  css_parser = CssParser::Parser.new
  css_parser.load_uri!("public/#{css}")

  con.transaction { |conn|
    poi_menu_id = insert_menu_item(
      conn,
      project_id: project_id,
      slugs: { 'en-US' => "pois #{theme}", 'fr-FR' => "poi #{theme}", 'es-ES' => "poi #{theme}" },
      parent_id: root_menu_id,
      index_order: 2,
      type: 'menu_group',
      name: { 'en-US' => "POIs #{theme}", 'fr-FR' => "POI #{theme}", 'es-ES' => "PDI #{theme}" }.compact,
      display_mode: 'compact',

      icon: 'teritorio teritorio-extra-point',
      color_fill:	'#ff0000',
      color_line:	'#ff0000',
    )

    group_fields_ids, fields_ids = insert_group_fields(conn, project_id, ontology)
    popup_fields_id, details_fields_id, list_fields_id = insert_fields_groups(conn, project_id, group_fields_ids, fields_ids, filters)

    ontology['group'].each_with_index{ |id_superclass, superclass_index|
      conn.exec('SAVEPOINT superclass')
      superclass_id, superclass = id_superclass
      superclass['display_mode'] = 'compact'
      superclass_menu_id = insert_menu_group(conn, project_id, poi_menu_id, [superclass_id], [superclass['icon']], css_parser, superclass, superclass_index)
      inserted = superclass['group'].each_with_index.collect{ |id_class, class_index|
        class_id, classs = id_class
        classs['color_fill'] = superclass['color_fill']
        classs['color_line'] = superclass['color_line']
        classs['display_mode'] = 'large'
        if classs.key?('group')
          conn.exec('SAVEPOINT class')
          class_menu_id = insert_menu_group(conn, project_id, superclass_menu_id, [superclass_id, class_id], [superclass['icon'], classs['icon']], css_parser, classs, class_index)
          inserted = classs['group'].each_with_index.collect{ |id_subclass, subclass_index|
            subclass_id, subclass = id_subclass
            subclass['color_fill'] = superclass['color_fill']
            subclass['color_line'] = superclass['color_line']
            subclass['display_mode'] = 'large'
            class_path = [superclass_id, class_id, subclass_id]
            source_slug = class_path.join('-')
            icons = [superclass['icon'], classs['icon'], subclass['icon']]
            insert_menu_category(conn, project_id, class_menu_id, class_path, icons, source_slug, css_parser, subclass, subclass_index, popup_fields_id, details_fields_id, list_fields_id)
          }.any?
          if !inserted
            conn.exec('ROLLBACK TO SAVEPOINT class')
          end
          inserted
        else
          class_path = [superclass_id, class_id]
          source_slug = class_path.join('-')
          icons = [superclass['icon'], classs['icon']]
          insert_menu_category(conn, project_id, superclass_menu_id, class_path, icons, source_slug, css_parser, classs, class_index, popup_fields_id, details_fields_id, list_fields_id)
        end
      }.any?
      if !inserted
        conn.exec('ROLLBACK TO SAVEPOINT superclass')
      end
    }
  }
end

def new_source_menu(con, project_id, root_menu_id, metadatas, css, schema, filters)
  css_parser = CssParser::Parser.new
  css_parser.load_uri!("/srv/app/public#{css}")

  con.transaction { |conn|
    properties_extra = {
      'all' => schema['properties'].to_h{ |key, _sch|
        [key, nil]
      },
    }

    poi_menu_id = insert_menu_item(
      conn,
      project_id: project_id,
      slugs: { 'en-US' => 'pois', 'fr-FR' => 'poi', 'es-ES' => 'poi' },
      parent_id: root_menu_id,
      index_order: 2,
      type: 'menu_group',
      name: { 'en-US' => 'POIs', 'fr-FR' => 'POI', 'es-ES' => 'PDI' }.compact,
      display_mode: 'compact',

      icon: 'teritorio teritorio-extra-point',
      color_fill:	'#ff0000',
      color_line:	'#ff0000',
    )

    group_fields_ids, fields_ids = insert_group_fields(conn, project_id, { 'properties_extra' => properties_extra })
    popup_fields_id, details_fields_id, list_fields_id = insert_fields_groups(conn, project_id, group_fields_ids, fields_ids, filters)

    metadatas.collect.each_with_index.collect{ |slug_metadata, index|
      slug, metadata = slug_metadata
      subclass = {
        'label' => metadata['name'],
        'color_fill' => '#ff0000',
        'color_line' => '#ff0000',
        'display_mode' => 'compact',
        'zoom' => 16,
        'properties_extra' => ['all'],
      }

      insert_menu_category(conn, project_id, poi_menu_id, nil, nil, slug, css_parser, subclass, index, popup_fields_id, details_fields_id, list_fields_id)
    }
  }
end

def new_filter(con, project_id, schema, i18ns)
  con.transaction { |conn|
    conn.exec('DELETE FROM filters WHERE project_id = $1', [project_id])

    schema['properties'].transform_values{ |spec|
      if spec['type'] == 'array'
        spec['items']['enum']
      else
        spec['enum']
      end
    }.compact.except('tactile_paving', 'pastry', 'mobile_phone:repair', 'computer:repair', 'sport', 'access', 'dispensing').collect{ |key, enum|
      name = i18ns.dig(key, '@default') || { 'en-US' => key }

      field_id = conn.exec(
        '
        INSERT INTO fields(project_id, type, field)
        VALUES ($1, $2, $3)
        ON CONFLICT (project_id, "group", field)
        DO UPDATE SET
          field = EXCLUDED.field -- Do nothing, but helps to return the id
        RETURNING
          id
      ', [project_id, 'field', key]
      ) { |result|
        result.first['id'].to_i
      }

      filter_id = (
        if [%w[yes no], %w[no yes]].include?(enum)
          conn.exec(
            'INSERT INTO filters(project_id, type, boolean_property) VALUES ($1, $2, $3) RETURNING id',
            [project_id, 'boolean', field_id]
          ) { |result| result.first['id'].to_i }
        elsif enum.size <= 1
          next
        elsif enum.size <= 5
          conn.exec(
            'INSERT INTO filters(project_id, type, checkboxes_list_property) VALUES ($1, $2, $3) RETURNING id',
            [project_id, 'checkboxes_list', field_id]
          ) { |result| result.first['id'].to_i }
        else
          conn.exec(
            'INSERT INTO filters(project_id, type, multiselection_property) VALUES ($1, $2, $3) RETURNING id',
            [project_id, 'multiselection', field_id]
          ) { |result| result.first['id'].to_i }
        end
      )
      name.each_key{ |lang|
        conn.exec(
          'INSERT INTO filters_translations(filters_id, languages_code, name) VALUES ($1, $2, $3)',
          [filter_id, lang, name[lang]]
        )
      }
      [key, filter_id]
    }.compact.to_h
  }
end

namespace :project do
  desc 'Create a new project'
  task :new, [] => :environment do
    PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres').transaction { |conn|
      set_default_languages(conn)

      slug, osm_id, theme, ontologies, datasources_slug, website, map_apikey = ARGV[2..].collect(&:presence)
      ontologies = ontologies&.split(',')
      datasource_url = 'https://datasources.teritorio.xyz/0.1'

      css = '/static/font-teritorio-2.9.0/teritorio/teritorio.css'
      project_id, _theme_id = new_project(conn, slug, datasources_slug, osm_id, theme, css, website, map_apikey)

      role_uuid, _policy_uuid = create_role(conn, slug)
      create_user(conn, project_id, slug, role_uuid)

      if datasources_slug.nil?
        metadatas = {}
        schema = {}
        filters = {}
      else
        metadatas = load_from_source(conn, "#{datasource_url}/data", slug, datasources_slug)
        i18ns = fetch_json("#{datasource_url}/data/#{datasources_slug}/i18n.json")
        load_i18n(conn, slug, i18ns)
        schema = fetch_json("#{datasource_url}/data/#{datasources_slug}/schema.json")
        filters = new_filter(conn, project_id, schema, i18ns)
      end
      root_menu_id = new_root_menu(conn, project_id)
      if !datasources_slug.nil?
        new_ontologies_menu(conn, project_id, root_menu_id, ontologies, css, filters)
      end
      new_source_menu(conn, project_id, root_menu_id, metadatas, css, schema, filters)
    }

    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
