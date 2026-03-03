# frozen_string_literal: true
# typed: false

class DirectusGeomGpx < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      INSERT INTO public.directus_extensions (enabled, id, folder, source, bundle) VALUES
        (true, '87c3416a-0027-4123-89e2-3a17c283a36d', 'directus-extension-map-gpx', 'local', NULL)
      ;

      UPDATE
        directus_fields
      SET
        interface = 'map-gpx'
      WHERE
        collection LIKE 'local-%' AND
        field = 'geom'
      ;
    SQL
  end
end
