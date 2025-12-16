# frozen_string_literal: true

class FieldArray < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE fields ADD COLUMN "array" boolean;

      INSERT INTO directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message) VALUES
      (615, 'fields', 'array', NULL, 'boolean', NULL, NULL, NULL, false, false, 4, 'full', NULL, NULL, NULL, false, 'field_block', NULL, NULL)
      ;

      UPDATE directus_fields SET sort = 5 WHERE id = 613;
      UPDATE directus_fields SET sort = 6 WHERE id = 614;
    SQL
  end
end
