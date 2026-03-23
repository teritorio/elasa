# frozen_string_literal: true

class DirectusFieldsOptions < ActiveRecord::Migration[7.0]
  def change
    execute <<~SQL.squish
      UPDATE directus_fields
      SET
        options = '{"template":"{{sources_id.slug}}","enableLink":true,"filter":{"_and":[{"project_id":{"_in":["$CURRENT_USER.project_id","{{project_id}}"]}}]}}'
      WHERE
        id = 74
      ;
      UPDATE directus_fields
      SET
        options = '{"filter":{"_and":[{"project_id":{"_in":["$CURRENT_USER.project_id","{{project_id}}"]}}]}}'
      WHERE
        id = 107
      ;
      UPDATE directus_fields
      SET
        options = '{"template":"{{related_fields_id.type}} {{related_fields_id.field}}{{related_fields_id.group}}","enableLink":true,"limit":100,"filter":{"_and":[{"project_id":{"_in":["$CURRENT_USER.project_id","{{project_id}}"]}}]}}'
      WHERE
        id = 144
      ;
      UPDATE directus_fields
      SET
        options = '{"template":"{{type}}{{field}}{{group}}","filter":{"_and":[{"type":{"_eq":"group"}},{"project_id":{"_in":["$CURRENT_USER.project_id","{{project_id}}"]}}]}}'
      WHERE
        id = 149
      ;
      UPDATE directus_fields
      SET
        options = '{"template":"{{type}}{{field}}{{group}}","filter":{"_and":[{"type":{"_eq":"group"}},{"project_id":{"_in":["$CURRENT_USER.project_id","{{project_id}}"]}}]}}'
      WHERE
        id = 150
      ;
      UPDATE directus_fields
      SET
        options = '{"template":"{{type}}{{field}}{{group}}","filter":{"_and":[{"type":{"_eq":"group"}},{"project_id":{"_in":["$CURRENT_USER.project_id","{{project_id}}"]}}]}}'
      WHERE
        id = 151
      ;
      UPDATE directus_fields
      SET
        options = '{"filter":{"_and":[{"project_id":{"_in":["$CURRENT_USER.project_id","{{project_id}}"]}}]}}'
      WHERE
        id = 573
      ;
      UPDATE directus_fields
      SET
        options = '{"filter":{"_and":[{"project_id":{"_in":["$CURRENT_USER.project_id","{{project_id}}"]}}]},"template":"{{slug}}","enableCreate":false}'
      WHERE
        id = 617
      ;
    SQL
  end
end
