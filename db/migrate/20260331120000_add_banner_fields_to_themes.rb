# frozen_string_literal: true
# typed: false

class AddBannerFieldsToThemes < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      ALTER TABLE themes_translations ADD COLUMN IF NOT EXISTS banner_message text;
      ALTER TABLE themes ADD COLUMN IF NOT EXISTS banner_dismissible boolean DEFAULT true;

      INSERT INTO directus_fields (id, collection, field, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message)
      VALUES
        (619, 'themes_translations', 'banner_message', 'input-rich-text-html', NULL, NULL, NULL, false, false, 10, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
        (620, 'themes', 'banner_dismissible', 'boolean', NULL, NULL, NULL, false, false, 13, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL)
      ;
    SQL
  end
end
