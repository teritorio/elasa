# frozen_string_literal: true

class FieldType < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE fields
        ADD COLUMN multilingual boolean,
        ADD COLUMN media_type varchar,
        ADD COLUMN role varchar
      ;

      INSERT INTO directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message) VALUES
      (612, 'fields', 'multilingual', 'cast-boolean', NULL, NULL, NULL, NULL, false, false, 3, 'full', NULL, NULL, NULL, false, 'field_block', NULL, NULL),
      (613, 'fields', 'media_type', NULL, 'select-dropdown', '{"choices":[{"text":"text/plain","value":"Plain text"},{"text":"text/html","value":"HTML"},{"text":"text/x-uri","value":"URL"},{"text":"text/vnd.phone-number","value":"Phone number"},{"text":"text/vnd.osm.opening_hours","value":"OSM opening_hours value"},{"text":"text/vnd.osm.html-color","value":"HTML color"},{"text":"text/vnd.osm.stars","value":"OSM stars value"}]}', NULL, NULL, false, false, 4, 'full', NULL, NULL, NULL, false, 'field_block', NULL, NULL),
      (614, 'fields', 'role', NULL, 'select-dropdown', '{"choices":[{"text":"string","value":"string"},{"text":"html","value":"html"},{"text":"string@short","value":"string@short"},{"text":"integer","value":"integer"},{"text":"boolean","value":"boolean"},{"text":"weblink","value":"weblink"},{"text":"weblink@social-network","value":"weblink@social-network"},{"text":"weblink@download","value":"weblink@download"},{"text":"email","value":"email"},{"text":"phone","value":"phone"},{"text":"date","value":"date"},{"text":"datetime","value":"datetime"},{"text":"duration","value":"duration"},{"text":"start_end_date","value":"start_end_date"},{"text":"osm:opening_hours","value":"osm:opening_hours"},{"text":"osm:collection_times","value":"osm:collection_times"},{"text":"image","value":"image"},{"text":"mapillary","value":"mapillary"},{"text":"panoramax","value":"panoramax"},{"text":"tag","value":"tag"},{"text":"color","value":"color"},{"text":"rating-scale","value":"rating-scale"},{"text":"osm:stars","value":"osm:stars"},{"text":"coordinates","value":"coordinates"},{"text":"addr","value":"addr"},{"text":"route","value":"route"}]}', NULL, NULL, false, false, 5, 'full', NULL, NULL, NULL, false, 'field_block', NULL, NULL)
      ;

      UPDATE directus_fields SET sort = 6 WHERE id = 140;
      UPDATE directus_fields SET "group" = NULL WHERE id = 140;
      UPDATE directus_fields SET sort = 8 WHERE id = 141;
      UPDATE directus_fields SET sort = 3 WHERE id = 144;
      UPDATE directus_fields SET sort = 9 WHERE id = 148;
      UPDATE directus_fields SET sort = 7 WHERE id = 550;
      UPDATE directus_fields SET sort = 10 WHERE id = 607;
    SQL
  end
end
