# frozen_string_literal: true
# typed: false

class DirectusFileOnDeleteCascade < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE directus_files
        DROP CONSTRAINT directus_files_project_id_foreign,
        ADD CONSTRAINT directus_files_project_id_foreign FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE
      ;
    SQL
  end
end
