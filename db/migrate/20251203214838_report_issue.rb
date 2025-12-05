# frozen_string_literal: true

class ReportIssue < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE themes ADD COLUMN report_issue boolean DEFAULT false;
      ALTER TABLE sources ADD COLUMN report_issue jsonb;

      INSERT INTO directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message) VALUES
      (610, 'sources', 'report_issue', NULL, 'input', '{"iconLeft":"bug_report"}', NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
      (611, 'themes', 'report_issue', 'cast-boolean', 'boolean', NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL)
      ;
    SQL
  end
end
