# frozen_string_literal: true
# typed: false

class ReportIssueInterface < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
        UPDATE directus_fields
        SET
          interface = 'key-value',
          options = '{"iconLeft":"bug_report","schema":[{"key":"url_template","type":"string","interface":"input","note":null,"options":{"iconLeft":"link"}},{"key":"value_extractors","type":"json","interface":"key-value","options":{"allowOther":true,"schema":[{"key":"lon","type":"string","interface":"input"},{"key":"lat","type":"string","interface":"input"}]}}]}',
          display = 'formatted-json-value',
          display_options = '{"format":"{{url_template}}"}'
        WHERE id = 610
        ;
      SQL
  end
end
