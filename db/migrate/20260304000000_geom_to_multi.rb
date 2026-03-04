# frozen_string_literal: true
# typed: false

class GeomToMulti < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      CREATE OR REPLACE FUNCTION pois_geom_multi() RETURNS TRIGGER AS $$
      BEGIN
        NEW.geom := ST_CollectionHomogenize(NEW.geom);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER pois_geom_multi_trigger
      BEFORE INSERT OR UPDATE OF geom ON pois
      FOR EACH ROW
      EXECUTE FUNCTION pois_geom_multi();
    SQL
  end
end
