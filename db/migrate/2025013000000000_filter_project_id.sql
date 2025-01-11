UPDATE directus_fields
SET
    options = '{"filter":{"_and":[{"project_id":{"_eq":"{{project_id}}"}}]}}'::jsonb
WHERE id = 107;

UPDATE directus_fields
SET
    hidden = true
WHERE id = 561;
