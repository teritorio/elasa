# frozen_string_literal: true

class AddOpeningHoursEventRenderType < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      UPDATE directus_fields
      SET options = jsonb_set(
        options::jsonb,
        '{choices}',
        (options::jsonb -> 'choices') || '[{"text":"osm:opening_hours@event","value":"osm:opening_hours@event"}]'::jsonb
      )::text
      WHERE id = 614
      ;
    SQL
  end
end
