# frozen_string_literal: true
# typed: false

class FilterOneProperty < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      DELETE FROM filters WHERE
        multiselection_property IS NULL AND
        checkboxes_list_property IS NULL AND
        boolean_property IS NULL AND
        property_date IS NULL AND
        number_range_property IS NULL;
      ALTER TABLE filters
        ADD COLUMN property integer REFERENCES fields(id) ON DELETE CASCADE;
      UPDATE filters SET property = coalesce(multiselection_property, checkboxes_list_property, boolean_property, property_date, number_range_property);
      ALTER TABLE filters
        ALTER COLUMN property SET NOT NULL,
        DROP COLUMN multiselection_property CASCADE,
        DROP COLUMN checkboxes_list_property CASCADE,
        DROP COLUMN boolean_property CASCADE,
        DROP COLUMN property_date CASCADE,
        DROP COLUMN number_range_property CASCADE
      ;

      DELETE FROM directus_fields WHERE id in (88, 114, 115, 116, 554, 555, 556, 558);
      UPDATE directus_fields
      SET
        field = 'property',
        options = '{"template":"{{field}}","filter":{"_and":[{"_and":[{"type":{"_eq":"field"}},{"project_id":{"_eq":"{{project_id}}"}}]}]}}'
      WHERE
        id = 553
      ;

      DELETE FROM directus_relations WHERE id in (66, 67, 68, 70);
      UPDATE directus_relations SET many_field = 'property' WHERE id = 65;
    SQL
  end
end
