# frozen_string_literal: true
# typed: false

class DirectusExtentions < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      UPDATE directus_extensions
      SET
        folder = 'directus-extension-computed-interface',
        source = 'local'
      WHERE
        id = 'd3a350fb-49a9-4f3a-9f1e-a4ba21e4b635'
      ;

      UPDATE directus_extensions
      SET
        folder = 'simple-list-interface',
        source = 'local'
      WHERE
        id = 'bfa185ec-f15c-4d3e-8e0e-06925ba6cdfe'
      ;

      UPDATE directus_extensions
      SET
        folder = 'directus-extension-m2o-presentation-interface',
        source = 'local'
      WHERE
        id = '2dc2e66e-5625-4c84-bf4d-0e76174739f9'
      ;
    SQL
  end
end
