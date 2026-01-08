# frozen_string_literal: true
# typed: false

class MenuGroupFilters < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      UPDATE directus_fields SET sort = 2 WHERE id = 69;
      UPDATE directus_fields SET sort = 3 WHERE id = 71;
      UPDATE directus_fields SET sort = 4 WHERE id = 73;
      UPDATE directus_fields SET sort = 5 WHERE id = 128;
      UPDATE directus_fields SET sort = 6 WHERE id = 149;
      UPDATE directus_fields SET sort = 7 WHERE id = 150;
      UPDATE directus_fields SET sort = 8 WHERE id = 151;
      UPDATE directus_fields SET sort = 9 WHERE id = 179;
      UPDATE directus_fields SET sort = 10 WHERE id = 180;

      UPDATE directus_fields SET sort = 12, "group" = NULL WHERE id = 107;
    SQL
  end
end
