UPDATE directus_fields SET readonly = true WHERE collection LIKE 'local-%' AND field = 'id';
