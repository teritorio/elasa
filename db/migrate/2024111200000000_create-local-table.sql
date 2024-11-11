MERGE INTO directus_extensions
USING (VALUES (true, 'a4b66d1b-c7fe-4bc2-bd22-6c3d3ab0e83f'::uuid, 'directus-extension-create-local-table', 'local', NULL::uuid)) AS source (enabled, id, folder, source, bundle) ON
    directus_extensions.folder = source.folder AND
    directus_extensions.source = source.source
WHEN MATCHED THEN UPDATE SET
    enabled = source.enabled,
    id = source.id,
    folder = source.folder,
    source = source.source,
    bundle = source.bundle
WHEN NOT MATCHED THEN INSERT (enabled, id, folder, source, bundle)
    VALUES (source.enabled, source.id, source.folder, source.source, source.bundle)
;

MERGE INTO directus_flows
USING (VALUES ('96ccf7a5-8702-4760-8c9e-b53267f234b2'::uuid, 'Create local POIs table', 'bolt', NULL, NULL, 'active', 'manual', 'all', '{"collections":["sources"],"requireConfirmation":true,"fields":[{"field":"withImages","type":"boolean","name":"With Images","meta":{"interface":"boolean"}},{"field":"withTranslations","type":"boolean","name":"With Translations","meta":{"interface":"boolean"}},{"field":"withName","type":"boolean","name":"With Name","meta":{"interface":"boolean"}},{"field":"withDescription","type":"boolean","meta":{"interface":"boolean"}}]}'::json, 'bbcfb368-cce2-4dc0-b5b1-9ba49a893da8'::uuid, '2024-11-11 17:16:24.222+00'::timestamp with time zone, '7ee01efc-e308-47e8-bf57-3dacd8ba56c5'::uuid)) AS source (id, name, icon, color, description, status, trigger, accountability, options, operation, date_created, user_created) ON
    directus_flows.id = source.id
WHEN MATCHED THEN UPDATE SET
    name = source.name,
    icon = source.icon,
    color = source.color,
    description = source.description,
    status = source.status,
    trigger = source.trigger,
    accountability = source.accountability,
    options = source.options,
    operation = source.operation,
    date_created = source.date_created,
    user_created = source.user_created
WHEN NOT MATCHED THEN INSERT (id, name, icon, color, description, status, trigger, accountability, options, operation, date_created, user_created)
    VALUES (source.id, source.name, source.icon, source.color, source.description, source.status, source.trigger, source.accountability, source.options, source.operation, source.date_created, source.user_created)
;

MERGE INTO directus_operations
USING (VALUES ('bbcfb368-cce2-4dc0-b5b1-9ba49a893da8'::uuid, 'Create Local Table', 'create_locale_table_elkil', 'create-locale-table', 19, 1, '{"withImages":"{{$trigger.body.withImages}}","withTranslations":"{{$trigger.body.withTranslations}}","withName":"{{$trigger.body.withName}}","withDescription":"{{$trigger.body.withDescription}}"}'::json, NULL::uuid, NULL::uuid, '96ccf7a5-8702-4760-8c9e-b53267f234b2'::uuid, '2024-11-11 17:16:33.864+00'::timestamp with time zone, '7ee01efc-e308-47e8-bf57-3dacd8ba56c5'::uuid)) AS source (id, name, key, type, position_x, position_y, options, resolve, reject, flow, date_created, user_created) ON
    directus_operations.id = source.id
WHEN MATCHED THEN UPDATE SET
    name = source.name,
    key = source.key,
    type = source.type,
    position_x = source.position_x,
    position_y = source.position_y,
    options = source.options,
    resolve = source.resolve,
    reject = source.reject,
    flow = source.flow,
    date_created = source.date_created,
    user_created = source.user_created
WHEN NOT MATCHED THEN INSERT (id, name, key, type, position_x, position_y, options, resolve, reject, flow, date_created, user_created)
    VALUES (source.id, source.name, source.key, source.type, source.position_x, source.position_y, source.options, source.resolve, source.reject, source.flow, source.date_created, source.user_created)
;
