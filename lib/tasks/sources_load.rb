# frozen_string_literal: true
# typed: true

require 'json'
require 'httpx'
require 'pg'
require 'i18n'
require_relative 'commons'

def fetch_all_json(urls)
  responses = HTTPX.get(*urls)
  urls.zip(responses).collect { |url, response|
    raise "[ERROR] #{url} => #{response.status}" if response.status != 200

    JSON.parse(response)
  }
end

# Back port from active_support
class String
  def slugify
    s = gsub(/\s+/, ' ')
    s.strip!
    s.gsub!(' ', '-')
    s.gsub!('&', 'and')
    s = I18n.transliterate(s)
    s.gsub!(/[^\w-]/u, '')
    s.gsub!(/-+/, '-')
    s.mb_chars.downcase.to_s
  end
end

def update_filter_cache(conn, project_slug, source_slug)
  conn.exec_params('SET search_path TO api02,public;')
  conn.exec_params("
    DELETE FROM
      pois_property_values
    USING
        projects
        JOIN sources ON
            sources.project_id = projects.id
    WHERE
        ($1::text IS NULL OR projects.slug = $1) AND
        ($2::text IS NULL OR sources.slug = $2) AND
        pois_property_values.project_id = projects.id AND
        pois_property_values.source_id = sources.id
  ", [project_slug, source_slug])
  conn.exec_params("
    INSERT INTO pois_property_values
    SELECT DISTINCT ON (t.project_id, t.source_id, fields.id)
        t.project_id,
        t.source_id,
        fields.id,
        t.property_values
    FROM
        projects
        JOIN sources ON
            sources.project_id = projects.id
        JOIN filters ON
            filters.project_id = projects.id
        JOIN fields ON
            fields.id = coalesce(multiselection_property, checkboxes_list_property, boolean_property)
        JOIN LATERAL pois_property_extract_values(projects.id, sources.id, fields.field) AS t ON true
    WHERE
        ($1::text IS NULL OR projects.slug = $1) AND
        ($2::text IS NULL OR sources.slug = $2)
    ORDER BY
        t.project_id,
        t.source_id,
        fields.id
  ", [project_slug, source_slug])
  conn.exec_params('SET search_path TO public;')
end

def load_source(conn, project_slug, metadatas)
  conn.exec('DROP TABLE IF EXISTS sources_import_raw')
  conn.exec("
    CREATE TEMP TABLE sources_import_raw(
      slug varchar NOT NULL,
      name json NOT NULL, -- Tanslation Object.
      attribution text,
      report_issue text
    )
  ")

  enco = PG::BinaryEncoder::CopyRow.new
  conn.copy_data('COPY sources_import_raw FROM STDIN (FORMAT binary)', enco) {
    metadatas.each{ |id, metadata|
      conn.put_copy_data([
        id,
        metadata['name']&.to_json,
        metadata['attribution'],
        metadata['report_issue']&.to_json,
      ])
    }
  }
  conn.exec('DROP TABLE IF EXISTS sources_import')
  conn.exec_params("
    CREATE TEMP TABLE sources_import AS (
      SELECT
        projects.id AS project_id,
        sources_import_raw.*
      FROM
        sources_import_raw
        JOIN projects ON
          projects.slug = $1
    )
  ", [project_slug])

  conn.exec_params("
    MERGE INTO
      sources
    USING
      (SELECT DISTINCT project_id, slug, attribution, report_issue FROM sources_import) AS sources_import
    ON
      sources.project_id = sources_import.project_id AND
      sources.slug = sources_import.slug
    WHEN MATCHED THEN
      UPDATE SET
        attribution = sources_import.attribution,
        report_issue = sources_import.report_issue::jsonb
    WHEN NOT MATCHED THEN
      INSERT (project_id, slug, attribution, report_issue)
      VALUES (
        sources_import.project_id,
        sources_import.slug,
        sources_import.attribution,
        sources_import.report_issue::jsonb
      )
  ")

  conn.exec_params("
    MERGE INTO
      sources_translations
    USING (
      SELECT
        sources.id AS sources_id,
        sources.slug,
        (json_each_text(name)).key AS lang,
        (json_each_text(name)).value AS name
      FROM
        sources
        JOIN sources_import ON
          sources.project_id = sources_import.project_id AND
          sources.slug = sources_import.slug
    ) AS sources_import
    ON
      sources_translations.sources_id = sources_import.sources_id AND
      sources_translations.languages_code = sources_import.lang
    WHEN MATCHED THEN
      UPDATE SET
        name = sources_import.name
    WHEN NOT MATCHED THEN
      INSERT (sources_id, languages_code, name)
      VALUES (
        sources_id,
        sources_import.lang,
        sources_import.name
      )
  ")

  conn.exec_params("
    DELETE FROM
      sources
    USING
      sources AS self
      JOIN projects ON
        projects.slug = $1 AND
        projects.id = self.project_id
      LEFT JOIN sources_import ON
        sources_import.slug = self.slug
      LEFT JOIN information_schema.tables ON
        tables.table_name = 'local-#{project_slug}-' || self.slug
    WHERE
      sources.id = self.id AND
      sources_import.slug IS NULL AND
      tables.table_name IS NULL
    ", [project_slug])
end

def load_pois(conn, project_slug, source_slug, pois)
  conn.exec("
    DROP TABLE IF EXISTS pois_import;
    CREATE TEMP TABLE pois_import(slugs json, geometry json, properties json);
  ")

  enco = PG::BinaryEncoder::CopyRow.new
  conn.copy_data('COPY pois_import FROM STDIN (FORMAT binary)', enco) {
    pois.each{ |feature|
      slugs = feature.dig('properties', 'tags', 'name')&.transform_values(&:parameterize)

      route = feature.dig('properties', 'tags', 'route')
      if !route.nil?
        pdfs = feature['properties']['tags']['route']['pdf'] || { 'fr-FR' => nil }
        feature['properties']['tags']['route'] = pdfs.to_h{ |lang, url|
          feature['properties']['tags']['route']['pdf'] = url
          [
            lang,
            feature['properties']['tags']['route'].dup
          ]
        }.compact
      end

      start_date = feature.dig('properties', 'tags').delete('start_date')
      end_date = feature.dig('properties', 'tags').delete('end_date')
      if !start_date.nil? || !end_date.nil?
        feature['properties']['tags']['start_end_date'] = {
          'start_date' => start_date,
          'end_date' => end_date
        }.compact
      end

      feature['properties']['tags'] = feature['properties']['tags'].compact

      conn.put_copy_data([slugs&.to_json, feature['geometry'].to_json, feature['properties'].to_json])
    }
  }
  conn.exec_params("
    WITH pois_import AS (
      SELECT DISTINCT ON (sources.id, pois_import.properties->>'id')
        sources.id AS source_id,
        pois_import.*,
        ST_Force2D(ST_GeomFromGeoJSON(geometry))::geometry(Geometry, 4326) AS geom
      FROM
        pois_import
        JOIN projects ON
          projects.slug = $1
        JOIN sources ON
          sources.project_id = projects.id AND
          sources.slug = $2
      ORDER BY
        sources.id,
        pois_import.properties->>'id'
    )
    MERGE INTO
      pois
    USING
      pois_import
    ON
      pois.source_id = pois_import.source_id AND
      pois.properties->>'id' = pois_import.properties->>'id'
    WHEN MATCHED THEN
      UPDATE SET
        geom = pois_import.geom,
        properties = pois_import.properties
    WHEN NOT MATCHED THEN
      INSERT (source_id, slugs, geom, properties)
      VALUES (
        pois_import.source_id,
        pois_import.slugs,
        pois_import.geom,
        pois_import.properties
      )
    ", [project_slug, source_slug])

  conn.exec_params("
    DELETE FROM
      pois
    USING
      pois AS self
      JOIN projects ON
        projects.slug = $1
      JOIN sources ON
        sources.project_id = projects.id AND
        sources.slug = $2
      LEFT JOIN pois_import ON
        pois_import.properties->>'id' = self.properties->>'id'
    WHERE
      pois.id = self.id AND
      pois.source_id = sources.id AND
      pois_import.properties IS NULL
    ", [project_slug, source_slug])

  conn.exec_params("
    SELECT
      api01.fill_pois_local_join(projects.id, sources.id, substring('local-' || projects.slug || '-' || sources.slug, 1, 63))
    FROM
      projects
      JOIN sources ON
        sources.project_id = projects.id AND
        sources.slug = $2 AND
        sources.extends_source_id IS NOT NULL
    WHERE
      projects.slug = $1
    ", [project_slug, source_slug])

  update_filter_cache(conn, project_slug, source_slug)
end

def load_from_source(con, datasource_url, project_slug, datasource_project)
  con.transaction{ |conn|
    conn.exec_params(
      "
      DELETE FROM
        pois_pois
      USING
        projects
        JOIN sources ON
          sources.project_id = projects.id
        JOIN pois ON
          pois.source_id = sources.id
      WHERE
        projects.slug = $1 AND
        pois_pois.parent_pois_id = pois.id
      ",
      [project_slug]
    )

    metadatas = fetch_json("#{datasource_url}/#{datasource_project}/metadata.json")

    puts "source #{project_slug} (#{metadatas.size})"

    load_source(conn, project_slug, metadatas)

    source_slugs = metadatas.keys
    source_urls = source_slugs.collect{ |source_slug| "#{datasource_url}/#{datasource_project}/#{source_slug}.geojson" }
    source_slugs.zip(fetch_all_json(source_urls)).each{ |source_slug, pois|
      load_pois(conn, project_slug, source_slug, pois['features'])
      puts "#{project_slug}/#{source_slug}: #{pois['features'].size}"
    }
    puts ''

    conn.exec_params(
      "
      INSERT INTO
        pois_pois(parent_pois_id, children_pois_id, index)
      SELECT
        parent_pois.id AS parent_pois_id,
        children_pois.id AS children_pois_id,
        index
      FROM
        projects
        JOIN sources ON
          sources.project_id = projects.id
        JOIN pois AS parent_pois ON
          parent_pois.source_id = sources.id
        JOIN LATERAL jsonb_array_elements(parent_pois.properties->'refs') WITH ORDINALITY AS parent_pois_refs(ref, index) ON true
        JOIN sources AS children_sources ON
          children_sources.project_id = projects.id
        JOIN pois AS children_pois ON
          children_pois.source_id = children_sources.id AND
          children_pois.properties->'id' = parent_pois_refs.ref
      WHERE
          projects.slug = $1
      ",
      [project_slug]
    )

    conn.exec_params('SELECT * FROM api01.force_update_project_pois_local($1)', [project_slug])

    metadatas
  }
end

def load_i18n(con, project_slug, i18ns)
  con.transaction{ |conn|
    puts "i18n: #{i18ns.size}"
    conn.exec("
      DROP TABLE IF EXISTS translations_import;
      CREATE TEMP TABLE translations_import(
        field text,
        field_translations text,
        values_translations text
      )
    ")

    enco = PG::BinaryEncoder::CopyRow.new
    conn.copy_data('COPY translations_import FROM STDIN (FORMAT binary)', enco) {
      i18ns.each{ |key, i18n|
        conn.put_copy_data([key, i18n.except('values').to_json, i18n['values']&.to_json])
      }
    }
    conn.exec_params(
      "
      WITH translations_import AS (
        SELECT
          projects.id AS project_id,
          translations_import.*
        FROM
          translations_import
          JOIN projects ON
            projects.slug = $1
      )
      MERGE INTO
        fields
      USING
        translations_import
      ON
        fields.project_id = translations_import.project_id AND
        fields.field = translations_import.field
      WHEN MATCHED THEN
        UPDATE SET
          values_translations = (coalesce(fields.values_translations, '{}'::json)::jsonb || translations_import.values_translations::jsonb)::json
      WHEN NOT MATCHED THEN
        INSERT (project_id, type, field, values_translations)
        VALUES (
          translations_import.project_id,
          'field',
          translations_import.field,
          translations_import.values_translations::json
        )
      ",
      [project_slug]
    )
    conn.exec_params(
      "
      WITH translations_import AS (
        SELECT
          fields.id AS field_id,
          translations_import.field_translations::json->'@default'->>'fr-FR' as field_translations
        FROM
          translations_import
          JOIN projects ON
            projects.slug = $1
          LEFT JOIN fields ON
            fields.project_id = projects.id AND
            fields.field = translations_import.field
        WHERE
          translations_import.field_translations::json->'@default'->>'fr-FR' IS NOT NULL
      )
      MERGE INTO
        fields_translations
      USING
        translations_import
      ON
        fields_translations.fields_id = translations_import.field_id AND
        fields_translations.languages_code = 'fr-FR'
      WHEN MATCHED THEN
        UPDATE SET
          name = translations_import.field_translations
      WHEN NOT MATCHED THEN
        INSERT (fields_id, languages_code, name)
        VALUES (
          translations_import.field_id,
          'fr-FR',
          translations_import.field_translations
        )
      ",
      [project_slug]
    )
  }
end

SCHEMA_MULTILINGUAL_ROUTE = {
  'type' => 'object',
  'additionalProperties' => {
    'type' => 'object',
    'properties' => {
        'gpx_trace' => {
            'type' => 'string'
        },
        'pdf' => {
            'type' => 'string'
        },
        'waypoint:type' => {
            enum: %w[
                parking
                start
                end
                waypoint
            ]
        }
    },
    'additionalProperties' => {
        'type' => 'object',
        'additionalProperties' => false,
        'properties' => {
            'difficulty' => {
                'enum' => %w[
                    easy
                    normal
                    hard
                ]
            },
            'duration' => {
                'title' => 'Duration in minutes',
                'type' => 'number'
            },
            'length' => {
                'title' => 'Length in kilometer',
                'type' => 'number'
            }
        }
    }

  }
}.freeze

def load_schema(con, project_slug, schemas)
  return if schemas['properties'].blank?

  con.transaction{ |conn|
    puts "schema: #{schemas['properties'].size}"
    conn.exec("
      DROP TABLE IF EXISTS schemas_import;
      CREATE TEMP TABLE schemas_import(
        field text,
        multilingual text,
        \"array\" text,
        media_type varchar,
        role varchar,
        json_schema text
      )
    ")

    schemas['$defs'] ||= {}
    schemas['$defs']['multilingual-route'] = SCHEMA_MULTILINGUAL_ROUTE
    schemas['$defs']['start_end_date'] = { type: 'object', additionalProperties: false, properties: { start_date: { type: 'string' }, end_date: { type: 'string' } } }
    enco = PG::BinaryEncoder::CopyRow.new
    conn.copy_data('COPY schemas_import FROM STDIN (FORMAT binary)', enco) {
      if schemas['properties'].key?('start_date') || schemas['properties'].key?('end_date')
        schemas['properties'].delete('start_date')
        schemas['properties'].delete('end_date')
        schemas['properties']['start_end_date'] = { '$ref' => '#/$defs/start_end_date' }
      end

      schemas['properties'].each{ |key, schema|
        item = schema
        item = { '$ref' => '#/$defs/multilingual-route' } if key == 'route'
        item = item['items'] if item['type'] == 'array'
        json_schema = item['$ref'].nil? ? item : schemas.dig(*item['$ref'][2..].split('/'))
        conn.put_copy_data([
          key,
          (item['$ref']&.start_with?('#/$defs/multilingual') || false).to_s,
          (schema['type'] == 'array').to_s,
          item['contentMediaType'],
          item['xContentRole'],
          json_schema.to_json
        ])
      }
    }
    conn.exec_params(
      "
      WITH schemas_import AS (
        SELECT
          projects.id AS project_id,
          schemas_import.*
        FROM
        schemas_import
          JOIN projects ON
            projects.slug = $1
      )
      MERGE INTO
        fields
      USING
      schemas_import
      ON
        fields.project_id = schemas_import.project_id AND
        fields.field = schemas_import.field
      WHEN MATCHED THEN
        UPDATE SET
          multilingual = schemas_import.multilingual::boolean,
          \"array\" = schemas_import.\"array\"::boolean,
          media_type = schemas_import.media_type,
          role = schemas_import.role,
          json_schema = schemas_import.json_schema::jsonb
      -- WHEN NOT MATCHED THEN -- Only if already exists
      ",
      [project_slug]
    )
  }
end
