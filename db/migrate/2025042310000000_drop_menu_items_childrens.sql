DROP TABLE menu_items_childrens;
DELETE FROM directus_collections WHERE collection = 'menu_items_childrens';
DELETE FROM directus_fields WHERE collection = 'menu_items_childrens';
DELETE FROM directus_permissions WHERE collection = 'menu_items_childrens';
DELETE FROM directus_relations WHERE collection = 'menu_items_childrens';
