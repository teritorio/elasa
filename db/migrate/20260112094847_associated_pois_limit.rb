# frozen_string_literal: true

class AssociatedPoisLimit < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      UPDATE directus_fields SET options = options::jsonb || '{"limit": 200}'::jsonb WHERE collection LIKE 'local-%' AND field='associated_pois';
    SQL
  end
end
