# frozen_string_literal: true
# typed: false

class LocalCodesCollection < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      INSERT INTO directus_flows (id, name, icon, color, description, status, trigger, accountability, options, operation, date_created, user_created)
      VALUES (
        '8f4cfb92-fd35-4f3f-af2c-2de3f46f2356'::uuid,
        'Create Local Codes Table',
        'bolt',
        NULL,
        NULL,
        'active',
        'manual',
        'all',
        '{"collections":["projects"],"requireConfirmation":true,"fields":[{"field":"tableName","type":"string","name":"Table Name","meta":{"interface":"input","width":"full"}}]}'::json,
        'eb00c4f6-3a64-4526-8d18-877ec68d57c4'::uuid,
        '2026-03-30 10:00:00+00'::timestamp with time zone,
        '7ee01efc-e308-47e8-bf57-3dacd8ba56c5'::uuid
      )
      ON CONFLICT (id) DO NOTHING
      ;

      INSERT INTO directus_operations (id, name, key, type, position_x, position_y, options, resolve, reject, flow, date_created, user_created)
      VALUES (
        'eb00c4f6-3a64-4526-8d18-877ec68d57c4'::uuid,
        'Create Local Codes',
        'create_local_codes',
        'create-local-codes',
        19,
        1,
        '{"tableName":"{{$trigger.body.tableName}}"}'::json,
        NULL,
        NULL,
        '8f4cfb92-fd35-4f3f-af2c-2de3f46f2356'::uuid,
        '2026-03-30 10:00:00+00'::timestamp with time zone,
        '7ee01efc-e308-47e8-bf57-3dacd8ba56c5'::uuid
      )
      ON CONFLICT (id) DO NOTHING
      ;

      INSERT INTO directus_extensions (enabled, id, folder, source, bundle)
      VALUES (
        true,
        '4d2b308c-9f9a-4ec1-9b5e-6fcce1973b4a'::uuid,
        'directus-extension-create-local-codes',
        'local',
        NULL
      )
      ON CONFLICT (id) DO NOTHING
      ;

      INSERT INTO directus_collections (collection, icon, hidden, singleton, accountability, sort, "group", collapse, versioning)
      VALUES ('local_codes', 'folder_open', false, false, 'all', 5, 'sources', 'open', false)
      ON CONFLICT (collection) DO NOTHING
      ;
    SQL
  end
end
