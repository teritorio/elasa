ALTER TABLE projects ALTER COLUMN datasources_slug DROP NOT NULL;

UPDATE directus_fields SET required = FALSE WHERE id = 559
