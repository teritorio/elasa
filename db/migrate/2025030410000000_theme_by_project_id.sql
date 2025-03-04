UPDATE directus_fields
SET options = '{"filter":{"_and":[{"project_id":{"_eq":"{{project_id}}"}}]}}'::jsonb
WHERE id = 16;
