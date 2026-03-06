# frozen_string_literal: true
# typed: false

class MenuItemsFiltersDelete < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      UPDATE
        directus_relations
      SET
        one_deselect_action = 'delete'
      WHERE
        id = 25
      ;
    SQL
  end
end
