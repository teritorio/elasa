UPDATE
    category_filters
SET
    values = (
        SELECT
            json_agg(DISTINCT value ORDER BY value) AS values
        FROM (
            SELECT
                jsonb_array_elements_text(properties->property) AS value
            FROM
                categories
                JOIN categorie_sources_tourinsoft ON
                    categorie_sources_tourinsoft.category_id = categories.id
                JOIN poi_tourinsoft ON
                    poi_tourinsoft.source_tourinsoft_id = categorie_sources_tourinsoft.source_tourinsoft_id
            WHERE
                categories.id = category_filters.category_id
            ) AS t
        GROUP BY
            id
    )
WHERE
    type IN (
        'multiselection'::category_filters_type_type,
        'checkboxes_list'::category_filters_type_type
    )
;
