# frozen_string_literal: true

class StyleClass < ActiveRecord::Migration[7.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE menu_items ALTER COLUMN style_class DROP EXPRESSION;
      ALTER TABLE menu_items DROP COLUMN style_class_string CASCADE;
      ALTER TABLE menu_items ALTER COLUMN style_class TYPE jsonb USING array_to_json(style_class);

      UPDATE directus_fields
      SET
        hidden = false,
        interface = 'simple-list',
        options = '{"size":"small","limit":3}'::jsonb
      WHERE
        collection = 'menu_items' AND
        field = 'style_class'
      ;
    SQL
  end
end
