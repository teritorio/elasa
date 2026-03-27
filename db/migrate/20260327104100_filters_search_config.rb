# frozen_string_literal: true

class FiltersSearchConfig < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      UPDATE directus_fields
      SET
        options = '{"search_config":{"_and":[{"_or":[{"filters_translations":{"name":{"_icontains":"$SEARCH"}}},{"field_id":{"fields_translations":{"name":{"_icontains":"$SEARCH"}}}},{"field_id":{"field":{"_icontains":"$SEARCH"}}}]}]}}'
      WHERE
        id = 606
      ;
    SQL
  end
end
