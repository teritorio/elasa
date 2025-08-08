# frozen_string_literal: true

class ExtCalc < ActiveRecord::Migration[7.0]
  def change
    execute <<~SQL.squish
      INSERT INTO directus_extensions(enabled, id, folder, source, bundle)
      VALUES
        (true, 'd3a350fb-49a9-4f3a-9f1e-a4ba21e4b635'::uuid, 'baf4208a-aab1-496b-af15-05fa841a62a8'::uuid, 'registry', NULL)
      ;
    SQL
  end
end
