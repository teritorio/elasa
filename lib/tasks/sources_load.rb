# frozen_string_literal: true
# typed: true

require 'json'
require 'http'
require 'pg'
require_relative 'commons'


# Back port from active_support
class String
  def slugify
    s = gsub(/\s+/, ' ')
    s.strip!
    s.gsub!(' ', '-')
    s.gsub!('&', 'and')
    s.gsub!(/[^\w-]/u, '')
    s.mb_chars.downcase.to_s
  end
end

def load_source(conn, project_slug, metadatas)
  conn.exec("
    CREATE TEMP TABLE sources_import_raw(
      slug varchar NOT NULL,
      name json NOT NULL, -- Tanslation Object.
      attribution text
    )
  ")

  enco = PG::BinaryEncoder::CopyRow.new
  conn.copy_data('COPY sources_import_raw FROM STDIN (FORMAT binary)', enco) {
    metadatas.each{ |id, metadata|
      conn.put_copy_data([
        id,
        metadata['name'].transform_keys{ |k| { 'fr' => 'fr-FR', 'en' => 'en-US' }[k] }.to_json,
        metadata['attribution']
      ])
    }
  }
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
      (SELECT DISTINCT project_id, slug, attribution FROM sources_import) AS sources_import
    ON
      sources.project_id = sources_import.project_id AND
      sources.slug = sources_import.slug
    WHEN MATCHED THEN
      UPDATE SET
        attribution = sources_import.attribution
    WHEN NOT MATCHED THEN
      INSERT (project_id, slug, attribution)
      VALUES (
        sources_import.project_id,
        sources_import.slug,
        sources_import.attribution
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

  conn.exec_params(
    "
    DELETE FROM
      sources
    USING
      sources AS self
      JOIN projects ON
        projects.slug = $1 AND
        projects.id = self.project_id
      LEFT JOIN sources_import ON
        sources_import.slug = self.slug
    WHERE
      sources.id = self.id AND
      sources_import.slug IS NULL
    ",
    [project_slug]
  )
end

def load_pois(conn, project_slug, source_slug, pois)
  conn.exec("
    DROP TABLE IF EXISTS pois_import;
    CREATE TEMP TABLE pois_import(
      slugs json,
      geometry json,
      properties json
    )
  ")

  enco = PG::BinaryEncoder::CopyRow.new
  conn.copy_data('COPY pois_import FROM STDIN (FORMAT binary)', enco) {
    pois.each{ |feature|
      slugs = feature.dig('properties', 'tags', 'name')&.transform_values(&:parameterize)
      conn.put_copy_data([slugs&.to_json, feature['geometry'].to_json, feature['properties'].to_json])
    }
  }
  conn.exec_params(
    "
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
    ",
    [project_slug, source_slug]
  )

  conn.exec_params(
    "
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
    ",
    [project_slug, source_slug]
  )
end

def load_from_source(datasource_url, project_slug, datasource_project)
  projects = fetch_json("#{datasource_url}.json")

  projects.select{ |project| datasource_project.nil? || project['name'] == datasource_project }.collect{ |_project|
    metadatas = fetch_json("#{datasource_url}/#{datasource_project}/metadata.json")

    puts "source #{project_slug} (#{metadatas.size})"

    # Output a table of current connections to the DB
    PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
      load_source(conn, project_slug, metadatas)

      metadatas.each_key{ |source_slug|
        pois = fetch_json("#{datasource_url}/#{datasource_project}/#{source_slug}.geojson")
        load_pois(conn, project_slug, source_slug, pois['features'])
        puts "#{project_slug}/#{source_slug}: #{pois['features'].size}"
      }
    }

    puts ''

    metadatas
  }
end

def load_i18n(project_slug, i18ns)
  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
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
          -- field_translations = translations_import.field_translations, -- field_translations is on join
          values_translations = translations_import.values_translations::json
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
  }
end
