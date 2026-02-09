# frozen_string_literal: true
# typed: false

class FilterDate < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      UPDATE
        fields
      SET
        json_schema = '{"type":"object","additionalProperties":false,"properties":{"start_date":{"type":"string"},"end_date":{"type":"string"}}}'::jsonb
      WHERE
        field = 'start_end_date'
      ;

      UPDATE
        fields_translations
      SET
        name = 'date'
      FROM
        fields
      WHERE
        fields_translations.fields_id = fields.id AND
        field = 'start_end_date'
      ;

      UPDATE
        filters
      SET
        property_begin = fields.id
      FROM
        projects
        JOIN fields ON
          fields.project_id = projects.id AND
          fields.field = 'start_end_date'
      WHERE
        filters.property_begin IS NOT NULL
      ;
      ALTER TABLE filters RENAME COLUMN property_begin TO property_date;
      ALTER TABLE filters RENAME CONSTRAINT filters_property_begin_foreign TO filters_property_date_foreign;
      UPDATE directus_fields SET field = 'property_date' WHERE collection = 'filters' AND field = 'property_begin';
      UPDATE directus_relations SET many_field = 'property_date' WHERE many_collection = 'filters' AND many_field = 'property_begin';

      DELETE FROM fields WHERE field = 'end_date';
      ALTER TABLE filters DROP COLUMN property_end CASCADE;
      DELETE FROM directus_fields WHERE collection = 'filters' AND field = 'property_end';
      DELETE FROM directus_relations WHERE many_collection = 'filters' AND many_field = 'property_end';

      UPDATE directus_fields
      SET options = '{"search_config":{"_and":[{"_or":[{"filters_translations":{"name":{"_icontains":"$SEARCH"}}},{"checkboxes_list_property":{"fields_translations":{"name":{"_icontains":"$SEARCH"}}}},{"checkboxes_list_property":{"fields_translations":{"name":{"_icontains":"$SEARCH"}}}},{"property_date":{"fields_translations":{"name":{"_icontains":"$SEARCH"}}}},{"number_range_property":{"fields_translations":{"name":{"_icontains":"$SEARCH"}}}}]}]}}'
      WHERE id = 606;
    SQL
  end
end
