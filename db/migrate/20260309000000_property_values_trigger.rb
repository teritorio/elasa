# frozen_string_literal: true
# typed: false

class PropertyValuesTrigger < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      DROP FUNCTION IF EXISTS filters_pois_property_values;
      DROP FUNCTION IF EXISTS filters_pois_property_values_trigger_from_menu_items_filters;
      DROP TRIGGER IF EXISTS menu_items_filters_pois_property_values_trigger ON menu_items_filters;
    SQL
  end
end
