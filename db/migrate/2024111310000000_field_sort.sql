UPDATE
    directus_fields
SET
    options = '{"template":"{{related_fields_id.type}} {{related_fields_id.field}}{{related_fields_id.group}}","enableLink":true,"limit":100}	related-values	{"template":"{{related_fields_id.type}}{{related_fields_id.field}}{{related_fields_id.group}}"}'::jsonb
WHERE
    id = 144
;