# frozen_string_literal: true

class VidoConfig < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE projects ADD COLUMN image_proxy_hosts jsonb;
      ALTER TABLE themes
        ADD COLUMN isochrone boolean DEFAULT false,
        ADD COLUMN map_style_base_url character varying(255),
        ADD COLUMN map_style_satellite_url character varying(255),
        ADD COLUMN map_bicycle_style_url character varying(255),
        ADD COLUMN matomo_url character varying(255),
        ADD COLUMN matomo_siteid character varying(255),
        ADD COLUMN google_site_verification character varying(255),
        ADD COLUMN google_tag_manager_id character varying(255),
        ADD COLUMN cookies_usage_detail_url character varying(255);
      ;
      ALTER TABLE themes_translations ADD COLUMN cookies_consent_message text;

      UPDATE directus_fields SET sort = 7 WHERE id = 49;
      UPDATE directus_fields SET sort = 1, "group" = 'map', width = 'half' WHERE id = 160;
      UPDATE directus_fields SET sort = 2, "group" = 'map', width = 'half' WHERE id = 161;
      UPDATE directus_fields SET sort = 5 WHERE id = 542;
      UPDATE directus_fields SET sort = 6 WHERE id = 543;
      UPDATE directus_fields SET sort = 8 WHERE id = 573;

      INSERT INTO directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message) VALUES
      (590, 'themes', 'isochrone', 'cast-boolean', 'boolean', NULL, NULL, NULL, false, false, 3, 'full', NULL, NULL, NULL, false, 'map', NULL, NULL),
      (591, 'themes', 'map_style_base_url', NULL, 'input', NULL, NULL, NULL, false, false, 4, 'full', NULL, NULL, NULL, true, 'map', NULL, NULL),
      (592, 'themes', 'map_style_satellite_url', NULL, 'input', NULL, NULL, NULL, false, false, 5, 'full', NULL, NULL, NULL, true, 'map', NULL, NULL),
      (593, 'themes', 'map_bicycle_style_url', NULL, 'input', NULL, NULL, NULL, false, false, 6, 'full', NULL, NULL, NULL, false, 'map', NULL, NULL),
      (594, 'themes', 'map', 'alias,no-data,group', 'group-detail', NULL, NULL, NULL, false, false, 10, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
      (595, 'themes', 'analytics', 'alias,no-data,group', 'group-detail', NULL, NULL, NULL, false, false, 11, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
      (596, 'themes', 'matomo_url', NULL, 'input', NULL, NULL, NULL, false, false, 1, 'half', NULL, NULL, NULL, false, 'analytics', NULL, NULL),
      (597, 'themes', 'matomo_siteid', NULL, 'input', NULL, NULL, NULL, false, false, 2, 'half', NULL, NULL, NULL, false, 'analytics', NULL, NULL),
      (598, 'themes', 'google_site_verification', NULL, 'input', NULL, NULL, NULL, false, false, 9, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
      (599, 'themes', 'google_tag_manager_id', NULL, 'input', NULL, NULL, NULL, false, true, 3, 'full', NULL, NULL, NULL, false, 'analytics', NULL, NULL),
      (600, 'themes', 'cookies_usage_detail_url', NULL, 'input', NULL, NULL, NULL, false, false, 4, 'full', NULL, NULL, NULL, false, 'analytics', NULL, NULL),
      (601, 'projects', 'image_proxy_hosts', 'cast-json', 'simple-list', '{"size":"small"}', NULL, NULL, false, false, 17, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
      (602, 'themes_translations', 'cookies_consent_message', NULL, 'input-multiline', NULL, NULL, NULL, false, false, 9, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL);
      ;
    SQL
  end
end
