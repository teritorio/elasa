# frozen_string_literal: true
# typed: false

class NoGeomCollection < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE pois ADD CONSTRAINT pois_geom_not_collection CHECK (
        geometrytype(geom) IN (
          'POINT', 'MULTIPOINT',
          'LINESTRING', 'MULTILINESTRING',
          'POLYGON', 'MULTIPOLYGON'
        )
      );
    SQL
  end
end
