# frozen_string_literal: true

class FilterFieldOptions < ActiveRecord::Migration[7.0]
  def change
    execute <<~SQL.squish
      UPDATE directus_fields
      SET
        options = '{"template":"{{field}}","filter":{"_and":[{"_and":[{"type":{"_eq":"field"}},{"project_id":{"_in":["$CURRENT_USER.project_id","{{project_id}}"]}}]}]}}'
      WHERE
        id = 553
      ;
    SQL
  end
end
