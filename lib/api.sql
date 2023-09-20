CREATE SCHEMA IF NOT EXISTS postgisftw;

DROP FUNCTION IF EXISTS postgisftw.project;
CREATE OR REPLACE FUNCTION postgisftw.project(
    _project_slug text
) RETURNS TABLE (
    d jsonb
) AS $$
    SELECT
        to_jsonb(projects.*) - 'polygon' - 'bbox_line' ||
        jsonb_build_object(
            'polygon', jsonb_build_object(
                'type', 'geojson',
                'data', ST_AsGeoJSON(projects.polygon)::jsonb - 'crs'
            ),
            'bbox_line', jsonb_build_object(
                'type', 'geojson',
                'data', ST_AsGeoJSON(projects.bbox_line)::jsonb - 'crs'
            ),
            'themes', (
                SELECT
                    json_agg(to_jsonb(themes.*) - 'project_id' - 'name' - 'root_menu_item_id')
                FROM
                    themes
                WHERE
                    themes.project_id = projects.id
            )
        ) AS project
    FROM
        projects
    WHERE
        projects.slug = _project_slug
    ;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS postgisftw.menu;
CREATE OR REPLACE FUNCTION postgisftw.menu(
    _project_slug text,
    _theme_slug text
) RETURNS TABLE (
    d jsonb
) AS $$
    SELECT
        jsonb_agg(
            jsonb_strip_nulls(jsonb_build_object(
                'id', menu_items.id,
                'parent_id', menu_items.parent_id,
                'index_order', menu_items.index_order,
                'hidden', menu_items.hidden,
                'selected_by_default', menu_items.selected_by_default,
                'menu_group', CASE WHEN
                    menu_items_sources.menu_items_id IS NULL AND
                    menu_items.href IS NULL THEN
                    jsonb_build_object(
                        'id', menu_items.id,
                        'slug', menu_items.slug,
                        'name', menu_items.name,
                        'icon', menu_items.icon,
                        'color_fill', menu_items.color_fill,
                        'color_line', menu_items.color_line,
                        'style_class', menu_items.style_class
                    )
                END,
                'category', CASE WHEN
                    menu_items_sources.menu_items_id IS NOT NULL AND
                    menu_items.href IS NULL THEN
                    jsonb_build_object(
                        'id', menu_items.id,
                        'slug', menu_items.slug,
                        'name', menu_items.name,
                        'search_indexed', menu_items.search_indexed,
                        'icon', menu_items.icon,
                        'color_fill', menu_items.color_fill,
                        'color_line', menu_items.color_line,
                        'style_class', menu_items.style_class,
                        'style_merge', menu_items.style_merge,
                        'display_mode', menu_items.display_mode,
                        'zoom', menu_items.zoom,
                        'filters', (
                            SELECT
                                jsonb_agg(
                                    jsonb_build_object(
                                        'type', filters.type,
                                        'name', filters.name
                                    ) ||
                                    CASE filters.type
                                    WHEN 'multiselection' THEN
                                        jsonb_build_object(
                                            'property', filters.multiselection_property
                                            -- TODO ---------------------------
                                            -- value:
                                            --   type: string
                                            -- name:
                                            --   $ref: '#/components/schemas/multilingual_string'
                                        )
                                    WHEN 'checkboxes_list' THEN
                                        jsonb_build_object(
                                            'property', filters.checkboxes_list_property
                                            -- TODO ---------------------------
                                            -- value:
                                            --   type: string
                                            -- name:
                                            --   $ref: '#/components/schemas/multilingual_string'
                                        )
                                    WHEN 'boolean' THEN
                                        jsonb_build_object(
                                            'property', filters.boolean_property
                                        )
                                    WHEN 'date_range' THEN
                                        jsonb_build_object(
                                            'property_begin', filters.property_begin,
                                            'property_end', filters.property_end
                                        )
                                    WHEN 'number_range' THEN
                                        jsonb_build_object(
                                            'property', filters.number_range_property,
                                            'min', filters.min,
                                            'max', filters.max
                                        )
                                    END
                                )
                            FROM
                                menu_items_filters
                                JOIN filters ON
                                    filters.id = menu_items_filters.filters_id
                            WHERE
                                menu_items_filters.menu_items_id = menu_items_id
                        )
                    )
                END,
                'link', CASE WHEN
                    menu_items_sources.menu_items_id IS NULL AND
                    menu_items.href IS NOT NULL THEN
                    jsonb_build_object(
                        'id', menu_items.id,
                        'slug', menu_items.slug,
                        'name', menu_items.name,
                        'href', menu_items.href,
                        'icon', menu_items.icon,
                        'color_fill', menu_items.color_fill,
                        'color_line', menu_items.color_line
                    )
                END
            ))
        )
    FROM
        projects
        JOIN themes ON
            themes.project_id = projects.id AND
            themes.slug = _theme_slug
        JOIN menu_items ON
            menu_items.theme_id = themes.id
        LEFT JOIN menu_items_sources ON
            menu_items_sources.menu_items_id = menu_items.id
    WHERE
        projects.slug = _project_slug
    ;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS postgisftw.pois;
CREATE OR REPLACE FUNCTION postgisftw.pois(
    _project_slug text,
    _theme_slug text
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
            jsonb_strip_nulls(jsonb_build_object(
                'type', 'Feature',
                'geometry', ST_AsGeoJSON(pois.geom)::jsonb,
                'properties',
                    (pois.properties->'tags')
                        - 'name' - 'description' - 'website:details'
                        - 'addr' - 'ref' ||
                    coalesce(pois.properties->'natives', '{}'::jsonb) ||
                    jsonb_build_object(
                        'name', pois.properties->'tags'->'name'->'fr',
                        'description', pois.properties->'tags'->'description'->'fr',
                        'website:details', pois.properties->'tags'->'website:details'->'fr',
                        -- addr
                        'addr:street', pois.properties->'tags'->'addr'->'street',
                        'addr:street', pois.properties->'tags'->'addr'->'street',
                        'addr:hamlet', pois.properties->'tags'->'addr'->'hamlet',
                        'addr:postcode', pois.properties->'tags'->'addr'->'postcode',
                        'addr:city', pois.properties->'tags'->'addr'->'city',
                        'addr:country', pois.properties->'tags'->'addr'->'country',
                        -- ref
                        'ref:FR:CRTA', pois.properties->'tags'->'ref'->'FR:CRTA',

                        'metadata', jsonb_build_object(
                            -- 'id', pois.properties->'id',
                            -- cartocode
                            'category_ids', array_agg(menu_items.id),
                            'updated_at', pois.properties->'updated_at',
                            'source', pois.properties->'source'
                            -- osm_id
                            -- osm_type
                        ),
                        'editorial', jsonb_build_object(
                            -- 'popup_fields',
                            -- 'details_fields',
                            -- 'list_fields',
                            -- 'class_label',
                            -- 'class_label_popup',
                            -- 'class_label_details',
                            -- 'website:details',
                            -- 'unavoidable'
                        ),
                        'display', jsonb_build_object(
                            'icon', (array_agg(menu_items.icon ORDER BY menu_items.id))[1],
                            'color_fill', (array_agg(menu_items.color_fill ORDER BY menu_items.id))[1],
                            'color_line', (array_agg(menu_items.color_line ORDER BY menu_items.id))[1],
                            'style_class', (array_agg(array_to_json(menu_items.style_class) ORDER BY menu_items.id))[1]
                        )
                    )
            )) AS feature
        FROM
            -- TODO only menu_items recursively from theme
            pois
            JOIN sources ON
                sources.id = pois.source_id
            JOIN projects ON
                projects.id = sources.project_id AND
                projects.slug = _project_slug
            JOIN themes ON
                themes.project_id = projects.id AND
                themes.slug = _theme_slug
            JOIN menu_items ON
                menu_items.theme_id = themes.id
            JOIN menu_items_sources ON
                menu_items_sources.menu_items_id = menu_items.id AND
                menu_items_sources.sources_id = sources.id
        GROUP BY
            pois.id,
            pois.properties,
            pois.geom
    ) AS t
    ;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;
