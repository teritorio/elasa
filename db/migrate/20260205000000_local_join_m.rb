# frozen_string_literal: true
# typed: false

require 'http'

class LocalJoinM < ActiveRecord::Migration[8.0]
  def change
    bearer = ENV.fetch('DIRECTUS_ADMIN_BEARER', nil)
    raise 'Missing Direcuts admin bearer tocken in DIRECTUS_ADMIN_BEARER to run this migration' if bearer.blank?

    db = PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres')

    sources = db.transaction { |conn|
      sql = <<~SQL.squish
        WITH sources AS (
          SELECT
            sources.id,
            sources.project_id,
            min(projects.slug) AS project_slug,
            sources.slug,
            sources.attribution,
            bool_or(website_details is not null) as website_details,
            bool_or(pois_files.pois_id is not null) as files
          FROM
            pois
            JOIN sources ON
              sources.id = pois.source_id
            JOIN projects ON
              projects.id = sources.project_id
            LEFT JOIN pois_files ON
              pois_files.pois_id = pois.id
          WHERE
            website_details IS NOT NULL OR
            pois_files.pois_id IS NOT NULL
          GROUP BY
            sources.id
        )
        SELECT
          sources.*,
          tables.table_name IS NOT NULL AND columns.table_name IS NULL AS source_already_exists_without_extends_poi
        FROM
          sources
          LEFT JOIN information_schema.tables ON
            tables.table_name = substring(project_slug || '-' || slug, 1, 63)
          LEFT JOIN information_schema.columns ON
            columns.table_schema = tables.table_schema AND
            columns.table_name = tables.table_name AND
            columns.column_name = 'extends_poi_id'
        WHERE
          website_details OR (files AND columns.table_name IS NOT NULL)
        ORDER BY
          project_slug,
          slug
      SQL
      sources = conn.exec_params(sql) { |results|
        results.collect(&:to_h)
      }

      sources.collect{ |row|
        next row if row['source_already_exists_without_extends_poi'] == 't'

        row['source_extend_id'] = conn.exec_params('
          MERGE INTO sources
          USING (SELECT $1::integer, $2, $3, $4::integer) AS up(project_id, slug, attribution, extends_source_id)
          ON (up.project_id = sources.project_id AND up.slug = sources.slug)
          WHEN NOT MATCHED THEN
            INSERT (project_id, slug, attribution, extends_source_id)
            VALUES (project_id, slug, attribution, extends_source_id)
          WHEN MATCHED THEN
            UPDATE SET
              attribution = up.attribution,
              extends_source_id = up.extends_source_id
          RETURNING id', [
            row['project_id'], "ext_#{row['slug']}", row['attribution'], row['id']
        ]){ |result|
          result.first['id'].to_i
        }
        conn.exec_params('
          MERGE INTO sources_translations
          USING (
            SELECT $2::integer, languages_code, name
            FROM sources_translations
            WHERE sources_id = $1::integer
          ) AS up(sources_id, languages_code, name)
          ON (up.sources_id = sources_translations.sources_id AND up.languages_code = sources_translations.languages_code)
          WHEN NOT MATCHED THEN
            INSERT (sources_id, languages_code, name)
            VALUES (sources_id, languages_code, name)
          WHEN MATCHED THEN
            UPDATE SET
            name = up.name
          ', [
            row['id'], row['source_extend_id']
        ])

        row
      }
    }

    sources.each_with_index{ |row, index|
      local_ext = "local-#{row['project_slug']}-ext_#{row['slug']}"[..62]
      puts "Create locale join table for #{local_ext} (#{index}/#{sources.size})"

      response = HTTP.auth("Bearer #{bearer}").post(
        'http://directus:8055/flows/trigger/96ccf7a5-8702-4760-8c9e-b53267f234b2',
        json: {
          collection: 'sources',
          keys: [row['source_extend_id'] || row['id']],
          withWebsiteDetails: row['website_details'] == 't',
          withImages: row['files'] == 't',
        }
      )
      puts response.status
      raise response if !response.status.success?

      db.transaction { |conn|
        if row['website_details'] == 't'
          local_ext_t = "#{local_ext[..(62 - 2)]}_t"
          sql = "
            MERGE INTO \"#{local_ext_t}\" AS t
            USING (
              SELECT
                l.id,
                pois.website_details
              FROM
                \"#{local_ext}\" AS l
                JOIN pois ON
                  pois.id = l.extends_poi_id
            ) AS l
            ON (t.pois_id = l.id AND t.languages_code = 'fr-FR')
            WHEN NOT MATCHED THEN
              INSERT (pois_id, languages_code, website___details)
              VALUES (l.id, 'fr-FR', l.website_details)
            WHEN MATCHED THEN
              UPDATE SET
                website___details = l.website_details
          "
          conn.exec_params(sql)
        end

        if row['files'] == 't' && row['source_already_exists_without_extends_poi'] == 'f'
          local_ext_i = "#{local_ext[..(62 - 2)]}_i"
          sql = "
            INSERT INTO \"#{local_ext_i}\"(pois_id, directus_files_id, index)
            SELECT
              l.id,
              directus_files_id,
              index
            FROM
              pois_files
              JOIN pois ON
                pois.source_id = $1 AND
                pois.id = pois_files.pois_id
              JOIN \"#{local_ext}\" AS l ON
                l.extends_poi_id = pois.id
          "
          conn.exec_params(sql, [row['id']])
        end

        conn.exec_params('UPDATE menu_items_sources SET sources_id = $2 WHERE sources_id = $1', [row['id'], row['source_extend_id']])
        conn.exec_params('UPDATE api02.pois_property_values SET source_id = $2 WHERE source_id = $1', [row['id'], row['source_extend_id']])
      }
    }

    execute <<~SQL.squish
      ALTER TABLE pois DROP COLUMN website_details CASCADE;
      DELETE FROM directus_fields WHERE collection = 'pois' AND field IN ('website_details', 'override');

      UPDATE directus_fields
      SET
        options = '{"template":"{{directus_files_id.$thumbnail}} {{directus_files_id.title}}","enableCreate":false,"enableSelect":false}',
        readonly = true,
        sort = 6,
        "group" = NULL
      WHERE id = 536;

      UPDATE directus_flows
      SET options = '{"collections":["sources"],"requireConfirmation":true,"fields":[{"field":"withImages","type":"boolean","name":"With Images","meta":{"interface":"boolean","width":"half"}},{"field":"withThumbnail","type":"boolean","name":"With Thumbnail","meta":{"interface":"boolean","options":{"iconOn":"image_search"},"width":"half"}},{"field":"withName","type":"boolean","name":"With Name","meta":{"interface":"boolean","width":"half"}},{"field":"withDescription","type":"boolean","name":"With Description","meta":{"interface":"boolean","width":"half"}},{"field":"withAddr","type":"boolean","name":"Add addr:* fields","meta":{"interface":"boolean","width":"half"}},{"field":"withContact","type":"boolean","name":"Add contact:* fields","meta":{"interface":"boolean","width":"half"}},{"field":"withWebsiteDetails","type":"boolean","name":"With website:details","meta":{"interface":"boolean"}},{"field":"withColors","type":"boolean","name":"withColors","meta":{"interface":"boolean"}},{"field":"withDeps","type":"boolean","name":"Add link to other objects","meta":{"interface":"boolean","width":"half"}},{"field":"withWaypoints","type":"boolean","name":"Add waypoints","meta":{"interface":"boolean","width":"half"}}]}'
      where id = '96ccf7a5-8702-4760-8c9e-b53267f234b2';

      DO $$
      DECLARE
        wd RECORD;
      BEGIN
        FOR wd IN
          SELECT
            tables.table_name,
            columns.column_name,
            t.table_name AS t_table_name
          FROM
            projects
            JOIN sources ON
              sources.project_id = projects.id
            JOIN information_schema.tables ON
              tables.table_name = substring('local-' || projects.slug || '-' || sources.slug, 1, 63)
            JOIN information_schema.columns ON
              columns.table_schema = tables.table_schema AND
              columns.table_name = tables.table_name AND
              columns.column_name = 'website___details'
            LEFT JOIN information_schema.tables AS t ON
              t.table_name = substring('local-' || projects.slug || '-' || sources.slug, 1, 63 - 2) || '_t'
        LOOP
          RAISE NOTICE 'Migrating website___details from % to %', wd.table_name, wd.t_table_name;
          EXECUTE 'UPDATE directus_fields SET collection = ''' || wd.t_table_name || ''' WHERE collection = ''' || wd.table_name || ''' AND field = ''website___details''';
          EXECUTE 'ALTER TABLE "' || wd.t_table_name || '" ADD COLUMN website___details varchar';
          EXECUTE '
            UPDATE "' || wd.t_table_name || '"
            SET website___details = t.website___details
            FROM "' || wd.table_name || '" AS t
            WHERE t.id = "' || wd.t_table_name || '".pois_id
          ';
          EXECUTE 'ALTER TABLE "' || wd.table_name || '" DROP COLUMN website___details';
        END LOOP;
      END; $$;
    SQL
  end
end
