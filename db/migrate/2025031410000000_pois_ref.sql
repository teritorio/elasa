CREATE TABLE pois_pois (
    id SERIAL PRIMARY KEY,
    parent_pois_id integer NOT NULL REFERENCES pois(id) ON DELETE CASCADE,
    children_pois_id integer NOT NULL REFERENCES pois(id) ON DELETE CASCADE,
    index integer not null DEFAULT 1
);

INSERT INTO public.directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url, versioning) VALUES ('pois_pois', 'import_export', NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all', NULL, NULL, 2, 'pois', 'open', NULL, false);

INSERT INTO public.directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message) VALUES (584, 'pois_pois', 'id', NULL, NULL, NULL, NULL, NULL, false, true, 1, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message) VALUES (585, 'pois_pois', 'parent_pois_id', NULL, NULL, NULL, NULL, NULL, false, true, 2, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message) VALUES (586, 'pois_pois', 'children_pois_id', NULL, NULL, NULL, NULL, NULL, false, true, 3, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message) VALUES (587, 'pois_pois', 'index', NULL, 'input', NULL, NULL, NULL, false, false, 4, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL);

INSERT INTO public.directus_permissions (id, collection, action, permissions, validation, presets, fields, policy) VALUES (254, 'pois_pois', 'create', NULL, NULL, NULL, '*', '5979e2ac-a34f-4c70-bf9d-de48b3900a8f');
INSERT INTO public.directus_permissions (id, collection, action, permissions, validation, presets, fields, policy) VALUES (255, 'pois_pois', 'read', '{"_and":[{"pois_id":{"source_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}}]}', NULL, NULL, '*', '5979e2ac-a34f-4c70-bf9d-de48b3900a8f');

INSERT INTO public.directus_relations (id, many_collection, many_field, one_collection, one_field, one_collection_field, one_allowed_collections, junction_field, sort_field, one_deselect_action) VALUES (76, 'pois_pois', 'children_pois_id', 'pois', NULL, NULL, NULL, 'parent_pois_id', NULL, 'nullify');
INSERT INTO public.directus_relations (id, many_collection, many_field, one_collection, one_field, one_collection_field, one_allowed_collections, junction_field, sort_field, one_deselect_action) VALUES (77, 'pois_pois', 'parent_pois_id', 'pois', 'parent_pois_id', NULL, NULL, 'children_pois_id', 'index', 'delete');

SELECT pg_catalog.setval('public.directus_fields_id_seq', 587, true);
SELECT pg_catalog.setval('public.directus_permissions_id_seq', 255, true);
SELECT pg_catalog.setval('public.directus_relations_id_seq', 77, true);
