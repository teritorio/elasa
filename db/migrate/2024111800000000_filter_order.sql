ALTER TABLE menu_items_filters ADD COLUMN index integer DEFAULT 1 NOT NULL;

UPDATE directus_collections SET sort = 3 WHERE collection = 'fields_fields';
UPDATE directus_collections SET sort = 4 WHERE collection = 'languages';
UPDATE directus_collections SET sort = 1, "group" = 'menu_items' WHERE collection = 'menu_items_childrens';
UPDATE directus_collections SET sort = 3, "group" = 'menu_items' WHERE collection = 'menu_items_filters';
UPDATE directus_collections SET "group" = 'menu_items' WHERE collection = 'menu_items_sources';
UPDATE directus_collections SET sort = 2 WHERE collection = 'menu_items_translations';

UPDATE directus_relations SET many_field = 'menu_items_id' WHERE id = 25;
UPDATE directus_relations SET sort_field = 'index' WHERE id = 25;

INSERT INTO directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message)
VALUES (561, 'menu_items_filters', 'index', NULL, NULL, NULL, NULL, NULL, FALSE, FALSE, NULL, 'full', NULL, NULL, NULL, FALSE, NULL, NULL, NULL);

UPDATE directus_permissions SET fields = '*' WHERE id IN (74, 75);
