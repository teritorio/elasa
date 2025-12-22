# frozen_string_literal: true

class FieldJsonSchema < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE fields ADD COLUMN json_schema jsonb;

      INSERT INTO directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message) VALUES
      (616, 'fields', 'array', NULL, 'boolean', NULL, NULL, NULL, false, false, 4, 'full', NULL, NULL, NULL, false, 'field_block', NULL, NULL)
      ;

    SQL
  end
end
