# frozen_string_literal: true

class FlatRefIndex < ActiveRecord::Migration[7.0]
  def change
    execute <<~SQL.squish
      CREATE OR REPLACE FUNCTION jsonb_to_text_array(j jsonb) RETURNS text[]
      AS $$
        SELECT array_agg(key || '=' || value) FROM jsonb_each_text(j)
      $$ LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE;

      CREATE INDEX pois_idx_ref_flat ON pois USING gin(jsonb_to_text_array(pois.properties->'tags'->'ref')) WHERE pois.properties->'tags' ? 'ref';
    SQL
  end
end
