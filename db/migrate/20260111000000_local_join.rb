# frozen_string_literal: true

class LocalJoin < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE sources ADD COLUMN extends_source_id integer REFERENCES sources(id);

      INSERT INTO directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message)
      VALUES (617, 'sources', 'extends_source_id', NULL, 'select-dropdown-m2o', '{"filter":{"_and":[{"project_id":{"_eq":"{{project_id}}"}}]},"template":"{{slug}}","enableCreate":false}', 'related-values', '{"template":"{{slug}}"}', false, false, NULL, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL);
    SQL
  end
end
