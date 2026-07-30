# frozen_string_literal: true

class AddOpeningHoursEventRenderType < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      UPDATE directus_fields
      SET
        options = '{"choices":[{"text":"string","value":"string"},{"text":"text","value":"text"},{"text":"integer","value":"integer"},{"text":"boolean","value":"boolean"},{"text":"weblink","value":"weblink"},{"text":"weblink@social-network","value":"weblink@social-network"},{"text":"weblink@download","value":"weblink@download"},{"text":"email","value":"email"},{"text":"phone","value":"phone"},{"text":"date","value":"date"},{"text":"datetime","value":"datetime"},{"text":"duration","value":"duration"},{"text":"start_end_date","value":"start_end_date"},{"text":"osm:opening_hours","value":"osm:opening_hours"},{"text":"osm:opening_hours:event","value":"osm:opening_hours:event"},{"text":"osm:collection_times","value":"osm:collection_times"},{"text":"image","value":"image"},{"text":"mapillary","value":"mapillary"},{"text":"panoramax","value":"panoramax"},{"text":"tag","value":"tag"},{"text":"color","value":"color"},{"text":"rating-scale","value":"rating-scale"},{"text":"osm:stars","value":"osm:stars"},{"text":"coordinates","value":"coordinates"},{"text":"addr","value":"addr"},{"text":"route","value":"route"}]}'
      WHERE
        id = 614
      ;
    SQL
  end
end
