UPDATE
    directus_fields
SET
    display = 'translations',
    display_options = '{"template":"{{name}}","languageField":"name","userLanguage":true}'::jsonb
WHERE
    id IN (236, 245, 252, 257, 545, 565)
;
