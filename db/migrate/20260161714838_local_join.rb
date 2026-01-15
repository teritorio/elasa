# frozen_string_literal: true
# typed: false

class LocalJoin < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      INSERT INTO directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url, versioning)
      VALUES ('local_extension_sources', 'folder_open', NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, NULL, 'all', NULL, NULL, 4, 'sources', 'open', NULL, false)
    SQL
  end
end
