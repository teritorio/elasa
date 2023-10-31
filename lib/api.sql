CREATE SCHEMA IF NOT EXISTS postgisftw;

DROP FUNCTION IF EXISTS postgisftw.id_from_slugs;
CREATE FUNCTION postgisftw.id_from_slugs(slugs json) RETURNS integer AS $$
    SELECT
        coalesce(
            (slugs->>'original_id')::integer,
            (
                'x' ||
                substr(
                    md5(
                        coalesce(
                            slugs->>'fr',
                            slugs->>'en'
                        )
                    ),
                    1, 8
                )
            )::bit(32)::integer
        )
    ;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;

DROP FUNCTION IF EXISTS postgisftw.project;
CREATE OR REPLACE FUNCTION postgisftw.project(
    _project_slug text
) RETURNS TABLE (
    d jsonb
) AS $$
    SELECT
        jsonb_strip_nulls(
            to_jsonb(projects.*) - 'name' - 'polygon' - 'bbox_line' ||
            jsonb_build_object(
                'name', projects.name->'fr',
                'polygon', jsonb_build_object(
                    'type', 'geojson',
                    'data', ST_AsGeoJSON(projects.polygon)::jsonb - 'crs'
                ),
                'bbox_line', ST_AsGeoJSON(projects.bbox_line)::jsonb - 'crs',
                'attributions', (
                    SELECT
                        array_agg(DISTINCT attribution)
                    FROM
                        sources
                    WHERE
                        sources.project_id = projects.id AND
                        attribution IS NOT NULL
                ),
                'themes', (
                    SELECT
                        jsonb_agg(
                            to_jsonb(themes.*)
                                - 'project_id' - 'root_menu_item_id'
                                - 'name' - 'keywords'
                                - 'explorer_mode' - 'favorites_mode' ||
                            jsonb_build_object(
                                'title', themes.name,
                                'keywords', nullif(coalesce(themes.keywords->>'fr', ''), ''),
                                'explorer_mode', nullif(explorer_mode, true),
                                'favorites_mode', nullif(favorites_mode, true)
                            )
                        )
                    FROM
                        themes
                    WHERE
                        themes.project_id = projects.id
                )
            )
        ) AS project
    FROM
        projects
    WHERE
        projects.slug = _project_slug
    ;
$$ LANGUAGE sql PARALLEL SAFE;


DROP FUNCTION IF EXISTS postgisftw.filter_values;
CREATE OR REPLACE FUNCTION postgisftw.filter_values(
    _project_id integer,
    _menu_items_id integer,
    _property text
) RETURNS jsonb AS $$
    WITH
    translation AS (
        SELECT
            values_translations
        FROM
            translations
        WHERE
            project_id = project_id AND
            key = _property
        LIMIT 1
    ),
    properties AS (
        SELECT
            coalesce(
                jsonb_path_query_first((pois.properties->'tags')::jsonb, ('$.' || CASE WHEN _property LIKE 'route:%' OR _property LIKE 'addr:%' THEN replace(_property, ':', '.') ELSE '"' || _property || '"' END)::jsonpath),
                jsonb_path_query_first((pois.properties->'natives')::jsonb, ('$.' || CASE WHEN _property LIKE 'route:%' OR _property LIKE 'addr:%' THEN replace(_property, ':', '.') ELSE '"' || _property || '"'  END)::jsonpath)
            ) AS property
        FROM
            menu_items_sources
            JOIN sources ON
                sources.id = menu_items_sources.sources_id
            JOIN pois ON
                pois.source_id = sources.id
        WHERE
            menu_items_sources.menu_items_id = _menu_items_id
    ),
    values AS (
        SELECT
            jsonb_array_elements_text(
                CASE jsonb_typeof(property)
                wHEN 'array' THEN property
                ELSE jsonb_build_array(property)
                END
            ) AS value
        FROM
            properties
        WHERE
            property is not NULL
    ),
    values_uniq AS (
        SELECT
            DISTINCT value
        FROM
            values
    )
    SELECT
        jsonb_strip_nulls(
            jsonb_agg(
                jsonb_build_object(
                    'value', value,
                    'name',
                        CASE WHEN translation.values_translations IS NOT NULL THEN
                            jsonb_build_object(
                                'fr', translation.values_translations->value->'@default'->'fr'
                            )
                        END
                )
            )
        )
    FROM
        values_uniq
        LEFT JOIN translation ON true
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
                'id', postgisftw.id_from_slugs(menu_items.slugs),
                'parent_id', postgisftw.id_from_slugs(parent_menu_items.slugs),
                'index_order', menu_items.index_order,
                'hidden', menu_items.hidden,
                'selected_by_default', menu_items.selected_by_default,
                'menu_group', CASE WHEN menu_items.type = 'menu_group' THEN
                    jsonb_build_object(
                        'slug', menu_items.slugs->'fr',
                        'name', menu_items.name,
                        'icon', menu_items.icon,
                        'color_fill', menu_items.color_fill,
                        'color_line', menu_items.color_line,
                        'display_mode', menu_items.display_mode
                    )
                END,
                'category', CASE WHEN menu_items.type = 'category' THEN
                    jsonb_build_object(
                        'slug', menu_items.slugs->'fr',
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
                                            'values', postgisftw.filter_values(projects.id, menu_items.id, filters.multiselection_property)
                                        )
                                    WHEN 'checkboxes_list' THEN
                                        jsonb_build_object(
                                            'property', filters.checkboxes_list_property,
                                            'values', postgisftw.filter_values(projects.id, menu_items.id, filters.checkboxes_list_property)
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
                                menu_items_filters.menu_items_id = menu_items.id AND
                                (filters.type != 'multiselection' OR postgisftw.filter_values(projects.id, menu_items.id, filters.multiselection_property) IS NOT NULL) AND
                                (filters.type != 'checkboxes_list' OR postgisftw.filter_values(projects.id, menu_items.id, filters.checkboxes_list_property) IS NOT NULL)
                        )
                    )
                END,
                'link', CASE WHEN menu_items.type = 'link' THEN
                    jsonb_build_object(
                        'slug', menu_items.slugs->'fr',
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
        LEFT JOIN theme_menu_items AS parent_menu_items ON
            parent_menu_items.id = menu_items.parent_id AND
            parent_menu_items.id != themes.root_menu_item_id -- Excludes root menu
    WHERE
        projects.slug = _project_slug
    ;
$$ LANGUAGE sql PARALLEL SAFE;


DROP FUNCTION IF EXISTS postgisftw.fields;
CREATE OR REPLACE FUNCTION postgisftw.fields(
    _root_field_id integer
) RETURNS jsonb AS $$
    WITH
    a AS (
        -- Recursive down
        WITH RECURSIVE a AS (
            SELECT
                fields.id,
                fields_fields.related_fields_id AS children_id,
                fields_fields."index"
            FROM
                fields
                LEFT JOIN fields_fields ON
                    fields_fields.fields_id = fields.id
            WHERE
                fields.id = _root_field_id
        UNION ALL
            SELECT
                fields.id,
                fields_fields.related_fields_id AS children_id,
                fields_fields."index"
            FROM
                a
                JOIN fields ON
                    fields.id = a.children_id
                LEFT JOIN fields_fields ON
                    fields_fields.fields_id = fields.id
        )
        SELECT
            *
        FROM
            a
    ),
    b AS (
        -- Recursive up, manualy
        SELECT
            a.id,
            jsonb_strip_nulls(jsonb_build_object(
                'field', field,
                'group', "group",
                'display_mode', display_mode,
                'icon', icon
                -- 'fields', null
            )) AS json
        FROM
            a
            JOIN fields ON
                fields.id = a.id
        WHERE
            "index" IS NULL -- leaf
    ),
    c AS (
        SELECT
            a.id,
            jsonb_strip_nulls(jsonb_build_object(
                'field', field,
                'group', "group",
                'display_mode', display_mode,
                'icon', icon,
                'fields', jsonb_agg(json ORDER BY "index")
            )) as json
        FROM
            a
            JOIN b ON
                b.id = a.children_id
            JOIN fields ON
                fields.id = a.id
        GROUP BY
            a.id,
            fields.id,
            fields.field,
            fields."group",
            fields.display_mode,
            fields.icon
    ),
    d AS (
        SELECT
            id,
            json
        FROM
            c
        WHERE
            id = _root_field_id
    UNION ALL
        SELECT
            a.id,
            jsonb_strip_nulls(jsonb_build_object(
                'field', field,
                'group', "group",
                'display_mode', display_mode,
                'icon', icon,
                'fields', jsonb_agg(json ORDER BY "index")
            )) as json
        FROM
            a
            JOIN c ON
                c.id = a.children_id
            JOIN fields ON
                fields.id = a.id
        WHERE
            c.id != _root_field_id
        GROUP BY
            a.id,
            fields.id,
            fields.field,
            fields."group",
            fields.display_mode,
            fields.icon
    )
    SELECT
        json
    FROM
        d
    ;
$$ LANGUAGE sql PARALLEL SAFE;


-- Function inspired by https://stackoverflow.com/questions/45585462/recursively-flatten-a-nested-jsonb-in-postgres-without-unknown-depth-and-unknown
DROP FUNCTION IF EXISTS postgisftw.json_flat;
CREATE OR REPLACE FUNCTION postgisftw.json_flat(
    _prefix text,
    _json jsonb
) RETURNS jsonb AS $$
    WITH RECURSIVE flat (key, value) AS (
        SELECT
            key, value
        FROM
            jsonb_each(_json)
    UNION
        SELECT
            concat(f.key, ':', j.key), j.value
        FROM
            flat f,
            jsonb_each(f.value) j
        WHERE
            jsonb_typeof(f.value) = 'object'
    )
    SELECT
        jsonb_object_agg(_prefix || ':' || key, value) AS data
    FROM
        flat
    WHERE
        jsonb_typeof(value) <> 'object'
    ;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;


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
                        - 'addr' - 'ref' - 'route' - 'source' ||
                    coalesce(postgisftw.json_flat('addr', pois.properties->'tags'->'addr'), '{}'::jsonb) ||
                    coalesce(postgisftw.json_flat('ref', pois.properties->'tags'->'ref'), '{}'::jsonb) ||
                    coalesce(postgisftw.json_flat('route', (pois.properties->'tags'->'route') - 'pdf' || jsonb_build_object('pdf', pois.properties->'tags'->'route'->'pdf'->'fr')), '{}'::jsonb) ||
                    coalesce(postgisftw.json_flat('source', pois.properties->'tags'->'source'), '{}'::jsonb) ||
                    coalesce(pois.properties->'natives', '{}'::jsonb) ||
                    jsonb_build_object(
                        'name', pois.properties->'tags'->'name'->'fr',
                        'description',
                            CASE _short_description
                            -- TODO strip html tags before substr
                            WHEN 'true' THEN substr(pois.properties->'tags'->'description'->>'fr', 1, 20)
                            ELSE pois.properties->'tags'->'description'->>'fr'
                            END,
                        'metadata', jsonb_build_object(
                            'id', postgisftw.id_from_slugs(pois.slugs), -- use slug as original POI id
                            -- cartocode
                            'category_ids', array_agg(menu_items.id), -- FIXME Should be all menu_items.id not just one from the current selection
                            'updated_at', pois.properties->'updated_at',
                            'source', pois.properties->'source',
                            'osm_id', CASE WHEN pois.properties->>'source' LIKE '%openstreetmap%' THEN substr(pois.properties->>'id', 2)::bigint END,
                            'osm_type',
                                CASE WHEN pois.properties->>'source' LIKE '%openstreetmap%' THEN
                                    CASE substr(pois.properties->>'id', 1, 1)
                                    WHEN 'n' THEN 'node'
                                    WHEN 'w' THEN 'way'
                                    WHEN 'r' THEN 'relation'
                                    END
                                END
                        ),
                        'editorial', jsonb_build_object(
                            'popup_fields', postgisftw.fields((array_agg(menu_items.popup_fields_id ORDER BY menu_items.id))[1])->'fields',
                            'details_fields', postgisftw.fields((array_agg(menu_items.details_fields_id ORDER BY menu_items.id))[1])->'fields',
                            'list_fields', postgisftw.fields((array_agg(menu_items.list_fields_id ORDER BY menu_items.id))[1])->'fields',
                            'class_label', jsonb_build_object('fr', (array_agg(menu_items.name->'fr' ORDER BY menu_items.id))[1]),
                            'class_label_popup', jsonb_build_object('fr', (array_agg(menu_items.name_singular->'fr' ORDER BY menu_items.id))[1]),
                            'class_label_details', jsonb_build_object('fr', (array_agg(menu_items.name_singular->'fr' ORDER BY menu_items.id))[1]),
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
            projects
            JOIN themes ON
                themes.project_id = projects.id AND
                themes.slug = _theme_slug
            JOIN menu_items ON
                menu_items.theme_id = themes.id AND
                (_category_id IS NULL OR postgisftw.id_from_slugs(menu_items.slugs) = _category_id)
            JOIN menu_items_sources ON
                menu_items_sources.menu_items_id = menu_items.id
            JOIN sources ON
                sources.project_id = projects.id AND
                sources.id = menu_items_sources.sources_id
            JOIN pois ON
                pois.source_id = sources.id
        WHERE
            projects.slug = _project_slug AND
            (_poi_ids IS NULL OR (
                postgisftw.id_from_slugs(pois.slugs) = ANY(_poi_ids) OR
                (_with_deps = true AND pois.properties->>'id' = ANY (SELECT jsonb_array_elements_text(properties->'refs') FROM pois WHERE pois.slugs->>'original_id' = ANY(_poi_ids::text[])))
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


DROP FUNCTION IF EXISTS postgisftw.attribute_translations;
CREATE OR REPLACE FUNCTION postgisftw.attribute_translations(
    _project_slug text,
    _theme_slug text,
    _lang text
) RETURNS TABLE (
    d jsonb
) AS $$
    SELECT
        jsonb_strip_nulls(jsonb_object_agg(
            key, jsonb_build_object(
                'label', jsonb_build_object(
                    'fr', key_translations->'@default'->_lang
                ),
                'values', (
                    SELECT
                        jsonb_object_agg(
                            key, jsonb_build_object(
                                'label', jsonb_build_object(
                                    'fr', value->'@default:full'->_lang
                                )
                            )
                        )
                    FROM
                        json_each(values_translations)
                )
            )
        ))
    FROM
        translations
    JOIN projects ON
        projects.slug = _project_slug
    ;
$$ LANGUAGE sql PARALLEL SAFE;
