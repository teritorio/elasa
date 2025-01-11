UPDATE directus_fields
SET
    interface = 'select-dropdown',
    options = '{"choices":[{"text":"compact","value":"compact"},{"text":"large","value":"large"}]}'::jsonb
WHERE id = 67;
