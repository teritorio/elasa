UPDATE directus_fields
SET options = '{"template":null,"filter":{"_and":[{"type":{"_eq":"menu_group"}},{"project_id":{"_eq":"{{project_id}}"}}]}}'::jsonb
WHERE id = 49;

UPDATE directus_fields
SET options = '{"template":"{{sources_id.slug}}","enableLink":true,"filter":{"_and":[{"project_id":{"_eq":"{{project_id}}"}}]}}'::jsonb
WHERE id = 74;
