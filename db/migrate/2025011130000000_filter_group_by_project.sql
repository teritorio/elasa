UPDATE directus_fields
SET
    options = '{"template":"{{type}}{{field}}{{group}}","filter":{"_and":[{"type":{"_eq":"group"}},{"project_id":{"_eq":"{{project_id}}"}}]}}'::jsonb
WHERE id IN (149, 150, 151);
