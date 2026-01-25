# frozen_string_literal: true
# typed: false

class MenuItemFilterNotNull < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      DELETE FROM menu_items_filters WHERE menu_items_id IS NULL OR filters_id IS NULL;
      ALTER TABLE menu_items_filters
        ALTER COLUMN menu_items_id SET NOT NULL,
        ALTER COLUMN filters_id SET NOT NULL;

      ALTER TABLE menu_items_filters ADD CONSTRAINT menu_items_filters_uniq_menu_items_id_index UNIQUE (menu_items_id, index);
    SQL
  end
end
