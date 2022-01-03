CREATE SCHEMA IF NOT EXISTS postgisftw;

DROP FUNCTION IF EXISTS postgisftw.project;
CREATE OR REPLACE FUNCTION postgisftw.project(
    _project_id integer
) RETURNS TABLE (
    d jsonb
) AS $$
    SELECT
        to_jsonb(projects.*) ||
        jsonb_build_object(
            'themes', (
                SELECT
                    json_agg(to_jsonb(themes.*) - 'project_id') AS themes
                FROM
                    projects
                    JOIN themes ON
                        themes.project_id = projects.id
                WHERE
                    projects.id = _project_id
            )
        ) AS project
    FROM
        projects
    WHERE
        projects.id = _project_id
    ;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS postgisftw.menu;
CREATE OR REPLACE FUNCTION postgisftw.menu(
    _project_id integer,
    _theme_id integer
) RETURNS TABLE (
    d jsonb
) AS $$
    SELECT
        jsonb_agg(
            to_jsonb(menu_items.*) - 'theme_id' - 'menu_group_id' - 'category_id' ||
            jsonb_build_object(
                'menu_group', to_jsonb(menu_groups.*),
                'category', to_jsonb(categories.*) || jsonb_build_object(
                    'filters', (
                        SELECT
                            jsonb_agg(
                                to_jsonb(category_filters.*) - 'category_id' - 'values' || jsonb_build_object(
                                    'name', property_label || coalesce(property_label_filter, '{}'::jsonb),
                                    'values', (
                                        SELECT
                                            jsonb_agg(jsonb_build_object(
                                                'value', value,
                                                'name', value_labels
                                            ))
                                        FROM
                                            jsonb_array_elements(category_filters.values) AS t(value)
                                    )
                                )
                            )
                        FROM
                            category_filters
                            LEFT JOIN property_labels ON
                                property_labels.property = category_filters.property
                        WHERE
                            category_id = categories.id
                    )
                )
            )
        )
    FROM
        menu_items
        LEFT JOIN menu_groups ON
            menu_groups.id = menu_items.menu_group_id
        LEFT JOIN categories ON
            categories.id = menu_items.category_id
    WHERE
        menu_items.theme_id = theme_id
    ;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS postgisftw.pois;
CREATE OR REPLACE FUNCTION postgisftw.pois(
    -- category_slug text
    _category_id integer
) RETURNS TABLE (
    d jsonb
) AS $$
    SELECT
        jsonb_build_object(
            'type', 'FeatureCollection',
            'features', coalesce(jsonb_agg(feature), '[]'::jsonb)
        )
    FROM (
        SELECT
            jsonb_build_object(
                'type', 'Feature',
                -- 'id', poi_tourinsoft.id,
                'geometry', ST_AsGeoJSON(geom)::jsonb,
                'properties',
                    to_jsonb(poi_tourinsoft.properties) ||
                    jsonb_build_object(
                        'metadata', jsonb_build_object(
                            'id', poi_tourinsoft.id -- slug
                        ),
                        'editorial', jsonb_build_object(
                            'popup_properties', sources_tourinsoft.popup_properties,
                            'class_label', sources_tourinsoft.label,
                            'class_label_popup', sources_tourinsoft.label_popup,
                            'class_label_details', sources_tourinsoft.label_details,
                            'website:details', CASE WHEN sources_tourinsoft.details_enable THEN 'https://www.teritorio.fr/' END -- TODO generate detail URL
                        ),
                        'display', jsonb_build_object(
                            'icon', categories.icon,
                            'color', categories.color,
                            'tourism_style_class', categories.tourism_style_class
                        )
                    )
            ) AS feature
        FROM
            poi_tourinsoft
            JOIN sources_tourinsoft ON
                sources_tourinsoft.id = poi_tourinsoft.source_tourinsoft_id
            JOIN categorie_sources_tourinsoft ON
                categorie_sources_tourinsoft.source_tourinsoft_id = poi_tourinsoft.source_tourinsoft_id
            JOIN categories ON
                categories.id = categorie_sources_tourinsoft.category_id AND
                -- categories.slug = category_slug
                categories.id = _category_id
    ) AS t
    ;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;
