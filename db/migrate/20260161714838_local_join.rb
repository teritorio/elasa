# frozen_string_literal: true
# typed: false

class LocalJoin < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE sources ADD COLUMN extends_source_id integer REFERENCES sources(id);

      INSERT INTO directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message)
      VALUES (617, 'sources', 'extends_source_id', NULL, 'select-dropdown-m2o', '{"filter":{"_and":[{"project_id":{"_eq":"{{project_id}}"}}]},"template":"{{slug}}","enableCreate":false}', 'related-values', '{"template":"{{slug}}"}', false, false, NULL, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL);

      UPDATE directus_operations
      SET options = '{"withImages":"{{$trigger.body.withImages}}","withThumbnail":"{{$trigger.body.withThumbnail}}","withName":"{{$trigger.body.withName}}","withDescription":"{{$trigger.body.withDescription}}","withAddr":"{{$trigger.body.withAddr}}","withContact":"{{$trigger.body.withContact}}","withWebsiteDetails":"{{$trigger.body.withWebsiteDetails}}","withColors":"{{$trigger.body.withColors}}","withDeps":"{{$trigger.body.withDeps}}","withWaypoints":"{{$trigger.body.withWaypoints}}","withTranslations":"{{$trigger.body.withTranslations}}"}'
      WHERE id = 'bbcfb368-cce2-4dc0-b5b1-9ba49a893da8';

      INSERT INTO directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url, versioning)
      VALUES ('local_extension_sources', 'folder_open', NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, NULL, 'all', NULL, NULL, 4, 'sources', 'open', NULL, false)
    SQL
  end
end
