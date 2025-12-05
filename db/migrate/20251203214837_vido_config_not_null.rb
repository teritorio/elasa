# frozen_string_literal: true

class VidoConfigNotNull < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE themes
        ALTER COLUMN map_style_base_url SET NOT NULL,
        ALTER COLUMN map_style_satellite_url SET NOT NULL
      ;
    SQL
  end
end
