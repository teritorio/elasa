# frozen_string_literal: true
# typed: false

class DirectusFieldsDisplay < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      UPDATE directus_fields SET interface = 'input-code', options = '{"size":"small","lineNumber":false}' WHERE id = 124;
    SQL
  end
end
