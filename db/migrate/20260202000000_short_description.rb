# frozen_string_literal: true
# typed: false

class ShortDescription < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      UPDATE fields_fields
      SET related_fields_id = description.id
      FROM
        fields AS groups
        JOIN fields AS short_description ON
          short_description.field = 'short_description'
        JOIN projects ON
          projects.id = groups.project_id
        JOIN fields AS description ON
          description.project_id = projects.id AND
          description.field = 'description'
        LEFT JOIN fields_fields AS existing ON
          existing.related_fields_id = description.id AND
          existing.fields_id = groups.id
      WHERE
        groups.id = fields_fields.fields_id AND
        short_description.id = fields_fields.related_fields_id AND
        existing.fields_id IS NULL
      ;

      DELETE FROM fields WHERE field = 'short_description';
    SQL
  end
end
