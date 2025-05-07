UPDATE directus_collections SET sort = 5 WHERE collection = 'fields';
UPDATE directus_collections SET sort = 3 WHERE collection = 'themes';

DELETE FROM directus_extensions WHERE folder = 'directus-extension-schema-sync';

-- Fix JSON spaces
UPDATE directus_fields SET options = '{"filter":{"_and":[{"project_id":{"_eq":"{{project_id}}"}}]}}' WHERE id = 16;
UPDATE directus_fields SET options = '{"template":null,"filter":{"_and":[{"type":{"_eq":"menu_group"}},{"project_id":{"_eq":"{{project_id}}"}}]}}' WHERE id = 49;
UPDATE directus_fields SET options = '{"choices":[{"text":"compact","value":"compact"},{"text":"large","value":"large"}]}' WHERE id = 67;
UPDATE directus_fields SET options = '{"template":"{{sources_id.slug}}","enableLink":true,"filter":{"_and":[{"project_id":{"_eq":"{{project_id}}"}}]}}' WHERE id = 74;
UPDATE directus_fields SET options = '{"presets":[{"name":"$t:amenity","color":"#2A62AC"},{"name":"$t:catering","color":"#F5B700"},{"name":"$t:local_shop","color":"#00B3CC"},{"name":"$t:craft","color":"#C58511"},{"name":"$t:culture","color":"#76009E"},{"name":"$t:culture_shopping","color":"#A16CB3"},{"name":"$t:education","color":"#4076F6"},{"name":"$t:hosting","color":"#99163A"},{"name":"$t:leisure","color":"#00A757"},{"name":"$t:mobility","color":"#008ECF"},{"name":"$t:nature","color":"#8CC56F"},{"name":"$t:products","color":"#F25C05"},{"name":"$t:public_landmark","color":"#1D1D1B"},{"name":"$t:remarkable","color":"#E50980"},{"name":"$t:safety","color":"#E42224"},{"name":"$t:services","color":"#2A62AC"},{"name":"$t:services_shopping","color":"#7093C3"},{"name":"$t:shopping","color":"#808080"},{"name":"$t:social_services","color":"#006660"}]}' WHERE id = 78;
UPDATE directus_fields SET options = '{"presets":[{"name":"$t:amenity","color":"#2A62AC"},{"name":"$t:catering","color":"#F09007"},{"name":"$t:local_shop","color":"#00A0C4"},{"name":"$t:craft","color":"#C58511"},{"name":"$t:culture","color":"#76009E"},{"name":"$t:culture_shopping","color":"#76009E"},{"name":"$t:education","color":"#4076F6"},{"name":"$t:hosting","color":"#99163A"},{"name":"$t:leisure","color":"#00A757"},{"name":"$t:mobility","color":"#3B74B9"},{"name":"$t:nature","color":"#70B06A"},{"name":"$t:products","color":"#F25C05"},{"name":"$t:public_landmark","color":"#1D1D1B"},{"name":"$t:remarkable","color":"#E50980"},{"name":"$t:safety","color":"#E42224"},{"name":"$t:services","color":"#2A62AC"},{"name":"$t:services_shopping","color":"#2A62AC"},{"name":"$t:shopping","color":"#808080"},{"name":"$t:social_services","color":"#006660"}]}' WHERE id = 79;
UPDATE directus_fields SET options = '{"filter":{"_and":[{"project_id":{"_eq":"{{project_id}}"}}]}}' WHERE id = 107;
UPDATE directus_fields SET options = '{"template":"{{related_fields_id.type}} {{related_fields_id.field}}{{related_fields_id.group}}","enableLink":true,"limit":100,"filter":{"_and":[{"project_id":{"_eq":"{{project_id}}"}}]}}' WHERE id = 144;
UPDATE directus_fields SET options = '{"template":"{{type}}{{field}}{{group}}","filter":{"_and":[{"type":{"_eq":"group"}},{"project_id":{"_eq":"{{project_id}}"}}]}}' WHERE id = 149;
UPDATE directus_fields SET options = '{"template":"{{type}}{{field}}{{group}}","filter":{"_and":[{"type":{"_eq":"group"}},{"project_id":{"_eq":"{{project_id}}"}}]}}' WHERE id = 150;
UPDATE directus_fields SET options = '{"template":"{{type}}{{field}}{{group}}","filter":{"_and":[{"type":{"_eq":"group"}},{"project_id":{"_eq":"{{project_id}}"}}]}}' WHERE id = 151;

UPDATE directus_fields SET sort = 14 WHERE id = 470;

UPDATE directus_fields SET width = 'half' WHERE id = 131;
INSERT INTO
    directus_fields(id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message)
VALUES
    (559, 'projects', 'datasources_slug', NULL, NULL, NULL, NULL, NULL, false, false, 4, 'half', NULL, NULL, NULL, false, NULL, NULL, NULL),
    (560, 'projects', 'api_key', NULL, NULL, NULL, NULL, NULL, true, false, 15, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL)
;

UPDATE directus_fields SET id = 578 WHERE id = 1001;
UPDATE directus_fields SET id = 579 WHERE id = 1002;
UPDATE directus_fields SET id = 580 WHERE id = 1003;
UPDATE directus_fields SET id = 581 WHERE id = 1004;
UPDATE directus_fields SET id = 582 WHERE id = 1005;

INSERT INTO
    directus_fields(id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message)
VALUES
    (583, 'pois', 'parent_pois_id', 'm2m', 'list-m2m', '{"enableCreate":false,"enableSelect":false,"enableLink":true}', NULL, NULL, true, false, 7, 'full', NULL, NULL, NULL, true, NULL, NULL, NULL)
;

DELETE FROM directus_relations WHERE many_collection = 'menu_items_childrens';

ALTER TABLE projects ALTER COLUMN slug SET NOT NULL;
ALTER TABLE projects ALTER COLUMN slug DROP DEFAULT;
DROP VIEW api01.projects_join;
ALTER TABLE projects ALTER COLUMN datasources_slug TYPE varchar(255);
