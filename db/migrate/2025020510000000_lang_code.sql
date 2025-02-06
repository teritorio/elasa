UPDATE
    fields
SET
    values_translations = replace(values_translations::text, '"fr":', '"fr-FR":')::json
WHERE
    values_translations IS NOT NULL
;
