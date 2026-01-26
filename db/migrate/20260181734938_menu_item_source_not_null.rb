# frozen_string_literal: true
# typed: false

class MenuItemSourceNotNull < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      DELETE FROM menu_items_sources WHERE menu_items_id IS NULL OR sources_id IS NULL;
      ALTER TABLE menu_items_sources
        ALTER COLUMN menu_items_id SET NOT NULL,
        ALTER COLUMN sources_id SET NOT NULL;

      ALTER TABLE menu_items_sources ADD CONSTRAINT menu_items_sources_uniq_menu_items_id_sources_id UNIQUE (menu_items_id, sources_id);
    SQL
  end
end
