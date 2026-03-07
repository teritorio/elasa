# frozen_string_literal: true
# typed: false

class PoisSlugsJsonb < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      DROP VIEW IF EXISTS api02.pois_join CASCADE;
      DROP VIEW IF EXISTS api02.pois_join_without_deps CASCADE;
      DROP VIEW IF EXISTS api02.pois_join_with_deps CASCADE;
      ALTER TABLE pois ALTER COLUMN slugs TYPE jsonb;
    SQL
  end
end
