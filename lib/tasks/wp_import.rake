# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'
require 'pg'
require 'cgi'
require 'image_size'
require 'active_support/core_ext/digest/uuid'

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
  raise "[ERROR] #{url} => #{response.status}" if !response.status.success?

  JSON.parse(response)
end

def fetch_html(url)
  response = HTTP.follow.get(url)
  return nil if response.status.code == 404
  raise "[ERROR] #{url} => #{response.status}" if !response.status.success?

  doc = Nokogiri::HTML.parse(response.to_s)
  doc.xpath('//article/div').children.to_s
end

def fetch_image(url)
  response = HTTP.follow.get(url)
  raise "[ERROR] #{url} => #{response.status}" if !response.status.success?

  response.body.to_s
end

def load_project(project_slug, datasources_slug, url)
  settings = fetch_json(url)

  icon_font_css_url = settings['icon_font_css_url']
  if icon_font_css_url.include?('teritorio.css')
    icon_font_css_url = icon_font_css_url.gsub(/(.*ver=)(.*)/, '/static/font-teritorio-\\2/teritorio/teritorio.css')
  elsif icon_font_css_url.include?('glyphicons')
    icon_font_css_url = '/static/glyphicons-regular-2.0/glyphicons-regular.css'
  end

  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    project_id = conn.exec(
      '
      INSERT INTO projects(slug, datasources_slug, icon_font_css_url, polygon, bbox_line, polygons_extra, default_country, default_country_state_opening_hours)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      ON CONFLICT (slug)
      DO UPDATE SET
        datasources_slug = $2,
        icon_font_css_url = $3,
        polygon = $4,
        bbox_line = $5,
        polygons_extra = $6,
        default_country = $7,
        default_country_state_opening_hours = $8
      RETURNING
        id
      ',
      [
        project_slug,
        datasources_slug,
        icon_font_css_url,
        settings['polygon']['data'].to_json,
        settings['bbox_line'].to_json,
        settings['polygons_extra']&.transform_values{ |polygon| polygon['data'].split('/')[-1].split('.')[0].to_i }&.to_json,
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

    [project_id, settings]
  }
end

def load_articles(project_id, base_url, url_articles)
  base_url = base_url.split('/')[0..2].join('/') + '/'
  articles = fetch_json(url_articles)

  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    conn.exec('DELETE FROM projects_articles WHERE projects_id = $1', [project_id])

    articles.each_with_index { |article, index|
      url = article['url']
      title = article['title']

      if url.start_with?(base_url)
        html = fetch_html(article['url'])
        html = html.gsub(base_url, '/')

        slug = url.split('/')[5]

        article_id = conn.exec("
          SELECT
            articles.id
          FROM
            articles
            JOIN articles_translations ON
              articles_translations.articles_id = articles.id
          WHERE
            articles.project_id = $1 AND
            articles_translations.languages_code = 'fr-FR' AND
            articles_translations.slug = $2
        ", [project_id, slug]) { |result|
          result.first&.[]('id')&.to_i
        }

        if article_id.nil?
          article_id = conn.exec("
            INSERT INTO articles(project_id)
            VALUES ($1)
            RETURNING
              id
          ", [project_id]) { |result|
            result.first['id'].to_i
          }
        end

        conn.exec("
          INSERT INTO articles_translations(articles_id, languages_code, title, slug, body)
          VALUES ($1, $2, $3, $4, $5)
          ON CONFLICT (articles_id, languages_code)
          DO UPDATE SET
            title = $3,
            slug = $4,
            body = $5
          ", [article_id, 'fr-FR', title, slug, html])

        conn.exec("
          INSERT INTO projects_articles(projects_id, articles_id, index)
          VALUES ($1, $2, $3)
          ", [project_id, article_id, index])
      else
        puts "[ERROR] Article not in base url: #{url}"
        exit
      end
    }
  }
end

def load_theme(project_id, settings, theme_slug, user_uuid)
  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    theme = settings['themes'].first

    logo = load_images(conn, project_id, user_uuid, [theme['logo_url']], nil).values.first
    favicon = load_images(conn, project_id, user_uuid, [theme['favicon_url']], nil).values.first

    theme_id = conn.exec(
      '
      INSERT INTO themes(project_id, slug, logo, favicon, favorites_mode, explorer_mode)
      VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (project_id, slug)
      DO UPDATE SET
        logo = $3,
        favicon = $4,
        favorites_mode = $5,
        explorer_mode = $6
      RETURNING
        id
      ',
      [
        project_id,
        theme_slug,
        logo,
        favicon,
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

    [theme_id, theme['site_url']['fr']]
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

def load_field_group(conn, project_id, group, i18ns, size_context)
  group_key = [group.except('group'), size_context]
  if @fields[group_key]

    if group['group']
      ids = (group['fields'] || []).collect{ |f|
        load_field_group(conn, project_id, f, i18ns, size_context)
      }

      conn.exec('SELECT array_agg(related_fields_id ORDER BY index) AS ids FROM fields_fields WHERE fields_id = $1', [@fields[group_key]]) { |result|
        if !result.first.nil?
          db_ids = result.first['ids']
          if !db_ids.nil? && ids.join(',') != db_ids[1..-2]
            puts "[ERROR] Group fields \"#{group['group']}\" mismatch content"
          end
        end
      }
    end

    @fields[group_key]
  else
    if group['group']
      duplicate_fields = (group['fields'] || []).pluck('field').compact.tally.select{ |_k, v| v > 1 }.keys
      if duplicate_fields.size > 0
        puts "[ERROR] Duplicate field in group #{group['group']}: #{duplicate_fields.join(', ')}"
      end
      ids = (group['fields'] || []).collect{ |f|
        load_field_group(conn, project_id, f, i18ns, size_context)
      }
    end

    id = conn.exec(
      '
    INSERT INTO fields(project_id, type, field, label_small, label_large, "group", display_mode, icon)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    ON CONFLICT (project_id, "group", field)
    DO UPDATE SET
      label_small = fields.label_small OR EXCLUDED.label_small,
      label_large = fields.label_large OR EXCLUDED.label_large,
      field = EXCLUDED.field,
      "group" = EXCLUDED."group",
      display_mode = EXCLUDED.display_mode,
      icon = EXCLUDED.icon
    RETURNING
      id
    ', [
        project_id,
        group['group'] ? 'group' : 'field',
        group['field'],
        size_context == 'small' ? group['label'] || false : false,
        size_context == 'large' ? group['label'] || false : false,
        group['group'],
        group['display_mode'],
        group['icon'],
      ]
    ) { |result|
      @fields[group_key] = result.first['id'].to_i
    }

    label = i18ns.dig(group['group'], 'label', 'fr') || i18ns.dig(group['field'], 'label', 'fr')
    label_popup = i18ns.dig(group['group'], 'label_popup', 'fr') || i18ns.dig(group['field'], 'label_popup', 'fr')
    label_popup = nil if label_popup == label
    label_details = i18ns.dig(group['group'], 'label_details', 'fr') || i18ns.dig(group['field'], 'label_details', 'fr')
    label_details = nil if label_details == label
    label_list = i18ns.dig(group['group'], 'label_list', 'fr') || i18ns.dig(group['field'], 'label_list', 'fr')
    label_list = nil if label_list == label

    if !label.nil?
      conn.exec(
        '
      INSERT INTO fields_translations(fields_id, languages_code, name, name_small, name_large, name_title)
      VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (fields_id, languages_code)
      DO UPDATE SET
        name = $3,
        name_small = $4,
        name_large = $5,
        name_title = $6
      ', [
          id,
          'fr-FR',
          label,
          label_popup,
          label_details,
          label_list,
        ]
      )
    end

    if group['group']
      ids.each_with_index { |i, index|
        conn.exec('INSERT INTO fields_fields(fields_id, related_fields_id, index) VALUES ($1, $2, $3)', [id, i, index])
      }
    end

    id
  end
end

def load_fields(conn, project_id, pois, menu_items, i18ns)
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

  invalid_fields = fields.collect{ |f| [f[1], f[2]&.pluck('fields')&.flatten(1), f[3]].flatten(1) }.flatten(2).compact.select{ |field| /[ \t=]/.match?(field['field']) }.uniq
  if !invalid_fields.empty?
    puts "[ERROR] Invalid field name [ \t=] #{invalid_fields.join(', ')}"
  end

  field_list_with_label = fields.pluck(3).flatten(1).compact.select{ |f| !f['label'].nil? }.uniq
  if !field_list_with_label.empty?
    puts "[ERROR] Fields list with label #{field_list_with_label.join(', ')}"
  end

  # details_fields
  field_with_multiple_label_popup_confg = fields.collect{ |f| f[2]&.pluck('fields')&.flatten(1) }.flatten(1).compact.group_by{ |field| field['field'] }.select{ |_key, group| group.pluck('label').uniq.size > 1 }.collect(&:first)
  if !field_with_multiple_label_popup_confg.empty?
    puts "[ERROR] Fields with multiple popup details configurations #{field_with_multiple_label_popup_confg.join(', ')}"
  end

  field_with_multiple_label_detail_confg = fields.collect{ |f| f[2]&.pluck('fields')&.flatten(1) }.flatten(1).compact.group_by{ |field| field['field'] }.select{ |_key, group| group.pluck('label').uniq.size > 1 }.collect(&:first)
  if !field_with_multiple_label_detail_confg.empty?
    puts "[ERROR] Fields with multiple label details configurations #{field_with_multiple_label_detail_confg.join(', ')}"
  end

  puts "fields: #{fields.size}"
  fields.select{ |field|
    !multiple_config.include?(field[0])
  }.collect{ |field|
    [field[0]] + %w[popup details list].zip(field[1..]).collect{ |mode, f|
      load_field_group(conn, project_id, {
        'group' => "#{menu_items[field[0]]&.dig('category', 'name', 'fr')} #{mode}",
        'fields' => f,
      }, i18ns, mode == 'details' ? 'large' : mode == 'popup' ? 'small' : nil)
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
  }.flatten.uniq.index_with{ |_id| true }
end

def load_use_external_details_link(pois, host)
  pois.select { |poi|
    website_details = poi.dig('properties', 'editorial', 'website:details')
    !website_details.nil? && !website_details.start_with?(host)
  }.collect{ |poi|
    poi.dig('properties', 'metadata', 'category_ids')&.select{ |id| id != 0 } # 0 from buggy WP
  }.flatten.uniq.index_with{ |_id| true }
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
  puts "missing_category_ids: #{missing_category_ids.inspect}" if !missing_category_ids.empty?
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

def add_waypoints(menu_items, pois, url_pois)
  pois = pois.collect{ |poi|
    dep_ids = (poi['properties'].delete('dep_ids') || poi['properties']['metadata'].delete('dep_ids'))&.compact&.presence
    if !dep_ids.nil?
      poi['properties']['dep_ids'] = dep_ids
    end

    poi
  }

  waypoint_id = 654_654_654 # Magic number to avoid collision with other pois
  # Fetch waypoints from deps and add them as local pois
  waypoints = pois.select{ |poi| poi['properties']['dep_ids']&.include?(-1) }.collect{ |poi|
    poi_id = poi['properties']['metadata']['id']
    wp_ids = []
    wps = fetch_json(url_pois.gsub('/pois.json', "/poi/#{poi_id}/deps.geojson"))['features'].select{ |p|
      p['properties'].key?('route:point:type')
    }.each_with_index.collect{ |p, index|
      id = (waypoint_id += 1)
      wp_ids << id
      p['properties'].delete('id')
      p['properties']['metadata'] = {
        'id' => id,
        'category_ids' => [-1],
        'source_id' => "#{poi_id}-#{index}"
      }
      p['properties']['route:waypoint:type'] = p['properties'].delete('route:point:type').gsub('way_point', 'waypoint')
      p['properties']['name'] = p['properties']['name']['fr'] if p['properties']['name'].present?
      p['properties']['description'] = p['properties']['description']['fr'] if p['properties']['description'].present?
      p
    }

    poi['properties']['dep_ids'] = poi['properties']['dep_ids'].select{ |dep_id| dep_id != -1 } + wp_ids

    wps
  }.flatten(1)

  waypoints_menu = {
    'id' => -1,
    'parent_id' => nil,
    'selected_by_default' => false,
    'hidden' => true,
    'index_order' => 0,
    'category' => {
      'id' => -1,
      'name' => {
        'en' => 'Waypoints',
        'fr' => 'Points de passage',
      },
      'icon' => 'teritorio teritorio-beef00',
      'color_fill' => '#beef00',
      'color_line' => '#beef00',
      'style_class' => nil,
      'display_mode' => 'compact'
    },
  }

  [menu_items + [waypoints_menu], pois + waypoints]
end

def load_images(conn, project_id, user_uuid, image_urls, directory)
  folder_uuid = (
    if !directory.nil?
      folder_uuid = Digest::UUID.uuid_v4
      conn.exec('
      MERGE INTO
        directus_folders
      USING (SELECT $1::integer, $2::uuid AS id, $3) AS source(project_id, id, name) ON
        directus_folders.project_id = source.project_id AND
        directus_folders.name = source.name AND
        directus_folders.parent IS NULL
      WHEN MATCHED THEN
        UPDATE SET
          name = source.name -- Do nothing, but helps to return the id
      WHEN NOT MATCHED THEN
        INSERT (project_id, id, name)
        VALUES (source.project_id, source.id, source.name)
      RETURNING
        directus_folders.id
    ', [project_id, folder_uuid, directory]) { |result|
        result.first['id']
      }
    end
  )

  directus_files = {}
  images_uuids = image_urls.collect{ |image_url|
    if directus_files[image_url].nil?
      img_data = fetch_image(image_url)
      next if img_data.nil?

      uuid = Digest::UUID.uuid_from_hash(Digest::MD5, Digest::UUID::DNS_NAMESPACE, image_url)
      name = image_url.split('/')[-1]
      if %w[gpx pdf].include?(image_url.split('.').last)
        width = nil
        height = nil
        mime = image_url.split('.').last == 'gpx' ? 'application/gpx+xml' : 'application/pdf'
      else
        image_info = ImageSize.new(StringIO.new(img_data))
        width = image_info.width
        height = image_info.height
        mime = image_info.media_type
      end
      filename = "#{uuid}.#{mime.split('/')[-1].split('+')[0]}"
      File.binwrite("./uploads/#{filename}", img_data)
      directus_files[image_url] = [uuid, filename, name, name.split('.')[..-2].join('.'), mime, user_uuid, img_data.size, width, height]
      uuid.to_s
    else
      directus_files[image_url][0]
    end
  }

  conn.exec('DROP TABLE IF EXISTS files_raw')
  conn.exec("
    CREATE TEMP TABLE files_raw(
      id text,
      filename_disk text,
      filename_download text,
      title text,
      type text,
      uploaded_by text,
      filesize text,
      width text,
      height text
    )
  ")
  enco = PG::BinaryEncoder::CopyRow.new
  conn.copy_data('COPY files_raw FROM STDIN (FORMAT binary)', enco) {
    directus_files.values.each{ |raw| conn.put_copy_data(raw.collect{ |r| r&.to_s }) }
  }
  conn.exec_params("
    MERGE INTO
      directus_files
    USING
      files_raw
    ON
      directus_files.id = files_raw.id::uuid
    WHEN MATCHED THEN
      UPDATE SET
        project_id = $1,
        filename_disk = files_raw.filename_disk,
        filename_download = files_raw.filename_download,
        title = files_raw.title,
        type = files_raw.type,
        folder = $2::uuid,
        uploaded_by = files_raw.uploaded_by::uuid,
        filesize = files_raw.filesize::integer,
        width = files_raw.width::integer,
        height = files_raw.height::integer
    WHEN NOT MATCHED THEN
      INSERT (id, project_id, storage, filename_disk, filename_download, title, type, folder, uploaded_by, filesize, width, height)
      VALUES (
        files_raw.id::uuid,
        $1,
        'local',
        files_raw.filename_disk,
        files_raw.filename_download,
        files_raw.title,
        files_raw.type,
        $2::uuid,
        files_raw.uploaded_by::uuid,
        files_raw.filesize::integer,
        files_raw.width::integer,
        files_raw.height::integer
      )
  ", [project_id, folder_uuid])

  image_urls.zip(images_uuids).to_h
end

def load_menu(project_slug, project_id, theme_id, user_uuid, url, url_pois, url_menu_sources, i18ns, policy_uuid, url_base)
  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    conn.exec('DELETE FROM menu_items WHERE project_id = $1', [project_id])
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
          'en-US' => 'Root',
          'fr-FR' => 'Racine',
        },
        'icon' => 'teritorio teritorio-beef00',
        'color_fill' => '#beef00',
        'color_line' => '#beef00',
        'style_class' => nil,
        'display_mode' => 'compact'
      },
    })

    pois = fetch_json(url_pois)['features']
    # Missing poi from buggy WP pois.geojson
    pois = add_missing_pois(menu_sources, pois)
    menu_items, pois = add_waypoints(menu_items, pois, url_pois)

    # Remove duplicate OSM objects in same catagory from WP API
    pois = pois.group_by{ |poi|
      if poi['properties'].key?('metadata')
        [
          poi['properties']['metadata']['category_ids'],
          poi['properties']['metadata']['source_id'] || poi['properties']['metadata']['id']
        ]
      else
        poi['properties']['id']
      end
    }.values.collect{ |pois|
      pois.min_by{ |poi| [poi['properties']['id'] || poi['properties']['metadata']['id']] }
    }

    fields = load_fields(conn, project_id, pois, menu_items, i18ns)
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

    # Categories not linked to datasource
    local_poi = pois.select{ |poi| %w[tis zone assmat].include?(poi['properties']['metadata']['source']) || poi.dig('properties', 'metadata', 'category_ids') == [-1] }
    local_category_ids = local_poi.collect{ |poi| poi['properties']['metadata']['category_ids'] }.flatten.uniq
    categories_local = menu_items.select{ |menu| menu['category'] && local_category_ids.include?(menu['id']) }.sort_by{ |category_local| category_local['category']['id'] }
    source_ids, deps = load_local_pois(conn, project_slug, project_id, user_uuid, categories_local, local_poi, i18ns, policy_uuid, url_base)

    until menu_entries.empty?
      menu = menu_entries.pop
      if !menu['parent_id'].nil? && !catorgry_ids_map.key?(menu['parent_id'])
        # parent_id not mapped yet
        menu_entries.unshift(menu)
        next
      end

      # Skip menu for local waypoints
      next if menu['id'] == -1

      fields_id = fields_ids[menu['id']]
      menu_item_id = conn.exec(
        '
        INSERT INTO menu_items(
          project_id,
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
          project_id,
          menu['index_order'],
          menu['hidden'],
          catorgry_ids_map[menu['parent_id']],
          menu['selected_by_default'],
          menu_type(menu),
          (menu_dig_all(menu, 'icon').presence || icon[menu['id']] || 'teritorio teritorio-beef00').strip,
          (menu_dig_all(menu, 'color_fill').presence || color_fill[menu['id']] || '#beef00').strip,
          (menu_dig_all(menu, 'color_line').presence || color_line[menu['id']] || '#beef00').strip,
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
      # Create/get id of fields
      fields_ids = %w[property_begin property_end property].select{ |property| filter[property].present? }.to_h{ |property|
        id = conn.exec(
          '
          INSERT INTO fields(project_id, type, field)
          VALUES ($1, $2, $3)
          ON CONFLICT (project_id, "group", field)
          DO UPDATE SET
            field = EXCLUDED.field -- Do nothing, but helps to return the id
          RETURNING
            id
        ', [project_id, 'field', filter[property]]
        ) { |result|
          result.first['id'].to_i
        }
        [filter[property], id]
      }

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
          filter['type'] == 'date_range' ? fields_ids[filter['property_begin']] : nil,
          filter['type'] == 'date_range' ? fields_ids[filter['property_end']] : nil,
          # number_range
          filter['type'] == 'number_range' ? fields_ids[filter['property']] : nil,
          filter['min'],
          filter['max'],
          # multiselection
          filter['type'] == 'multiselection' ? fields_ids[filter['property']] : nil,
          # checkboxes_list
          filter['type'] == 'checkboxes_list' ? fields_ids[filter['property']] : nil,
          # boolean
          filter['type'] == 'boolean' ? fields_ids[filter['property']] : nil,
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
          INSERT INTO menu_items_filters(menu_items_id, filters_id, index)
          VALUES (
            $1,
            $2,
            (SELECT coalesce(max(index) + 1, 1) FROM menu_items_filters WHERE menu_items_id = $1)
          )
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
      poi.dig('properties', 'metadata', 'source') != 'zone' && poi.dig('properties', 'metadata', 'source') != 'tis' && poi.dig('properties', 'metadata', 'category_ids') != [-1]
    }.collect{ |poi|
      id = poi.dig('properties', 'metadata', 'id')
      ref = poi.dig('properties', 'tis_id') || poi.dig('properties', 'metadata', 'source_id')
      if ref.nil? && !poi.dig('properties', 'metadata', 'osm_type').nil? && !poi.dig('properties', 'metadata', 'osm_id').nil?
        ref = poi.dig('properties', 'metadata', 'osm_type')[0] + poi.dig('properties', 'metadata', 'osm_id').to_s
      end
      if ref.nil? && !poi.dig('properties', 'osm_poi_type').nil? && !poi.dig('properties', 'idosm').nil?
        ref = poi.dig('properties', 'osm_poi_type')[0] + poi.dig('properties', 'idosm').to_s
      end

      # if id.nil? || ref.nil?
      #   puts "nil ref/id on #{JSON.dump(poi)}"
      #   nil
      # else
      [id, ref, poi.dig('properties', 'metadata', 'category_ids').min]
      # end
    }.compact_blank.collect{ |id, ref, category_id|
      [project_id, ref, { original_id: id.to_s }.to_json, category_id]
    }

    conn.exec("
      CREATE TEMP TABLE pois_slug_import(
        project_id varchar NOT NULL,
        ref varchar,
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
          menu_items.project_id = $1 AND
          menu_items_translations.slug = $2
        ORDER BY
          menu_items.id
        RETURNING
          id
        ',
        [project_id, categorie['id'], source_id]
      ) { |result|
        result&.first
      }
      if id.nil?
        puts "[ERROR] Fails link _local_ source to menu_item: #{source_id}"
      end
    }

    # Make POI deps links from slug
    links_local_pois_deps(conn, project_id, deps)

    # POI from datasource with local addon

    local_addon_raw = []
    pois.each{ |poi|
      website_details = nil
      image_urls = nil
      if poi.dig('properties', 'editorial', 'source:website:details') == 'local'
        website_details = poi['properties']['editorial']['website:details']
      end
      if poi.dig('properties', 'source:image') == 'local'
        image_urls = poi['properties']['image']
      end
      if website_details || image_urls
        c = menu_items.find{ |menu| menu['id'] == poi['properties']['metadata']['category_ids'].first }
        dir = menu_dig_all(c, 'name')&.dig('fr')
        local_addon_raw << [poi['properties']['metadata']['id'].to_s, website_details, [image_urls, dir]]
      end
    }

    directus_files = local_addon_raw.collect(&:last).select{ |urls, _dir|
      !urls.nil?
    }.collect(&:reverse).group_by(&:first).transform_values{ |vv|
      vv.collect(&:last).flatten.uniq
    }.collect{ |dir, urls|
      load_images(conn, project_id, user_uuid, urls, dir)
    }.inject(&:merge)
    local_addon_raw.collect{ |row|
      row[-1] = row[-1][0]
      row
    }.select{ |raw| !raw[-1].nil? }.each{ |row|
      row[-1] = row[-1].collect{ |image_url| directus_files[image_url] }
    }

    conn.exec("
      CREATE TEMP TABLE local_addon_raw(
        poi_id text,
        website_details text,
        image json
      )
    ")
    enco = PG::BinaryEncoder::CopyRow.new
    conn.copy_data('COPY local_addon_raw FROM STDIN (FORMAT binary)', enco) {
      local_addon_raw.each{ |raw| conn.put_copy_data(raw) }
    }
    conn.exec_params("
      WITH a AS (
        SELECT
          pois.id AS poi_id,
          t.image::uuid AS files_id,
          t.index
        FROM
          local_addon_raw
          JOIN pois ON
            (pois.slugs->>'original_id')::bigint = local_addon_raw.poi_id::bigint
          JOIN sources ON
            sources.id = pois.source_id AND
            sources.project_id = $1
          JOIN LATERAL json_array_elements_text(image::json) WITH ORDINALITY AS t(image, index) ON true
      )
      MERGE INTO
        pois_files
      USING
        a AS local_addon_raw
      ON
        pois_files.pois_id = local_addon_raw.poi_id AND
        pois_files.directus_files_id = local_addon_raw.files_id
      WHEN NOT MATCHED THEN
        INSERT (pois_id, directus_files_id, index)
        VALUES (
          local_addon_raw.poi_id,
          local_addon_raw.files_id,
          local_addon_raw.index
        )
    ", [project_id])
    pois_custom_poi_ids = conn.exec_params("
      WITH a AS (
        SELECT
          pois.id AS poi_id,
          local_addon_raw.website_details
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
          website_details = local_addon_raw.website_details
      RETURNING
        pois.id
    ", [project_id]) { |result|
      result.collect{ |row| row['poi_id'] }
    }
    if pois_custom_poi_ids.size != local_addon_raw.size
      puts "[ERROR] Fails to insert custom POI : #{local_addon_raw.size} != #{pois_custom_poi_ids.size}"
    end
  }
end

def load_local_table(conn, source_name, name, table, table_aprent, fields, ps, i18ns, policy_uuid)
  fields_table = fields.select{ |_, _, _, _, type, _| !type.nil? }.collect{ |field, t, interface, _options, type, fk| [field.gsub(':', '___'), t, interface, type, fk] }
  create_table = fields_table.collect{ |field, _, _, type, fk| [field, type, fk.nil? ? nil : "REFERENCES #{fk}"].compact.join(' ') }.join(",\n")
  conn.exec('SET client_min_messages TO WARNING')
  conn.exec("DROP TABLE IF EXISTS \"t_#{table}\"")
  conn.exec("CREATE TEMP TABLE \"t_#{table}\" (#{create_table})".gsub(' integer', ' text').gsub(' bigint', ' text').gsub(' uuid', ' text').gsub(/REFERENCES [^ ]+( ON DELETE SET NULL| ON DELETE CASCADE|)/, ''))

  vv = ps.collect{ |p|
    values = fields_table.collect{ |field, t, _, _|
      begin
        if %w[id pois_id].include?(field)
          p['properties']['metadata']['id']
        elsif field == 'geom'
          if p['geometry']['type'] == 'Feature'
            p['geometry'] = p['geometry']['geometry']
          end
          p['geometry'].to_json
        elsif field == 'languages_code'
          'fr-FR'
        elsif field.include?('color')
          p['properties']['display'][field]
        else
          r = t.call(p['properties'][field.gsub('___', ':')], p['properties'])
          r = r.strip if r.is_a?(String)
          r
        end
      rescue StandardError => e
        puts p.inspect
        puts "ERROR: getting value for field \"#{field}\", #{e.message}"
        raise
      end
    }
  }.compact

  enco = PG::BinaryEncoder::CopyRow.new
  conn.copy_data("COPY \"t_#{table}\"(\"#{fields_table.collect(&:first).join('", "')}\") FROM STDIN (FORMAT binary)", enco) {
    vv.each{ |values|
      conn.put_copy_data(values.collect{ |r| r&.to_s })
    }
  }

  create_table = create_table.gsub(/^id varchar/, table_aprent.nil? ?
    'id integer DEFAULT nextval(\'"pois_id_seq"\'::regclass) PRIMARY KEY' :
    'id SERIAL PRIMARY KEY')
  create_table = create_table
                 .gsub('pois_id varchar', "\"#{source_name}_id\" SERIAL")
                 .gsub('geom json', 'geom geometry(Geometry,4326)')
                 .gsub(' json', ' jsonb')
  conn.exec("DROP TABLE IF EXISTS \"#{table}\" CASCADE")
  conn.exec("CREATE TABLE \"#{table}\" (#{create_table})")
  conn.exec("CREATE INDEX \"#{table[..(63 - 9)]}_idx_geom\" ON \"#{table}\" USING gist(geom)") if create_table.include?('geom geometry(Geometry,4326)')
  conn.exec("
    INSERT INTO \"#{table}\"(\"#{fields_table.collect(&:first).join('", "')}\")
    SELECT
    " + fields_table.collect { |field, _, _, type|
      if %w[id pois_id].include?(field) || type.include?('bigint')
        "\"#{field}\"::bigint"
      elsif type.include?('uuid')
        "\"#{field}\"::uuid"
      elsif field == 'geom'
        'ST_Force2D(ST_GeomFromGeoJSON(geom))'
      else
        "\"#{field}\""
      end
    }.join(', ') + "
    FROM
      \"t_#{table}\"
  ")

  conn.exec('DELETE FROM directus_collections WHERE collection = $1', ["#{table[..60]}_p"])
  conn.exec('DELETE FROM directus_collections WHERE collection = $1', ["#{table[..60]}_w"])
  conn.exec('DELETE FROM directus_collections WHERE collection = $1', [table[..62]])
  conn.exec('
    INSERT INTO directus_collections(collection, translations, hidden, icon, "group") VALUES ($1, $2, $3, $4, $5)
    ON CONFLICT (collection)
    DO UPDATE SET
      translations = $2
  ', [
    table[..62],
    !table.end_with?('_t') && !table.end_with?('_i') ? [{ language: 'fr-FR', translation: uncapitalize(name) }].to_json : nil,
    table.end_with?('_t') || table.include?('-waypoints'),
    'pin_drop',
    table.end_with?('_t') ? table_aprent[..62] : 'local_sources',
  ])
  conn.exec('DELETE FROM directus_fields WHERE collection = $1', [table[..62]])
  fields.each{ |key, _, interface, options, _, _|
    name = i18ns.dig(key, 'label', 'fr')

    conn.exec('
      INSERT INTO directus_fields(collection, field, special, translations, options, readonly, hidden, sort, interface) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
    ', [
      table[..62],
      key[..62].gsub(':', '___'),
      interface == 'files' ? 'files' : nil,
      name.nil? ? nil : [{ language: 'fr-FR', translation: uncapitalize(name) }].to_json,
      options,
      key == 'id',
      table.end_with?('_t') && %w[id pois_id languages_code].include?(key),
      nil,
      interface,
    ])
  }

  conn.exec('DELETE FROM directus_permissions WHERE collection = $1', [table[..62]])
  %w[create read update delete].each{ |action|
    conn.exec('
      INSERT INTO directus_permissions(policy, collection, action, permissions, fields)
      VALUES ($1, $2, $3, $4, $5)
    ', [
      policy_uuid,
      table[..62],
      action,
      {}.to_json,
      '*'
    ])
  }
end

def load_local_pois(conn, project_slug, project_id, user_uuid, categories_local, pois, i18ns, policy_uuid, url_base)
  slugs = []
  deps_ids_s = {}
  source_ids = categories_local.collect{ |category_local|
    name = category_local['category']['name']['en'] || category_local['category']['name']['fr']
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

      p['properties'].compact.except('metadata', 'display', 'editorial', 'classe', 'custom_details', 'sources', 'osm_galerie_images', 'classic-editor-remember').merge({
        'color_fill' => p.dig('properties', 'display', 'color_fill'),
        'color_line' => p.dig('properties', 'display', 'color_line'),
      }.compact).collect{ |k, v|
        if k.include?('color')
          [k, v]
        elsif v.is_a?(Array)
          [k, Array]
        elsif v.is_a?(Hash)
          [k, Hash]
        elsif v.is_a?(Integer) || v.to_i.to_s == v
          [k, Integer]
        elsif v.is_a?(String) && (v.include?('</') || v.match?(/&[a-z]{2-10};/))
          [k, :html]
        else
          [k, v.is_a?(String) ? v.size <= 15 ? v : v.size >= 255 ? '...' : nil : v.presence]
        end
      }
    }.flatten(1).group_by(&:first).transform_values{ |key_values|
      key_values.collect(&:last).tally
    }.to_h{ |key, stats|
      if !key.include?('color') && (stats.size != 1 || stats.to_a[0][0].is_a?(String)) && stats.size > ps.size / 10
        stats = { nil => stats.size }
      end
      [key, stats]
    }
    fields = []
    fields_translations = []
    fields_image = nil
    fields_deps = nil
    value_stats.sort_by{ |_key, stats| -stats.values.sum }.each{ |key, stats|
      interface = nil
      options = nil
      fk = nil
      i = if %w[name description short_description].include?(key)
            f = ->(i, _j) { i }
            interface = 'input-rich-text-html' if stats&.keys&.include?(:html)
            'text'
          elsif ['addr:postcode', 'addr:housenumber', 'maxlength', 'ref', 'start_date', 'end_date', 'ref:fr:siret'].include?(key)
            f = ->(i, _j) { i }
            'varchar'
          elsif key == 'image'
            fields_image = key
            f = nil
            interface = 'files'
            options = '{"template":"{{directus_files_id.$thumbnail}} {{directus_files_id.title}}"}'
            nil
          elsif key == 'dep_ids'
            fields_deps = true
            nil
          elsif key == 'route:waypoint:type'
            f = ->(i, _j) { i }
            interface = 'select-dropdown'
            options = '{"choices":[{"text":"parking","value":"parking","icon":"parking"},{"text":"start","value":"start","icon":"flag"},{"text":"waypoint","value":"waypoint","icon":"pin_drop"},{"text":"end","value":"end","icon":"emoji_flags"}]}'
            'varchar'
          elsif key == 'download'
            f = ->(i, _j) { i.nil? ? nil : load_images(conn, project_id, user_uuid, [i.first], name).values.first }
            interface = 'file'
            fk = 'directus_files(id) ON DELETE SET NULL'
            'uuid'
          elsif ['route:gpx_trace', 'route:pdf', 'image:thumbnail'].include?(key)
            f = ->(i, _j) { i.nil? ? nil : load_images(conn, project_id, user_uuid, [i], name).values.first }
            interface = key == 'image:thumbnail' ? 'file-image' : 'file'
            fk = 'directus_files(id) ON DELETE SET NULL'
            'uuid'
          elsif key == 'website:details'
            f = ->(_i, j) { j['editorial']['website:details'] }
            'varchar'
          elsif key.include?('color')
            f = ->(i, _j) { i }
            interface = 'select-color'
            options = { presets: stats.keys.collect{ |v| { name: v, color: v } } }.to_json
            'varchar'
          elsif stats&.keys&.include?(Array) || stats&.keys&.include?(Hash)
            f = ->(i, _j) { i&.to_json }
            'json'
          elsif stats&.keys&.size == 1 && stats&.keys&.include?(Integer)
            f = ->(i, _j) { i&.to_i }
            'bigint'
          elsif stats&.keys&.include?(:html)
            f = ->(i, _j) { i }
            interface = 'input-rich-text-html'
            'text'
          elsif stats&.keys&.include?('...')
            f = ->(i, _j) { i }
            'text'
          else
            f = ->(i, _j) { i }
            'varchar'
          end
      if !i.nil? && !stats.keys.include?(nil) && stats.keys.size == ps.size
        i += ' NOT NULL'
      end
      if %w[name description short_description].include?(key)
        fields_translations << [key, f, interface, options, i, fk]
      else
        fields << [key, f, interface, options, i, fk]
      end
    }

    conn.exec("DROP TABLE IF EXISTS \"#{table[..60]}_i\" CASCADE") if !fields_image.nil?
    conn.exec("DROP TABLE IF EXISTS \"#{table[..60]}_t\" CASCADE") if !fields_translations.empty?
    conn.exec('DELETE FROM directus_collections WHERE collection = $1', ["#{table[..60]}_i"])
    conn.exec('DELETE FROM directus_collections WHERE collection = $1', ["#{table[..60]}_t"])

    fields += [['id', nil, nil, nil, 'varchar', nil], ['geom', nil, nil, nil, 'json NOT NULL', nil]]
    load_local_table(conn, source_name, name, table, nil, fields, ps, i18ns, policy_uuid)

    if !fields_translations.empty?
      fields_translations += [
        ['id', nil, nil, nil, 'varchar', nil], ['pois_id', nil, nil, nil, 'integer NOT NULL', "\"#{table}\"(id) ON DELETE CASCADE"],
        ['languages_code', nil, nil, nil, 'varchar(255)', 'languages(code) ON DELETE CASCADE']
      ]
      load_local_table(conn, source_name, name, "#{table[..60]}_t", table, fields_translations, ps, i18ns, policy_uuid)
      conn.exec('DELETE FROM directus_relations WHERE many_collection = $1', ["#{table[..60]}_t"])
      conn.exec('
        INSERT INTO directus_fields(collection, field, special, interface, options, display) VALUES ($1, $2, $3, $4, $5, $6)
      ', [
        table[..62],
        "#{source_name[..50]}_translations",
        'translations',
        'translations',
        '{"languageField":"name","defaultLanguage":"en-US","defaultOpenSplitView":true,"userLanguage":true}',
        'translations',
      ])
      conn.exec('
        INSERT INTO directus_relations(many_collection, many_field, one_collection, one_field, junction_field, one_deselect_action) VALUES ($1, $2, $3, $4, $5, $6)
      ', [
        "#{table[..60]}_t",
        'languages_code',
        'languages',
        nil,
        'pois_id',
        'nullify',
      ])
      conn.exec('
        INSERT INTO directus_relations(many_collection, many_field, one_collection, one_field, junction_field, one_deselect_action) VALUES ($1, $2, $3, $4, $5, $6)
      ', [
        "#{table[..60]}_t",
        'pois_id',
        table[..62],
        "#{source_name[..50]}_translations",
        'languages_code',
        'nullify',
      ])
    end

    if !fields_image.nil?
      image_urls = ps.select{ |poi| !poi['properties']['image'].nil? }.collect{ |poi|
        [poi['properties']['metadata']['id'], poi['properties']['image']]
      }.to_h
      directus_files = load_images(conn, project_id, user_uuid, image_urls.values.flatten.uniq, name)

      table_i = "#{table[..60]}_i"
      conn.exec("DROP TABLE IF EXISTS \"#{table_i}\" CASCADE")
      conn.exec("
        CREATE TABLE \"#{table_i}\"(
          id SERIAL PRIMARY KEY,
          pois_id bigint NOT NULL REFERENCES \"#{table}\"(id) ON DELETE CASCADE,
          directus_files_id uuid NOT NULL REFERENCES directus_files(id) ON DELETE CASCADE,
          index integer NOT NULL
        )
      ")
      image_urls.collect{ |poi_id, image_urls|
        image_urls.each_with_index.collect{ |image_url, index|
          conn.exec_params("
          INSERT INTO \"#{table_i}\"(pois_id, directus_files_id, index)
          VALUES ($1, $2, $3)
        ", [
            poi_id,
            directus_files[image_url],
            index,
          ])

          [poi_id, directus_files[image_url]]
        }
      }

      conn.exec('DELETE FROM directus_relations WHERE many_collection = $1', [table_i])

      conn.exec('DELETE FROM directus_collections WHERE collection = $1', [table_i])
      conn.exec('
        INSERT INTO directus_collections(collection, hidden, icon, "group") VALUES ($1, $2, $3, $4)
      ', [
        table_i,
        true,
        'pin_drop',
        table,
      ])
      conn.exec('
        INSERT INTO directus_relations(many_collection, many_field, one_collection, one_field, junction_field, sort_field, one_deselect_action) VALUES ($1, $2, $3, $4, $5, $6, $7)
      ', [
        table_i,
        'directus_files_id',
        'directus_files',
        nil,
        'pois_id',
        nil,
        'delete',
      ])
      conn.exec('
      INSERT INTO directus_relations(many_collection, many_field, one_collection, one_field, junction_field, sort_field, one_deselect_action) VALUES ($1, $2, $3, $4, $5, $6, $7)
      ', [
        table_i,
        'pois_id',
        table[..62],
        'image',
        'directus_files_id',
        'index',
        'delete',
      ])

      conn.exec('DELETE FROM directus_permissions WHERE collection = $1', [table_i])
      %w[create read update delete].each{ |action|
        conn.exec('
          INSERT INTO directus_permissions(policy, collection, action, permissions, fields)
          VALUES ($1, $2, $3, $4, $5)
        ', [
          policy_uuid,
          table_i,
          action,
          {}.to_json,
          '*'
        ])
      }
    end

    if !fields_deps.nil?
      deps_ids = ps.to_h{ |poi|
        [poi['properties']['metadata']['id'], poi['properties']['dep_ids']]
      }

      # Associated POI

      table_p = "#{table[..60]}_p"
      conn.exec("DROP TABLE IF EXISTS \"#{table_p}\" CASCADE")
      conn.exec("
        CREATE TABLE \"#{table_p}\"(
          id SERIAL PRIMARY KEY,
          parent_pois_id integer NOT NULL REFERENCES \"#{table}\"(id) ON DELETE CASCADE,
          children_pois_id integer NOT NULL REFERENCES pois(id) ON DELETE CASCADE,
          index integer NOT NULL DEFAULT 1
        )
      ")
      deps_ids_s[table_p] = deps_ids

      conn.exec('DELETE FROM directus_relations WHERE many_collection = $1', [table_p])

      conn.exec('DELETE FROM directus_collections WHERE collection = $1', [table_p])
      conn.exec('
        INSERT INTO directus_fields(collection, field, special, interface, options, display) VALUES ($1, $2, $3, $4, $5, $6)
      ', [
        table[..62],
        'associated_pois',
        'm2m',
        'list-m2m',
        '{"enableCreate":false,"enableLink":true}',
        nil,
      ])
      conn.exec('
        INSERT INTO directus_collections(collection, hidden, icon, "group") VALUES ($1, $2, $3, $4)
      ', [
        table_p,
        true,
        'import_export',
        table,
      ])
      conn.exec('
        INSERT INTO directus_relations(many_collection, many_field, one_collection, one_field, junction_field, sort_field, one_deselect_action) VALUES ($1, $2, $3, $4, $5, $6, $7)
      ', [
        table_p,
        'children_pois_id',
        'pois',
        nil,
        'parent_pois_id',
        nil,
        'delete',
      ])
      conn.exec('
        INSERT INTO directus_relations(many_collection, many_field, one_collection, one_field, junction_field, sort_field, one_deselect_action) VALUES ($1, $2, $3, $4, $5, $6, $7)
      ', [
        table_p,
        'parent_pois_id',
        table[..62],
        'associated_pois',
        'children_pois_id',
        'index',
        'delete',
      ])

      conn.exec('DELETE FROM directus_permissions WHERE collection = $1', [table_p])
      %w[create read update delete].each{ |action|
        conn.exec('
          INSERT INTO directus_permissions(policy, collection, action, permissions, fields)
          VALUES ($1, $2, $3, $4, $5)
        ', [
          policy_uuid,
          table_p,
          action,
          {}.to_json,
          '*'
        ])
      }

      # Waypoints

      table_w = "#{table[..60]}_w"
      table_pdp = "local-#{project_slug}-waypoints"
      conn.exec("DROP TABLE IF EXISTS \"#{table_w}\" CASCADE")
      conn.exec("
        CREATE TABLE \"#{table_w}\"(
          id SERIAL PRIMARY KEY,
          parent_pois_id integer NOT NULL REFERENCES \"#{table}\"(id) ON DELETE CASCADE,
          children_pois_id integer NOT NULL REFERENCES \"#{table_pdp}\"(id) ON DELETE CASCADE,
          index integer NOT NULL DEFAULT 1
        )
      ")
      deps_ids.each{ |poi_id, dep_ids|
        conn.exec_params("
          INSERT INTO \"#{table_w}\"(parent_pois_id, children_pois_id, index)
          SELECT
            $1,
            dep_id::integer,
            index
          FROM
            jsonb_array_elements_text($2::jsonb) WITH ORDINALITY AS t(dep_id, index)
            JOIN \"#{table_pdp}\" AS w ON
              w.id = dep_id::integer
          ORDER BY
            index
          ", [
          poi_id,
          dep_ids.to_json,
        ])
      }

      conn.exec('DELETE FROM directus_relations WHERE many_collection = $1', [table_w])

      conn.exec('DELETE FROM directus_collections WHERE collection = $1', [table_w])
      conn.exec('
        INSERT INTO directus_fields(collection, field, special, interface, options, display) VALUES ($1, $2, $3, $4, $5, $6)
      ', [
        table[..62],
        'waypoints',
        'm2m',
        'list-m2m',
        '{"enableLink":true,"limit":200,"layout":"table","tableSpacing":"compact","fields":["index","children_pois_id.route___waypoint___type","children_pois_id.waypoints_translations.name"],"enableSelect":false}',
        nil,
      ])
      conn.exec('
        INSERT INTO directus_collections(collection, hidden, icon, "group") VALUES ($1, $2, $3, $4)
      ', [
        table_w,
        true,
        'import_export',
        table,
      ])
      conn.exec('
        INSERT INTO directus_relations(many_collection, many_field, one_collection, one_field, junction_field, sort_field, one_deselect_action) VALUES ($1, $2, $3, $4, $5, $6, $7)
      ', [
        table_w,
        'children_pois_id',
        table_pdp,
        nil,
        'parent_pois_id',
        nil,
        'delete',
      ])
      conn.exec('
        INSERT INTO directus_relations(many_collection, many_field, one_collection, one_field, junction_field, sort_field, one_deselect_action) VALUES ($1, $2, $3, $4, $5, $6, $7)
      ', [
        table_w,
        'parent_pois_id',
        table[..62],
        'waypoints',
        'children_pois_id',
        'index',
        'delete',
      ])

      conn.exec('DELETE FROM directus_permissions WHERE collection = $1', [table_w])
      %w[create read update delete].each{ |action|
        conn.exec('
          INSERT INTO directus_permissions(policy, collection, action, permissions, fields)
          VALUES ($1, $2, $3, $4, $5)
        ', [
          policy_uuid,
          table_w,
          action,
          {}.to_json,
          '*'
        ])
      }
    end

    # Create trigger and fill pois_local table
    conn.exec('SELECT api01.create_pois_local_view($1, $2, $3)', [project_id, source_id, table])
    conn.exec('SELECT api01.force_update_pois_local($1)', [table])

    source_id
  }

  [source_ids, deps_ids_s]
end

def links_local_pois_deps(conn, project_id, deps_ids_s)
  deps_ids_s.each{ |table_p, deps_ids|
    deps_ids.each{ |poi_id, dep_ids|
      conn.exec_params("
        INSERT INTO \"#{table_p}\"(parent_pois_id, children_pois_id, index)
        SELECT DISTINCT ON(\"index\")
          $1,
          pois.id,
          t.index
        FROM
          jsonb_array_elements_text($2::jsonb) WITH ORDINALITY AS t(dep_id, index)
          JOIN pois ON
            coalesce(pois.slugs->>'original_id', pois.id::text) = t.dep_id AND
            coalesce(pois.properties->'natives' ? 'route:waypoint:type', false) = false
          JOIN sources ON
            sources.id = pois.source_id AND
            sources.project_id = $3
        ORDER BY
          t.index,
          pois.slugs->>'original_id' NULLS LAST
        ", [
          poi_id,
          dep_ids.to_json,
          project_id,
        ])
    }
  }
end

namespace :wp do
  desc 'Import data from API'
  task :import, [] => :environment do
    url, project_slug, theme_slug, datasource_url, datasources_slug = ARGV[2..]
    base_url, project_id, settings, user_uuid, policy_uuid = nil
    PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres').transaction { |conn|
      set_default_languages(conn)
    }

    PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres').transaction { |conn|
      puts "\n====\n#{project_slug}\n====\n\n"
      base_url = "#{url}/#{project_slug}/#{theme_slug}"
      project_id, settings = load_project(project_slug, datasources_slug, "#{base_url}/settings.json")

      load_articles(project_id, base_url, "#{base_url}/articles.json?slug=non-classe")

      role_uuid, policy_uuid = create_role(conn, project_slug)
      user_uuid = create_user(conn, project_id, project_slug, role_uuid)
    }

    PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres').transaction { |conn|
      theme_id, url_base = load_theme(project_id, settings, theme_slug, user_uuid)

      load_from_source(conn, "#{datasource_url}/data", project_slug, datasources_slug) if datasources_slug.present?
      i18ns = fetch_json("#{base_url}/attribute_translations/fr.json")
      load_menu(project_slug, project_id, theme_id, user_uuid, "#{base_url}/menu.json", "#{base_url}/pois.json", "#{base_url}/menu_sources.json", i18ns, policy_uuid, url_base)
      i18ns = i18ns.transform_values{ |v|
        {
          '@default' => { 'fr-FR' => v.dig('label', 'fr') }.compact_blank,
          'values' => v['values']&.transform_values{ |vv|
            {
              '@default:full' => { 'fr-FR' => vv.dig('label', 'fr') }.compact_blank,
              '@default:short' => { 'fr-FR' => vv.dig('label_list', 'fr') }.compact_blank,
            }.compact_blank
          }
        }.compact_blank
      }
      load_i18n(conn, project_slug, i18ns)

      if datasources_slug.present?
        i18ns = fetch_json("#{datasource_url}/data/#{datasources_slug}/i18n.json")
        load_i18n(conn, project_slug, i18ns)
      end
    }

    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
