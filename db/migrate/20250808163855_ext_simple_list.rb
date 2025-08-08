# frozen_string_literal: true

class ExtSimpleList < ActiveRecord::Migration[7.0]
  def change
    execute <<~SQL.squish
      INSERT INTO directus_extensions(enabled, id, folder, source, bundle)
      VALUES
        (true, 'bfa185ec-f15c-4d3e-8e0e-06925ba6cdfe'::uuid, '3b80b125-4f65-4a6f-96c6-4ede2ed9f506'::uuid, 'registry', NULL)
      ;

      UPDATE directus_fields
      SET
          interface = 'simple-list',
          options = '{"size":"small"}'::jsonb
      FROM
          information_schema.columns AS c,
          information_schema.tables AS t
      WHERE
          c.table_schema = t.table_schema AND
          c.table_name = t.table_name AND
          c.data_type = 'jsonb' AND
          t.table_type = 'BASE TABLE' AND
          directus_fields.collection = t.table_name AND
          directus_fields.field = c.column_name
      ;
    SQL
  end
end
