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
        ADD COLUMN field_id integer REFERENCES fields(id) ON DELETE CASCADE;

      UPDATE filters SET field_id = coalesce(multiselection_property, checkboxes_list_property, boolean_property, property_date, number_range_property);

      -- Deduplicate filters
      CREATE TEMP TABLE filters_id AS
      SELECT
        filters.project_id,
        field_id,
        min(filters.id) AS min_filter_id,
        array_agg(filters.id) AS filter_ids
      FROM
        filters
        JOIN fields ON
          filters.field_id = fields.id
      GROUP BY
        filters.project_id,
        field_id,
        field
      HAVING count(*) > 1
      ;
      UPDATE
        menu_items_filters
      SET
        filters_id = filters_id.min_filter_id
      FROM
        filters_id
      WHERE
        menu_items_filters.filters_id = ANY(filters_id.filter_ids)
      ;
      DELETE FROM
        filters
      USING
        filters_id
      WHERE
        filters.id = ANY(filters_id.filter_ids) AND
        filters.id != filters_id.min_filter_id
      ;

      ALTER TABLE filters
        ALTER COLUMN field_id SET NOT NULL,
        ADD CONSTRAINT filters_uniq_project_id_property UNIQUE(project_id, field_id),
        DROP COLUMN multiselection_property CASCADE,
        DROP COLUMN checkboxes_list_property CASCADE,
        DROP COLUMN boolean_property CASCADE,
        DROP COLUMN property_date CASCADE,
        DROP COLUMN number_range_property CASCADE
      ;

      DELETE FROM directus_fields WHERE id in (88, 114, 115, 116, 554, 555, 556, 558);
      UPDATE directus_fields
      SET
        field = 'field_id',
        options = '{"template":"{{field}}","filter":{"_and":[{"_and":[{"type":{"_eq":"field"}},{"project_id":{"_eq":"{{project_id}}"}}]}]}}'
      WHERE
        id = 553
      ;

      DELETE FROM directus_relations WHERE id in (66, 67, 68, 70);
      UPDATE directus_relations SET many_field = 'field_id' WHERE id = 65;
    SQL
  end
end
