INSERT INTO directus_fields (collection, field, special, interface) VALUES
('categories', 'sources_osm', 'm2m', 'list-m2m');
INSERT INTO directus_relations (many_collection, many_field, one_collection, one_field, junction_field, one_deselect_action) VALUES
('categorie_sources_osm', 'source_osm_id', 'sources_osm', NULL, 'category_id', 'nullify'),
('categorie_sources_osm', 'category_id', 'categories', 'sources_osm', 'source_osm_id', 'nullify');
UPDATE directus_collections SET icon='import_export' WHERE collection='categorie_sources_osm';

INSERT INTO directus_fields (collection, field, special, interface) VALUES
('categories', 'sources_tourinsoft', 'm2m', 'list-m2m');
INSERT INTO directus_relations (many_collection, many_field, one_collection, one_field, junction_field, one_deselect_action) VALUES
('categorie_sources_tourinsoft', 'source_tourinsoft_id', 'sources_tourinsoft', NULL, 'category_id', 'nullify'),
('categorie_sources_tourinsoft', 'category_id', 'categories', 'sources_tourinsoft', 'source_tourinsoft_id', 'nullify');
UPDATE directus_collections SET icon='import_export' WHERE collection='categorie_sources_tourinsoft';

INSERT INTO directus_fields (collection, field, special, interface) VALUES
('categories', 'sources_cms', 'm2m', 'list-m2m');
INSERT INTO directus_relations (many_collection, many_field, one_collection, one_field, junction_field, one_deselect_action) VALUES
('categorie_sources_cms', 'source_cms_id', 'sources_cms', NULL, 'category_id', 'nullify'),
('categorie_sources_cms', 'category_id', 'categories', 'sources_cms', 'source_cms_id', 'nullify');
UPDATE directus_collections SET icon='import_export' WHERE collection='categorie_sources_cms';
