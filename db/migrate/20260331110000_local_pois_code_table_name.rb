# frozen_string_literal: true
# typed: false

class LocalPoisCodeTableName < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      INSERT INTO directus_flows (id, name, icon, color, description, status, trigger, accountability, options, operation, date_created, user_created)
      VALUES (
        '96ccf7a5-8702-4760-8c9e-b53267f234b2'::uuid,
        'Create local POIs table',
        'bolt',
        NULL,
        NULL,
        'active',
        'manual',
        'all',
        '{"collections":["sources"],"requireConfirmation":true,"fields":[{"field":"withImages","type":"boolean","name":"With Images","meta":{"interface":"boolean","width":"half"}},{"field":"withThumbnail","type":"boolean","name":"With Thumbnail","meta":{"interface":"boolean","options":{"iconOn":"image_search"},"width":"half"}},{"field":"withName","type":"boolean","name":"With Name","meta":{"interface":"boolean","width":"half"}},{"field":"withDescription","type":"boolean","name":"With Description","meta":{"interface":"boolean","width":"half"}},{"field":"withAddr","type":"boolean","name":"Add addr:* fields","meta":{"interface":"boolean","width":"half"}},{"field":"withContact","type":"boolean","name":"Add contact:* fields","meta":{"interface":"boolean","width":"half"}},{"field":"withWebsiteDetails","type":"boolean","name":"With website:details","meta":{"interface":"boolean"}},{"field":"withColors","type":"boolean","name":"withColors","meta":{"interface":"boolean"}},{"field":"withDeps","type":"boolean","name":"Add link to other objects","meta":{"interface":"boolean","width":"half"}},{"field":"withWaypoints","type":"boolean","name":"Add waypoints","meta":{"interface":"boolean","width":"half"}},{"field":"codeTableName","type":"string","name":"Code table name","meta":{"interface":"input","width":"full"}}]}'::json,
        'bbcfb368-cce2-4dc0-b5b1-9ba49a893da8'::uuid,
        '2024-11-11 17:16:24.222+00'::timestamp with time zone,
        '7ee01efc-e308-47e8-bf57-3dacd8ba56c5'::uuid
      )
      ON CONFLICT (id) DO UPDATE
      SET options = EXCLUDED.options
      ;

      INSERT INTO directus_operations (id, name, key, type, position_x, position_y, options, resolve, reject, flow, date_created, user_created)
      VALUES (
        'bbcfb368-cce2-4dc0-b5b1-9ba49a893da8'::uuid,
        'Create Local Table',
        'create_locale_table_elkil',
        'create-locale-table',
        19,
        1,
        '{"withImages":"{{$trigger.body.withImages}}","withThumbnail":"{{$trigger.body.withThumbnail}}","withName":"{{$trigger.body.withName}}","withDescription":"{{$trigger.body.withDescription}}","withAddr":"{{$trigger.body.withAddr}}","withContact":"{{$trigger.body.withContact}}","withWebsiteDetails":"{{$trigger.body.withWebsiteDetails}}","withColors":"{{$trigger.body.withColors}}","withDeps":"{{$trigger.body.withDeps}}","withWaypoints":"{{$trigger.body.withWaypoints}}","codeTableName":"{{$trigger.body.codeTableName}}","withTranslations":"{{$trigger.body.withTranslations}}"}'::json,
        NULL,
        NULL,
        '96ccf7a5-8702-4760-8c9e-b53267f234b2'::uuid,
        '2024-11-11 17:16:33.864+00'::timestamp with time zone,
        '7ee01efc-e308-47e8-bf57-3dacd8ba56c5'::uuid
      )
      ON CONFLICT (id) DO UPDATE
      SET options = EXCLUDED.options
      ;
    SQL
  end
end
