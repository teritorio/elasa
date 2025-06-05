UPDATE directus_relations SET one_deselect_action = 'delete' WHERE many_collection like 'local-%_i' AND (one_collection = 'directus_files' OR one_field = 'image');
