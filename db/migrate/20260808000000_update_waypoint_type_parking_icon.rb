# frozen_string_literal: true
# typed: false

class UpdateWaypointTypeParkingIcon < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      UPDATE directus_fields
      SET
        options = '{"choices":[{"text":"parking","value":"parking","icon":"local_parking"},{"text":"start","value":"start","icon":"flag"},{"text":"waypoint","value":"waypoint","icon":"pin_drop"},{"text":"end","value":"end","icon":"emoji_flags"}]}'
      WHERE
        collection LIKE 'local-%-waypoints'
        AND field = 'route___waypoint___type'
      ;
    SQL
  end
end
