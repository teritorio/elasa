# frozen_string_literal: true

class SourcesUniq < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE sources ADD CONSTRAINT sources_uniq_project_id_slug UNIQUE (project_id, slug);
    SQL
  end
end
