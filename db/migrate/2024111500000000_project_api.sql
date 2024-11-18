ALTER TABLE projects ADD COLUMN datasources_slug varchar;
UPDATE projects SET datasources_slug = slug;
ALTER TABLE projects ALTER COLUMN datasources_slug SET NOT NULL;

ALTER TABLE projects ADD COLUMN api_key uuid NOT NULL DEFAULT gen_random_uuid();

MERGE INTO directus_flows AS flows USING (VALUES
  ('8b576a89-30a0-4f3e-b20b-bc944914a1df'::uuid, 'Update POIs from Datasources', 'download', NULL, NULL, 'active', 'manual', 'all', '{"collections":["sources"]}'::json, 'ada3d2b2-2666-4be9-ac80-c57a91576a06'::uuid, '2024-11-15 12:07:07.149+00'::timestamp with time zone, '7ee01efc-e308-47e8-bf57-3dacd8ba56c5'::uuid)
) AS new_flows (id, name, icon, color, description, status, trigger, accountability, options, operation, date_created, user_created) ON
    flows.id = new_flows.id
WHEN MATCHED THEN
  UPDATE SET
    name = new_flows.name,
    icon = new_flows.icon,
    color = new_flows.color,
    description = new_flows.description,
    status = new_flows.status,
    trigger = new_flows.trigger,
    accountability = new_flows.accountability,
    options = new_flows.options,
    operation = new_flows.operation,
    date_created = new_flows.date_created,
    user_created = new_flows.user_created
WHEN NOT MATCHED THEN
  INSERT (id, name, icon, color, description, status, trigger, accountability, options, operation, date_created, user_created)
  VALUES (new_flows.id, new_flows.name, new_flows.icon, new_flows.color, new_flows.description, new_flows.status, new_flows.trigger, new_flows.accountability, new_flows.options, new_flows.operation, new_flows.date_created, new_flows.user_created)
;

MERGE INTO directus_operations AS operations USING (VALUES
  ('bbcfb368-cce2-4dc0-b5b1-9ba49a893da8'::uuid, 'Create Local Table', 'create_locale_table_elkil', 'create-locale-table', 19, 1, '{"withImages":"{{$trigger.body.withImages}}","withTranslations":"{{$trigger.body.withTranslations}}","withName":"{{$trigger.body.withName}}","withDescription":"{{$trigger.body.withDescription}}"}'::json, NULL, NULL::uuid, '96ccf7a5-8702-4760-8c9e-b53267f234b2'::uuid, '2024-11-11 17:16:33.864+00'::timestamp with time zone, '7ee01efc-e308-47e8-bf57-3dacd8ba56c5'::uuid),
  ('d334ba61-f792-40a2-9e9a-3bd6cf40f61a'::uuid, 'Read Projects', 'projects', 'item-read', 37, 1, '{"collection":"projects","key":"{{sources.project_id}}"}'::json, '8f15f766-7319-4c8e-a3c4-19a8ba54224b'::uuid, NULL::uuid, '8b576a89-30a0-4f3e-b20b-bc944914a1df'::uuid, '2024-11-15 12:14:18.725+00'::timestamp with time zone, '7ee01efc-e308-47e8-bf57-3dacd8ba56c5'::uuid),
  ('ada3d2b2-2666-4be9-ac80-c57a91576a06'::uuid, 'Read Sources', 'sources', 'item-read', 19, 1, '{"collection":"sources","key":"{{$trigger.body.keys}}"}'::json, 'd334ba61-f792-40a2-9e9a-3bd6cf40f61a'::uuid, NULL::uuid, '8b576a89-30a0-4f3e-b20b-bc944914a1df'::uuid, '2024-11-15 12:14:18.829+00'::timestamp with time zone, '7ee01efc-e308-47e8-bf57-3dacd8ba56c5'::uuid),
  ('8f15f766-7319-4c8e-a3c4-19a8ba54224b'::uuid, 'Webhook / Request URL', 'request_vcvmd', 'request', 55, 1, '{"url":"http://api:12000/api/0.2/project/{{projects.slug}}/admin/sources/load?api_key={{projects.api_key}}"}'::json, NULL, NULL::uuid, '8b576a89-30a0-4f3e-b20b-bc944914a1df'::uuid, '2024-11-15 16:24:47.807+00'::timestamp with time zone, '7ee01efc-e308-47e8-bf57-3dacd8ba56c5'::uuid)
) AS new_operations (id, name, key, type, position_x, position_y, options, resolve, reject, flow, date_created, user_created) ON
    operations.id = new_operations.id
WHEN MATCHED THEN
    UPDATE SET
        name = new_operations.name,
        key = new_operations.key,
        type = new_operations.type,
        position_x = new_operations.position_x,
        position_y = new_operations.position_y,
        options = new_operations.options,
        resolve = new_operations.resolve,
        reject = new_operations.reject,
        flow = new_operations.flow,
        date_created = new_operations.date_created,
        user_created = new_operations.user_created
WHEN NOT MATCHED THEN
    INSERT (id, name, key, type, position_x, position_y, options, resolve, reject, flow, date_created, user_created)
    VALUES (new_operations.id, new_operations.name, new_operations.key, new_operations.type, new_operations.position_x, new_operations.position_y, new_operations.options, new_operations.resolve, new_operations.reject, new_operations.flow, new_operations.date_created, new_operations.user_created)
;
