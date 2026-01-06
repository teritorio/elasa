# frozen_string_literal: true

class UniqOriginalId < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      WITH a AS (
        SELECT
          *
        FROM
          (
            SELECT
              projects.slug,
              sources.project_id,
              pois.slugs ->> 'original_id' as original_id,
              pois.id,
              rank() OVER (
                PARTITION BY
                  projects.slug,
                  sources.project_id,
                  pois.slugs ->> 'original_id'
                ORDER BY
                  pois.id
              ) AS rank
            FROM
              pois
              JOIN sources ON sources.id = pois.source_id
              JOIN projects ON projects.id = sources.project_id
            WHERE
              pois.slugs ->> 'original_id' IS NOT NULL
          )
        WHERE
          rank >= 2
        ORDER BY
          slug,
          id
        )
        UPDATE
          pois
        SET
          slugs = nullif(slugs::jsonb - 'original_id', '{}'::jsonb)
        FROM
          a
        WHERE
          pois.id = a.id
        ;
    SQL
  end
end
