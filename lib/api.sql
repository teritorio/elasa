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
            'bbox_line', ST_AsGeoJSON(projects.bbox_line)::jsonb - 'crs',
            'attributions', '[]'::jsonb, -- TODO compute from sources
            'themes', (
                SELECT
                    jsonb_agg(
                        to_jsonb(themes.*)
                            - 'project_id' - 'root_menu_item_id'
                            - 'name' - 'keywords' ||
                        jsonb_build_object(
                            'title', themes.name,
                            'keywords', coalesce(themes.keywords->>'fr', '')
                        )
                    )
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
$$ LANGUAGE sql PARALLEL SAFE;


DROP FUNCTION IF EXISTS postgisftw.menu;
CREATE OR REPLACE FUNCTION postgisftw.menu(
    _project_slug text,
    _theme_slug text
) RETURNS TABLE (
    d jsonb
) AS $$
    WITH RECURSIVE theme_menu_items AS (
        SELECT
            menu_items.*
        FROM
            projects
            JOIN themes ON
                themes.project_id = projects.id AND
                themes.slug = _theme_slug
            JOIN menu_items ON
                menu_items.id = themes.root_menu_item_id
        WHERE
            projects.slug = _project_slug

        UNION ALL

        SELECT
            menu_items.*
        FROM
            theme_menu_items
            JOIN menu_items ON
                menu_items.parent_id = theme_menu_items.id
    )
    SELECT
        jsonb_agg(
            jsonb_strip_nulls(jsonb_build_object(
                'id', menu_items.id,
                'parent_id', nullif(menu_items.parent_id, themes.root_menu_item_id), -- Excludes root menu
                'index_order', menu_items.index_order,
                'hidden', menu_items.hidden,
                'selected_by_default', menu_items.selected_by_default,
                'menu_group', CASE WHEN type = 'menu_group' THEN
                    jsonb_build_object(
                        'slug', menu_items.slug,
                        'name', menu_items.name,
                        'icon', menu_items.icon,
                        'color_fill', menu_items.color_fill,
                        'color_line', menu_items.color_line,
                        'display_mode', menu_items.display_mode
                    )
                END,
                'category', CASE WHEN type = 'category' THEN
                    jsonb_build_object(
                        'slug', menu_items.slug,
                        'name', menu_items.name,
                        'search_indexed', menu_items.search_indexed,
                        'icon', menu_items.icon,
                        'color_fill', menu_items.color_fill,
                        'color_line', menu_items.color_line,
                        'style_class', menu_items.style_class,
                        'display_mode', menu_items.display_mode,
                        'style_merge', menu_items.style_merge,
                        'zoom', coalesce(menu_items.zoom, 16),
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
                                            'property', filters.multiselection_property,
                                            'values', '{}'::jsonb -- TODO ---------------------------
                                        )
                                    WHEN 'checkboxes_list' THEN
                                        jsonb_build_object(
                                            'property', filters.checkboxes_list_property,
                                            'values', '{}'::jsonb -- TODO ---------------------------
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
                                menu_items_filters.menu_items_id = menu_items.id
                        )
                    )
                END,
                'link', CASE WHEN type = 'link' THEN
                    jsonb_build_object(
                        'slug', menu_items.slug,
                        'name', menu_items.name,
                        'href', menu_items.href,
                        'icon', menu_items.icon,
                        'color_fill', menu_items.color_fill,
                        'color_line', menu_items.color_line,
                        'display_mode', menu_items.display_mode
                    )
                END
            ))
        )
    FROM
        projects
        JOIN themes ON
            themes.project_id = projects.id AND
            themes.slug = _theme_slug
        JOIN theme_menu_items AS menu_items ON
            -- Excludes root menu
            menu_items.id != themes.root_menu_item_id
    ;
$$ LANGUAGE sql PARALLEL SAFE;


DROP FUNCTION IF EXISTS postgisftw.fields;
CREATE OR REPLACE FUNCTION postgisftw.fields(
    _root_field_id integer
) RETURNS jsonb AS $$
    SELECT
        jsonb_strip_nulls(jsonb_build_object(
            'field', field,
            'group', "group",
            'display_mode', display_mode,
            'icon', icon,
            'fields', nullif(
                jsonb_agg(postgisftw.fields(fields_fields.related_fields_id) ORDER BY "index"),
                '[null]'::jsonb
            )
        ))
    FROM
        fields
        LEFT JOIN fields_fields ON
            fields_fields.fields_id = fields.id
    WHERE
        fields.id = _root_field_id
    GROUP BY
        fields.id,
        fields.field,
        fields."group",
        fields.display_mode,
        fields.icon
    ;
$$ LANGUAGE sql PARALLEL SAFE;



DROP FUNCTION IF EXISTS postgisftw.pois;
CREATE OR REPLACE FUNCTION postgisftw.pois(
    _project_slug text,
    _theme_slug text,
    _category_id integer,
    _poi_ids integer[],
    _geometry_as text,
    _short_description boolean,
    _start_date text,
    _end_date text,
    _with_deps boolean
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
                'geometry',
                    CASE _geometry_as
                    WHEN 'point' THEN ST_AsGeoJSON(ST_PointOnSurface(pois.geom))::jsonb
                    WHEN 'bbox' THEN ST_AsGeoJSON(ST_Envelope(pois.geom))::jsonb
                    ELSE ST_AsGeoJSON(pois.geom)::jsonb
                    END,
                'properties',
                    (pois.properties->'tags')
                        - 'name' - 'description' - 'website:details'
                        - 'addr' - 'ref' ||
                    coalesce(pois.properties->'natives', '{}'::jsonb) ||
                    jsonb_build_object(
                        'name', pois.properties->'tags'->'name'->'fr',
                        'description',
                            CASE _short_description
                            -- TODO strip html tags before substr
                            WHEN 'true' THEN substr(pois.properties->'tags'->'description'->>'fr', 1, 20)
                            ELSE pois.properties->'tags'->'description'->>'fr'
                            END,
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
                            'id', pois.id, -- TODO use public id / slug
                            -- cartocode
                            'category_ids', array_agg(menu_items.id), -- FIXME Should be all menu_items.id not just one from the current selection
                            'updated_at', pois.properties->'updated_at',
                            'source', pois.properties->'source'
                            -- osm_id
                            -- osm_type
                        ),
                        'editorial', jsonb_build_object(
                            'popup_fields', postgisftw.fields((array_agg(menu_items.popup_fields_id ORDER BY menu_items.id))[1])->'fields',
                            'details_fields', postgisftw.fields((array_agg(menu_items.details_fields_id ORDER BY menu_items.id))[1])->'fields',
                            'list_fields', postgisftw.fields((array_agg(menu_items.list_fields_id ORDER BY menu_items.id))[1])->'fields',
                            -- 'class_label', (array_agg(menu_items.class_label ORDER BY menu_items.id))[1], -- TODO -------
                            -- 'class_label_popup', (array_agg(menu_items.class_label_popup ORDER BY menu_items.id))[1], -- TODO -------
                            -- 'class_label_details', (array_agg(menu_items.class_label_details ORDER BY menu_items.id))[1], -- TODO -------
                            'website:details', pois.properties->'tags'->'website:details'->'fr'
                            -- 'unavoidable', (array_agg(menu_items.unavoidable ORDER BY menu_items.id))[1] -- TODO -------
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
            -- TODO only for not hidden menu_items, recursively from theme
            pois
            JOIN projects ON
                projects.slug = _project_slug
            JOIN themes ON
                themes.project_id = projects.id AND
                themes.slug = _theme_slug
            JOIN menu_items ON
                menu_items.theme_id = themes.id AND
                (_category_id IS NULL OR menu_items.id = _category_id)
            JOIN sources ON
                sources.project_id = projects.id
            JOIN menu_items_sources ON
                menu_items_sources.menu_items_id = menu_items.id AND
                menu_items_sources.sources_id = sources.id
        WHERE
            pois.source_id = sources.id AND
            (_poi_ids IS NULL OR (
                pois.id = ANY(_poi_ids) OR
                (_with_deps = true AND pois.properties->>'id' = ANY (SELECT jsonb_array_elements_text(properties->'refs') FROM pois WHERE pois.id = ANY(_poi_ids)))
            )) AND
            (_start_date IS NULL OR pois.properties->'tag'->>'start_date' IS NULL OR pois.properties->'tag'->>'start_date' <= _start_date) AND
            (_end_date IS NULL OR pois.properties->'tag'->>'end_date' IS NULL OR pois.properties->'tag'->>'end_date' >= _end_date)
        GROUP BY
            pois.id,
            pois.properties,
            pois.geom
    ) AS t
    ;
$$ LANGUAGE sql PARALLEL SAFE;
