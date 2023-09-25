# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'
require 'pg'


def fetch_json(url)
  JSON.parse(HTTP.follow.get(url))
end

def load_source(conn, project_slug, metadatas)
  conn.exec("
    CREATE TEMP TABLE sources_import(
      slug varchar NOT NULL,
      name json NOT NULL, -- Tanslation Object.
      attribution text
    )
  ")

  enco = PG::BinaryEncoder::CopyRow.new
  conn.copy_data('COPY sources_import FROM STDIN (FORMAT binary)', enco) {
    metadatas.each{ |id, metadata|
      conn.put_copy_data([id, metadata['name'].to_json, metadata['attribution']])
    }
  }
  conn.exec_params(
    "
    WITH sources_import AS (
      SELECT
        projects.id AS project_id,
        sources_import.*
      FROM
        sources_import
        JOIN projects ON
          projects.slug = $1
    )
    MERGE INTO
      sources
    USING
      sources_import
    ON
      sources.project_id = sources_import.project_id AND
      sources.slug = sources_import.slug
    WHEN MATCHED THEN
      UPDATE SET
        name = sources_import.name,
        attribution = sources_import.attribution
    WHEN NOT MATCHED THEN
      INSERT (project_id, slug, name, attribution)
      VALUES (
        sources_import.project_id,
        sources_import.slug,
        sources_import.name,
        sources_import.attribution
      )
    ",
    [project_slug]
  )

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
      geometry json,
      properties json
    )
  ")

  enco = PG::BinaryEncoder::CopyRow.new
  conn.copy_data('COPY pois_import FROM STDIN (FORMAT binary)', enco) {
    pois.each{ |feature|
      conn.put_copy_data([feature['geometry'].to_json, feature['properties'].to_json])
    }
  }
  conn.exec_params(
    "
    WITH pois_import AS (
      SELECT
        sources.id AS source_id,
        pois_import.*,
        ST_GeomFromGeoJSON(geometry)::geometry(Geometry, 4326) AS geom
      FROM
        pois_import
        JOIN projects ON
          projects.slug = $1
        JOIN sources ON
          sources.project_id = projects.id AND
          sources.slug = $2
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
      INSERT (source_id, geom, properties)
      VALUES (
        pois_import.source_id,
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

def load_sources(datasource_url, project_slug)
  projects = fetch_json(datasource_url)

  projects.select{ |project| project_slug.nil? || project['name'] == project_slug }.each{ |project|
    project_slug = project['name']
    metadatas = fetch_json("#{datasource_url}/#{project_slug}/metadata.json")

    puts "== #{project_slug}: #{metadatas.size} =="

    # Output a table of current connections to the DB
    PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
      load_source(conn, project_slug, metadatas)

      metadatas.each{ |source_slug, _metadata|
        pois = fetch_json("#{datasource_url}/#{project_slug}/#{source_slug}.geojson")
        load_pois(conn, project_slug, source_slug, pois['features'])
        puts "#{project_slug}/#{source_slug}: #{pois['features'].size}"
      }
    }

    puts ''
  }
end

namespace :sources do
  desc 'Load Sources and POIs from datasource'
  task :load, [] => :environment do
    url_base, project_slug = ARGV[2..]
    load_sources("#{url_base}/data", project_slug)
    exit 0 # Beacause of manually deal with rake command line arguments
  end
end