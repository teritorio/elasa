SET search_path TO api02,public;

BEGIN;

TRUNCATE pois_property_values;
INSERT INTO pois_property_values
SELECT DISTINCT ON (t.project_id, fields.id, t.source_id)
    t.project_id,
    fields.id,
    t.source_id,
    t.property_values
FROM
    filters
    JOIN fields ON
        fields.id = coalesce(multiselection_property, checkboxes_list_property, boolean_property)
    JOIN LATERAL pois_property_extract_values(filters.project_id, NULL, fields.field) AS t ON true
WHERE
    :project_id IS NULL OR filters.project_id = :project_id
ORDER BY
    t.project_id,
    t.source_id,
    fields.id
;

COMMIT;
