# frozen_string_literal: true
# typed: false

class FilterDate < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      DELETE FROM fields where field = 'start_end_date';
      UPDATE
        fields
      SET
        field = 'start_end_date',
        json_schema = '{"type":"object","additionalProperties":false,"properties":{"start_date":{"type":"string"},"end_date":{"type":"string"}}}'::jsonb
      WHERE
        field = 'start_date'
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

      ALTER TABLE filters RENAME COLUMN property_begin TO property_date;
      UPDATE directus_fields SET field = 'property_date' WHERE collection = 'filters' AND field = 'property_begin';

      DELETE FROM fields WHERE field = 'end_date';
      ALTER TABLE filters DROP COLUMN property_end CASCADE;
      DELETE FROM directus_fields WHERE collection = 'filters' AND field = 'property_end';
    SQL
  end
end
