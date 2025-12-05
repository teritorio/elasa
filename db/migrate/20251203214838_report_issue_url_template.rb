# frozen_string_literal: true

class ReportIssueUrlTemplate < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE sources ADD COLUMN report_issue_url_template text;
    SQL
  end
end
