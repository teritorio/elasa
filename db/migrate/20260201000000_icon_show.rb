# frozen_string_literal: true

class IconShow < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE menu_items ADD COLUMN icon_show varchar NOT NULL DEFAULT 'always';

      INSERT INTO directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message) VALUES
      (618, 'menu_items', 'icon_show', NULL, 'select-dropdown', '{"choices":[{"text":"always","value":"always","icon":"check_box"},{"text":"never","value":"never","icon":"check_box_outline_blank"}]}', NULL, NULL, false, false, 11, 'full', NULL, NULL, NULL, false, 'category', NULL, NULL);
    SQL
  end
end
