ALTER TABLE articles ALTER COLUMN project_id SET NOT NULL;
ALTER TABLE articles
    DROP CONSTRAINT articles_project_id_foreign,
    ADD CONSTRAINT articles_project_id_foreign FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
;

UPDATE
    directus_fields
SET
    readonly = true,
    required = false
WHERE
    id = 572
;
