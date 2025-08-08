# frozen_string_literal: true

class PoiCalculated < ActiveRecord::Migration[7.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE pois ADD COLUMN properties_id text GENERATED ALWAYS AS (properties->>'id') STORED;
      ALTER TABLE pois ADD COLUMN properties_tags_name text GENERATED ALWAYS AS (properties->'tags'->>'name') STORED;

      INSERT INTO directus_fields(id, collection, field)
      VALUES
        (588, 'pois', 'properties_id'),
        (589, 'pois', 'properties_tags_name')
      ;
    SQL
  end
end
