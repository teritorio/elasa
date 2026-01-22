# frozen_string_literal: true
# typed: false

class DirectusPluginJson < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      INSERT INTO directus_extensions(enabled, id, folder, source, bundle)
      VALUES (true, '8f77639c-6570-484b-9628-79a3d44c5a4c', 'directus-extension-key-value-interface', 'local', NULL)
    SQL
  end
end
