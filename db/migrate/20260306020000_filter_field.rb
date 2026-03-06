# frozen_string_literal: true
# typed: false

class FilterField < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      UPDATE
        directus_fields
      SET
        special = NULL,
        "group" = null
      WHERE
        id = 553
      ;
    SQL
  end
end
