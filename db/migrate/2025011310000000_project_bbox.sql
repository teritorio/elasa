ALTER TABLE projects ALTER column bbox_line DROP NOT NULL, ALTER column bbox_line DROP EXPRESSION;

UPDATE directus_fields
SET hidden = false
WHERE id = 22;
