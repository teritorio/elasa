CREATE SCHEMA IF NOT EXISTS api01;
SET search_path TO api01,public;

DROP VIEW IF EXISTS projects_join;
CREATE VIEW projects_join AS
SELECT
    projects.*,
    jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.name) AS name
FROM
    projects
    JOIN projects_translations AS trans ON
        trans.projects_id = projects.id
GROUP BY
    projects.id
;

DROP VIEW IF EXISTS themes_join;
CREATE VIEW themes_join AS
SELECT
    themes.*,
    jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.name) AS name,
    jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.description) AS description,
    jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.site_url) AS site_url,
    jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.main_url) AS main_url,
    jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.keywords) AS keywords
FROM
    themes
    JOIN themes_translations AS trans ON
        trans.themes_id = themes.id
GROUP BY
    themes.id
;

DROP VIEW IF EXISTS menu_items_join;
CREATE VIEW menu_items_join AS
SELECT
    menu_items.*,
    jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.name) AS name,
    jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.name_singular) AS name_singular,
    jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.slug) AS slug
FROM
    menu_items
    JOIN menu_items_translations AS trans ON
        trans.menu_items_id = menu_items.id
GROUP BY
    menu_items.id
;

DROP VIEW IF EXISTS filters_join;
CREATE VIEW filters_join AS
SELECT
    filters.*,
    jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.name) AS name
FROM
    filters
    JOIN filters_translations AS trans ON
        trans.filters_id = filters.id
GROUP BY
    filters.id
;


DROP FUNCTION IF EXISTS capitalize;
CREATE FUNCTION capitalize(str text) RETURNS text AS $$
    SELECT
        upper(substring(str from 1 for 1)) ||
        substring(str from 2 for length(str))
    ;
$$ LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS id_from_slugs;
CREATE FUNCTION id_from_slugs(slugs json, id integer) RETURNS bigint AS $$
    SELECT
        coalesce(
            (slugs->>'original_id')::bigint,
            id
        )
    ;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS id_from_slugs_menu_item;
CREATE FUNCTION id_from_slugs_menu_item(slugs jsonb, id integer) RETURNS bigint AS $$
    SELECT
        coalesce(
            CASE WHEN slugs->>'fr' ~ E'^\\d+$' THEN (slugs->>'fr')::bigint END,
            id
        )
    ;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS project;
CREATE OR REPLACE FUNCTION project(
    _base_url text,
    _project_slug text
) RETURNS TABLE (
    d text
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
                'polygons_extra', (
                    SELECT
                        jsonb_object_agg(
                            key,
                            jsonb_build_object(
                                'type', 'geojson',
                                'data', (SELECT _base_url || '/api/0.1/' || projects.slug || '/' || themes.slug || '/poi/' || (value::text) || '.geojson' FROM themes_join AS themes WHERE themes.project_id = projects.id LIMIT 1)
                            )
                        )
                    FROM
                        json_each_text(polygons_extra)
                ),
                'bbox_line', ST_AsGeoJSON(projects.bbox_line)::jsonb - 'crs',
                'attributions', coalesce((
                    SELECT
                        array_agg(DISTINCT attribution)
                    FROM
                        sources
                    WHERE
                        sources.project_id = projects.id AND
                        attribution IS NOT NULL
                ), array[]::text[]),
                'themes', (
                    SELECT
                        jsonb_strip_nulls(jsonb_agg(
                            to_jsonb(themes.*)
                                - 'project_id' - 'root_menu_item_id'
                                - 'name' - 'keywords'
                                - 'logo' - 'favicon'
                                - 'explorer_mode' - 'favorites_mode' ||
                            jsonb_build_object(
                                'title', themes.name,
                                'keywords', nullif(coalesce(themes.keywords->>'fr', ''), ''),
                                'logo_url', _base_url || '/assets/' || directus_files_logo.id::text || '/' || directus_files_logo.filename_download,
                                'favicon_url', _base_url || '/assets/' || directus_files_favicon.id::text || '/' || directus_files_favicon.filename_download,
                                'explorer_mode', nullif(explorer_mode, true),
                                'favorites_mode', nullif(favorites_mode, true)
                            )
                        ))
                    FROM
                        themes_join AS themes
                        LEFT JOIN directus_files AS directus_files_logo ON
                            directus_files_logo.id = themes.logo
                        LEFT JOIN directus_files AS directus_files_favicon ON
                            directus_files_favicon.id = themes.favicon
                    WHERE
                        themes.project_id = projects.id
                )
            )
        )::text
    FROM
        projects_join AS projects
    WHERE
        projects.slug = _project_slug
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS pois_local;
CREATE OR REPLACE FUNCTION pois_local(
    _base_url text,
    _project_slug text
) RETURNS TABLE (
    id integer,
    geom geometry(Geometry,4326),
    properties jsonb,
    source_id integer,
    slugs json
) AS $$
DECLARE
    source record;
    poi record;
BEGIN
    FOR source IN
        WITH
        projects AS (
            SELECT
                *
            FROM
                projects
            WHERE
                slug = _project_slug
        )
        SELECT
            sources.id,
            tables.table_name,
            regexp_replace(tables.table_name, 'local-[a-z0-9_]+-', '') || '_id' AS local_id,
            tables_t.table_name AS table_name_t,
            tables_i.table_name AS table_name_i,
            array_agg(column_name) AS file_fields
        FROM
            projects
            JOIN sources ON
                sources.project_id = projects.id
            JOIN information_schema.tables ON
                tables.table_name = 'local-' || _project_slug || '-' || sources.slug
            -- Translations
            LEFT JOIN information_schema.tables AS tables_t ON
                tables_t.table_name = tables.table_name || '_t'
            -- Many files fields
            LEFT JOIN information_schema.tables AS tables_i ON
                tables_i.table_name = tables.table_name || '_i'
            -- One file fields
            LEFT JOIN information_schema.table_constraints  ON
                table_constraints.table_name = tables.table_name AND
                table_constraints.table_schema = 'public' AND
                table_constraints.constraint_type = 'FOREIGN KEY'
            LEFT JOIN information_schema.key_column_usage ON
                key_column_usage.constraint_name = table_constraints.constraint_name AND
                key_column_usage.table_schema = 'public' AND
                key_column_usage.table_name = tables.table_name
        GROUP BY
            sources.id,
            tables.table_name,
            tables_t.table_name,
            tables_i.table_name
    LOOP
        FOR poi IN EXECUTE '
            WITH ' ||
            CASE WHEN source.table_name_t IS NULL THEN '' ELSE '
            j AS (
                SELECT
                    "' || source.local_id || '" AS id,
                    substring(languages_code, 1, 2) AS languages_code,
                    (jsonb_each_text(row_to_json(t.*)::jsonb - ''id'' - ''languages_code'' - ''' || source.local_id || ''')).key,
                    (jsonb_each_text(row_to_json(t.*)::jsonb - ''id'' - ''languages_code'' - ''' || source.local_id || ''')).value
                FROM
                    "' || source.table_name_t || '" AS t
            ),
            jj AS (
                SELECT
                    id,
                    key,
                    json_objectagg(
                        languages_code: value
                    ) AS values
                FROM
                    j
                GROUP BY
                    id,
                    key
            ),
            trans AS (
                SELECT
                    id,
                    json_objectagg(key: values)::jsonb AS jsonb
                FROM
                    jj
                GROUP BY
                    id
            ),
            ' END ||
            CASE WHEN source.table_name_i IS NULL THEN '' ELSE '
            pois_files AS (
                SELECT
                    pois_id,
                    nullif(jsonb_agg(to_jsonb(
                        ''' || _base_url || '/assets/'' || pois_files.directus_files_id::text || ''/'' || directus_files.filename_download
                    ) ORDER BY pois_files.index), ''[null]'') AS image
                FROM
                    "' || source.table_name_i || '" AS pois_files
                    LEFT JOIN directus_files ON
                        directus_files.id = pois_files.directus_files_id
                GROUP BY
                    pois_id
            ),
            ' END || '
            z AS (SELECT 0)
            SELECT
                t.id,
                geom,
                jsonb_strip_nulls(jsonb_build_object(
                    ''id'', t.id,
                    ''source'', NULL,
                    ''updated_at'', NULL,
                    ''natives'', jsonb_strip_nulls(
                        row_to_json(t.*)::jsonb - ''id'' - ''geom'' || ' ||
                        CASE WHEN source.table_name_i IS NULL THEN '''{}''::jsonb' ELSE '
                        jsonb_build_object(
                            ''image'', pois_files.image
                        )' END || ' || ' ||
                        CASE WHEN source.table_name_t IS NULL THEN '''{}''::jsonb' ELSE '
                        trans.jsonb' END || ' ||
                        jsonb_build_object(' ||
                            (SELECT array_to_string(array_agg('''' || f || ''', ''' || _base_url || '/assets/'' || "directus_files_' || f || '".id::text || ''/'' || "directus_files_' || f || '".filename_download'), ', ') FROM unnest(source.file_fields) AS fields(f)) ||
                        ')
                    )
                )) AS properties
            FROM
                "' || source.table_name || '" AS t ' ||
                CASE WHEN source.table_name_i IS NULL THEN '' ELSE '
                LEFT JOIN pois_files ON
                    pois_files.pois_id = t.id
                ' END ||
                CASE WHEN source.table_name_t IS NULL THEN '' ELSE '
                LEFT JOIN trans ON
                    trans.id = t.id
                ' END ||
                (SELECT array_to_string(array_agg('LEFT JOIN directus_files AS "directus_files_' || f || '" ON "directus_files_' || f || '".id = "' || f || '"'), ' ') FROM unnest(source.file_fields) AS fields(f)) ||
        ''
        LOOP
            id := poi.id;
            geom := poi.geom;
            properties := poi.properties;
            source_id := source.id;
            slugs := jsonb_build_object('original_id', poi.id);
            RETURN NEXT;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS filter_values;
CREATE OR REPLACE FUNCTION filter_values(
    _base_url text,
    _project_slug text,
    _property text
)  RETURNS TABLE (
    project_id integer,
    menu_items_id integer,
    property text,
    filter_values jsonb
) AS $$
    WITH
    sources AS (
        SELECT
            sources.project_id,
            menu_items_sources.menu_items_id,
            sources.id
        FROM
            menu_items_sources
            JOIN sources ON
                sources.id = menu_items_sources.sources_id
    ),
    pois AS (
        SELECT
            sources.project_id,
            sources.menu_items_id,
            pois.*
        FROM
            pois
            JOIN sources ON
                sources.id = pois.source_id
        WHERE
            jsonb_pois_keys_array(properties) @> ARRAY[split_part(_property, ':', 1)]
        UNION ALL
        SELECT
            sources.project_id,
            sources.menu_items_id,
            pois_local.*,
            NULL::text AS website_details
        FROM
            sources
            JOIN pois_local(_base_url, _project_slug) AS pois_local ON
                pois_local.source_id = sources.id
    ),
    properties_values AS (
        SELECT
            project_id,
            menu_items_id,
            coalesce(
                jsonb_path_query_first((pois.properties->'tags')::jsonb, ('$.' || CASE WHEN _property LIKE 'route:%' OR _property LIKE 'addr:%' THEN replace(_property, ':', '.') ELSE '"' || _property || '"' END)::jsonpath),
                jsonb_path_query_first((pois.properties->'natives')::jsonb, ('$.' || '"' || _property || '"')::jsonpath)
            ) AS property
        FROM
            pois
    ),
    values AS (
        SELECT
            project_id,
            menu_items_id,
            jsonb_array_elements_text(
                CASE jsonb_typeof(property)
                wHEN 'array' THEN property
                ELSE jsonb_build_array(property)
                END
            ) AS value
        FROM
            properties_values
        WHERE
            property IS NOT NULL AND
            property != 'null'::jsonb
    ),
    values_uniq AS (
        SELECT DISTINCT ON (project_id, menu_items_id, value)
            project_id,
            menu_items_id,
            value
        FROM
            values
        ORDER BY
            project_id,
            menu_items_id,
            value
    )
    SELECT
        values_uniq.project_id,
        menu_items_id,
        _property AS property,
        jsonb_strip_nulls(
            jsonb_agg(
                jsonb_build_object(
                    'value', value,
                    'name',
                        CASE WHEN translations.values_translations IS NOT NULL THEN
                            jsonb_build_object(
                                'fr', translations.values_translations->value->'@default'->'fr'
                            )
                        END
                )
            )
        ) AS filter_values
    FROM
        values_uniq
        LEFT JOIN translations ON
            translations.project_id = values_uniq.project_id AND
            translations.key = _property
    GROUP BY
        values_uniq.project_id,
        menu_items_id
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS menu;
CREATE OR REPLACE FUNCTION menu(
    _base_url text,
    _project_slug text,
    _theme_slug text
) RETURNS TABLE (
    d text
) AS $$
    WITH
    RECURSIVE theme_menu_items AS (
        SELECT
            menu_items.*,
            NULL::bigint AS parent_slug_id
        FROM
            projects
            JOIN themes ON
                themes.project_id = projects.id AND
                themes.slug = _theme_slug
            JOIN menu_items_join AS menu_items ON
                menu_items.id = themes.root_menu_item_id
        WHERE
            projects.slug = _project_slug

        UNION ALL

        SELECT
            menu_items.*,
            CASE
                WHEN theme_menu_items.parent_slug_id IS NULL THEN 0
                ELSE id_from_slugs_menu_item(theme_menu_items.slug, theme_menu_items.id)
            END AS parent_slug_id
        FROM
            theme_menu_items
            JOIN menu_items_join AS menu_items ON
                menu_items.parent_id = theme_menu_items.id
    ),
    theme_menu_items_filters AS (
        SELECT
            menu_items.id,
            menu_items.index_order,
            menu_items.hidden,
            menu_items.selected_by_default,
            menu_items.parent_id,
            menu_items.project_id,
            menu_items.icon,
            menu_items.display_mode,
            menu_items.search_indexed,
            menu_items.style_merge,
            menu_items.zoom,
            menu_items.color_fill,
            menu_items.color_line,
            menu_items.href,
            menu_items.style_class_string,
            menu_items.style_class,
            menu_items.type,
            menu_items.popup_fields_id,
            menu_items.details_fields_id,
            menu_items.list_fields_id,
            menu_items.use_internal_details_link,
            menu_items.use_external_details_link,
            menu_items.name,
            menu_items.name_singular,
            menu_items.slug,
            menu_items.parent_slug_id,
            nullif(jsonb_agg(
                jsonb_build_object(
                    'type', filters.type,
                    'name', filters.name
                ) ||
                CASE filters.type
                WHEN 'multiselection' THEN
                    jsonb_build_object(
                        'property', filters.multiselection_property,
                        'values', coalesce(
                            (SELECT filter_values FROM filter_values(_base_url, _project_slug, filters.multiselection_property) AS f WHERE f.project_id = menu_items.project_id AND f.menu_items_id = menu_items.id),
                            '[]'::jsonb
                        )
                    )
                WHEN 'checkboxes_list' THEN
                    jsonb_build_object(
                        'property', filters.checkboxes_list_property,
                        'values', coalesce(
                            (SELECT filter_values FROM filter_values(_base_url, _project_slug, filters.checkboxes_list_property) AS f WHERE f.project_id = menu_items.project_id AND f.menu_items_id = menu_items.id),
                            '[]'::jsonb
                        )
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
            ), '[null]'::jsonb) AS filters
        FROM
            theme_menu_items AS menu_items
            LEFT JOIN menu_items_filters ON
                menu_items_filters.menu_items_id = menu_items.id
            LEFT JOIN filters_join AS filters ON
                filters.id = menu_items_filters.filters_id
        GROUP BY
            menu_items.id,
            menu_items.index_order,
            menu_items.hidden,
            menu_items.selected_by_default,
            menu_items.parent_id,
            menu_items.project_id,
            menu_items.icon,
            menu_items.display_mode,
            menu_items.search_indexed,
            menu_items.style_merge,
            menu_items.zoom,
            menu_items.color_fill,
            menu_items.color_line,
            menu_items.href,
            menu_items.style_class_string,
            menu_items.style_class,
            menu_items.type,
            menu_items.popup_fields_id,
            menu_items.details_fields_id,
            menu_items.list_fields_id,
            menu_items.use_internal_details_link,
            menu_items.use_external_details_link,
            menu_items.name,
            menu_items.name_singular,
            menu_items.slug,
            menu_items.parent_slug_id
    )
    SELECT
        jsonb_agg(
            jsonb_strip_nulls(jsonb_build_object(
                'id', id_from_slugs_menu_item(menu_items.slug, menu_items.id),
                'parent_id', menu_items.parent_slug_id,
                'index_order', menu_items.index_order,
                'hidden', menu_items.hidden,
                'selected_by_default', menu_items.selected_by_default,
                'menu_group', CASE WHEN menu_items.type = 'menu_group' THEN
                    jsonb_build_object(
                        -- 'slug', menu_items.slug->'fr',
                        'name', menu_items.name,
                        'icon', menu_items.icon,
                        'color_fill', menu_items.color_fill,
                        'color_line', menu_items.color_line,
                        'display_mode', menu_items.display_mode
                    )
                END,
                'category', CASE WHEN menu_items.type = 'category' THEN
                    jsonb_build_object(
                        -- 'slug', menu_items.slug->'fr',
                        'name', menu_items.name,
                        'search_indexed', menu_items.search_indexed,
                        'icon', menu_items.icon,
                        'color_fill', menu_items.color_fill,
                        'color_line', menu_items.color_line,
                        'style_class', menu_items.style_class,
                        'display_mode', menu_items.display_mode,
                        'style_merge', menu_items.style_merge,
                        'zoom', coalesce(menu_items.zoom, 16),
                        'filters', menu_items.filters
                    )
                END,
                'link', CASE WHEN menu_items.type = 'link' THEN
                    jsonb_build_object(
                        -- 'slug', menu_items.slug->'fr',
                        'name', menu_items.name,
                        'href', menu_items.href,
                        'icon', menu_items.icon,
                        'color_fill', menu_items.color_fill,
                        'color_line', menu_items.color_line,
                        'display_mode', menu_items.display_mode
                    )
                END
            ))
        )::text
    FROM
        theme_menu_items_filters AS menu_items
    WHERE
        parent_id IS NOT NULL
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS fields;
CREATE OR REPLACE FUNCTION fields(
    _root_field_id integer
) RETURNS jsonb AS $$
    WITH
    -- Recursive down
    RECURSIVE a AS (
        SELECT
            -1 AS parent_id,
            fields.id,
            NULL::integer AS "index",
            jsonb_strip_nulls(jsonb_build_object(
                -- 'field', null,
                'label', nullif(fields.label, false),
                'group', fields."group",
                'display_mode', fields.display_mode,
                'icon', fields.icon
                -- 'fields', null
            )) AS json,
            false AS leaf
        FROM
            fields
        WHERE
            fields.id = _root_field_id
    UNION ALL
        SELECT
            a.id AS parent_id,
            fields.id,
            fields_fields."index",
            jsonb_strip_nulls(jsonb_build_object(
                'field', fields.field,
                'label', nullif(fields.label, false),
                'group', fields."group",
                'display_mode', fields.display_mode,
                'icon', fields.icon
                -- 'fields', null
            )) AS json,
            fields.field IS NOT NULL AS leaf
        FROM
            a
            JOIN fields_fields ON
                fields_fields.fields_id = a.id
            JOIN fields ON
                fields.id = fields_fields.related_fields_id
    ),
    -- Recursive up step 1
    b AS (
        SELECT
            a3.parent_id,
            a3.id,
            a3."index",
            a3.json || jsonb_build_object(
                'fields', jsonb_agg(a2.json ORDER BY a2."index")
            ) AS json,
            true AS leaf
        FROM
            (SELECT parent_id FROM a GROUP BY parent_id HAVING BOOL_AND(leaf)) AS a
            JOIN a AS a2 ON
                a2.parent_id = a.parent_id
            JOIN a AS a3 ON
                a3.id = a.parent_id
        GROUP BY
            a3.parent_id,
            a3.id,
            a3."index",
            a3.json
        UNION ALL
        SELECT
            a2.*
        FROM
            (SELECT parent_id FROM a GROUP BY parent_id HAVING NOT BOOL_AND(leaf)) AS a
            JOIN a AS a2 ON
                a2.parent_id = a.parent_id AND
                a2.id NOT IN (SELECT parent_id FROM a GROUP BY parent_id HAVING BOOL_AND(leaf))
    ),
    -- Recursive up step 2
    c AS (
        SELECT
            b3.parent_id,
            b3.id,
            b3."index",
            b3.json || jsonb_build_object(
                'fields', jsonb_agg(b2.json ORDER BY b2."index")
            ) AS json,
            true AS leaf
        FROM
            (SELECT parent_id FROM b GROUP BY parent_id HAVING BOOL_AND(leaf)) AS b
            JOIN b AS b2 ON
                b2.parent_id = b.parent_id
            JOIN b AS b3 ON
                b3.id = b.parent_id
        GROUP BY
            b3.parent_id,
            b3.id,
            b3."index",
            b3.json
        UNION ALL
        SELECT
            b2.*
        FROM
            (SELECT parent_id FROM b GROUP BY parent_id HAVING parent_id = -1 OR NOT BOOL_AND(leaf)) AS b
            JOIN b AS b2 ON
                b2.parent_id = b.parent_id AND
                b2.id NOT IN (SELECT parent_id FROM b GROUP BY parent_id HAVING BOOL_AND(leaf))
    )
    SELECT
        json
    FROM
        c
    LIMIT 1
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;


-- Function inspired by https://stackoverflow.com/questions/45585462/recursively-flatten-a-nested-jsonb-in-postgres-without-unknown-depth-and-unknown
DROP FUNCTION IF EXISTS json_flat_object;
CREATE OR REPLACE FUNCTION json_flat_object(
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


DROP FUNCTION IF EXISTS json_flat;
CREATE OR REPLACE FUNCTION json_flat(
    _prefix text,
    _json jsonb
) RETURNS jsonb AS $$
    SELECT
        CASE jsonb_typeof(_json)
            WHEN 'object' THEN json_flat_object(_prefix, _json)
            ELSE jsonb_build_object(_prefix, _json)
        END
    ;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS pois;
CREATE OR REPLACE FUNCTION pois(
    _base_url text,
    _project_slug text,
    _theme_slug text,
    _category_id bigint,
    _poi_ids bigint[],
    _geometry_as text,
    _short_description boolean,
    _start_date text,
    _end_date text,
    _with_deps boolean,
    _cliping_polygon_slug text
) RETURNS TABLE (
    d text
) AS $$
    WITH
    projects AS (
        SELECT
            *
        FROM
            projects
        WHERE
            slug = _project_slug
    ),
    cliping_polygon AS (
        SELECT
            geom
        FROM
            projects
            JOIN sources ON
                sources.project_id = projects.id
            JOIN (
                SELECT * FROM pois
                UNION ALL
                SELECT *, NULL::text AS website_details FROM pois_local(_base_url, _project_slug)
            ) AS pois ON
                pois.source_id = sources.id AND
                pois.slugs->>'original_id' = (SELECT polygons_extra->>_cliping_polygon_slug FROM projects)
            WHERE
                _cliping_polygon_slug IS NOT NULL
    ),
    menu AS (
        SELECT
            sources.id AS source_id,
            menu_items.slug,
            menu_items.id AS menu_id,
            coalesce(menu_items.name_singular->>'fr', menu_items.name->>'fr') AS name_singular,
            menu_items.use_internal_details_link,
            menu_items.use_external_details_link,
            jsonb_build_object(
                'popup_fields', menu_items.popup_fields,
                'details_fields', menu_items.details_fields,
                'list_fields', menu_items.list_fields,
                'class_label', jsonb_build_object('fr', menu_items.name->'fr'),
                'class_label_popup', jsonb_build_object('fr', menu_items.name_singular->'fr'),
                'class_label_details', jsonb_build_object('fr', menu_items.name_singular->'fr')
                -- 'unavoidable', menu_items.unavoidable -- TODO -------
            ) AS editorial,
            jsonb_build_object(
                'icon', menu_items.icon,
                'color_fill', menu_items.color_fill,
                'color_line', menu_items.color_line,
                'style_class', array_to_json(menu_items.style_class)
            ) AS display
        FROM
            projects
            JOIN (
                SELECT
                    *,
                    fields(menu_items.popup_fields_id)->'fields' AS popup_fields,
                    fields(menu_items.details_fields_id)->'fields' AS details_fields,
                    fields(menu_items.list_fields_id)->'fields' AS list_fields
                FROM
                    menu_items_join AS menu_items
            ) AS menu_items ON
                menu_items.project_id = projects.id AND
                (_category_id IS NULL OR id_from_slugs_menu_item(menu_items.slug, menu_items.id) = _category_id)
            JOIN menu_items_sources ON
                menu_items_sources.menu_items_id = menu_items.id
            JOIN sources ON
                sources.project_id = projects.id AND
                sources.id = menu_items_sources.sources_id
    ),
    json_pois AS (
        SELECT
            row_number() OVER (PARTITION BY pois.slug_id) = 1 AS first_one,
            jsonb_strip_nulls(jsonb_build_object(
                'type', 'Feature',
                'geometry', ST_AsGeoJSON(
                    CASE _geometry_as
                    WHEN 'point' THEN
                        CASE ST_Dimension(pois.geom)
                        WHEN 0 THEN pois.geom
                        ELSE ST_PointOnSurface(pois.geom)
                        END
                    WHEN 'bbox' THEN ST_Envelope(pois.geom)
                    WHEN 'point_or_bbox' THEN
                        CASE ST_Dimension(pois.geom)
                        WHEN 0 THEN pois.geom
                        ELSE ST_Envelope(pois.geom)
                        END
                    ELSE pois.geom
                    END
                )::jsonb,
                'properties',
                    coalesce(pois.properties->'tags', '{}'::jsonb)
                        - 'name' - 'official_name' - 'loc_name' - 'alt_name'
                        - 'description' - 'website:details'
                        - 'addr' - 'ref' - 'route' - 'source' ||
                    coalesce(json_flat('addr', pois.properties->'tags'->'addr'), '{}'::jsonb) ||
                    coalesce(json_flat('ref', pois.properties->'tags'->'ref'), '{}'::jsonb) ||
                    coalesce(
                        CASE jsonb_typeof(pois.properties->'tags'->'route')
                            WHEN 'object' THEN json_flat('route', (pois.properties->'tags'->'route') - 'pdf' || jsonb_build_object('pdf', pois.properties->'tags'->'route'->'pdf'->'fr'))
                            ELSE jsonb_build_object('route', pois.properties->'tags'->'route')
                        END, '{}'::jsonb) ||
                    coalesce(json_flat('source', pois.properties->'tags'->'source'), '{}'::jsonb) ||
                    (coalesce(pois.properties->'natives', '{}'::jsonb) - 'name' - 'description' - 'website:details') ||
                    (CASE WHEN pois.image IS NOT NULL THEN jsonb_build_object('image', pois.image) ELSE '{}'::jsonb END) ||
                    jsonb_build_object(
                        'name', coalesce(
                            pois.properties->'tags'->'name'->>'fr',
                            pois.properties->'natives'->'name'->>'fr',
                            menu.name_singular
                        ),
                        'official_name', pois.properties->'tags'->'official_name'->'fr',
                        'loc_name', pois.properties->'tags'->'loc_name'->'fr',
                        'alt_name', pois.properties->'tags'->'alt_name'->'fr',
                        'description',
                            CASE _short_description
                            -- TODO strip html tags before substr
                            WHEN 'true' THEN substr(coalesce(
                                pois.properties->'tags'->'description'->>'fr',
                                pois.properties->'natives'->'description'->>'fr'
                            ), 1, 100)
                            ELSE coalesce(
                                pois.properties->'tags'->'description'->>'fr',
                                pois.properties->'natives'->'description'->>'fr'
                            )
                            END,
                        'metadata', jsonb_build_object(
                            'id', pois.slug_id,
                            -- cartocode
                            'category_ids', array_agg(id_from_slugs_menu_item(menu.slug, menu.menu_id)) OVER (PARTITION BY pois.slug_id),
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
                        'editorial', menu.editorial || jsonb_build_object(
                            'website:details', coalesce(
                                pois.website_details,
                                CASE WHEN menu.use_external_details_link THEN coalesce(
                                    pois.properties->'tags'->'website:details'->>'fr',
                                    pois.properties->'natives'->>'website:details'
                                ) END,
                                CASE WHEN menu.use_internal_details_link THEN _base_url || '/poi/' || pois.slug_id || '/details' END
                            )
                        ),
                        'display', menu.display
                    )
            )) AS feature
        FROM
            menu
            JOIN (
                SELECT
                    pois.*,
                    nullif(jsonb_agg(to_jsonb(
                        _base_url || '/assets/' || pois_files.directus_files_id::text || '/' || directus_files.filename_download
                    ) ORDER BY pois_files.index), '[null]') AS image,
                    id_from_slugs(slugs, pois.id) AS slug_id -- use slug as original POI id
                FROM
                    pois
                    LEFT JOIN pois_files ON
                        pois_files.pois_id = pois.id
                    LEFT JOIN directus_files ON
                        directus_files.id = pois_files.directus_files_id
                GROUP BY
                    pois.id
                UNION ALL
                SELECT *, NULL::text AS website_details, NULL::jsonb AS image, id AS slug_id FROM pois_local(_base_url, _project_slug)
            ) AS pois ON
                pois.source_id = menu.source_id AND
                (
                    (SELECT geom FROM cliping_polygon) IS NULL OR
                    ST_Intersects(pois.geom, (SELECT geom FROM cliping_polygon))
                )
        WHERE
            (_poi_ids IS NULL OR (
                pois.slug_id = ANY(_poi_ids) OR
                (_with_deps = true AND pois.properties->>'id' = ANY (SELECT jsonb_array_elements_text(properties->'refs') FROM pois WHERE pois.slugs->>'original_id' = ANY(_poi_ids::text[])))
            )) AND
            (_start_date IS NULL OR pois.properties->'tag'->>'start_date' IS NULL OR pois.properties->'tag'->>'start_date' <= _start_date) AND
            (_end_date IS NULL OR pois.properties->'tag'->>'end_date' IS NULL OR pois.properties->'tag'->>'end_date' >= _end_date)
        ORDER BY
            menu.menu_id,
            pois.slug_id
    )
    SELECT
        jsonb_build_object(
            'type', 'FeatureCollection',
            'features', coalesce(jsonb_agg(feature), '[]'::jsonb)
        )::text
    FROM
        json_pois
    WHERE
        first_one
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS attribute_translations;
CREATE OR REPLACE FUNCTION attribute_translations(
    _project_slug text,
    _theme_slug text,
    _lang text
) RETURNS TABLE (
    d text
) AS $$
    WITH
    translations AS (
        SELECT
            key,
            key_translations,
            values_translations
        FROM
            translations
            JOIN projects ON
                projects.slug = _project_slug AND
                projects.id = translations.project_id
    ),
    translation_fields AS (
        SELECT
            coalesce(fields.group, fields.field) AS key,
            json_build_object(
                '@default', json_build_object(
                    -- TODO loop to get the right language translations
                    substring(languages_code, 1, 2), fields_translations.name
                )
            ) AS key_translations,
            NULL::json AS values_translations
        FROM
            projects
            JOIN fields ON
                fields.project_id = projects.id
            JOIN fields_translations ON
                fields_translations.fields_id = fields.id
        WHERE
            projects.slug = _project_slug
    ),
    translations_local AS (
        SELECT
            field AS key,
            json_build_object(
                '@default', json_build_object(
                    -- TODO loop to get the right language translations
                    substring(translations->0->>'language', 1, 2), translations->0->'translation'
                )
            ) AS key_translations,
            NULL::json AS values_translations
        FROM
            directus_fields
        WHERE
            directus_fields.collection LIKE 'local-' || _project_slug || '-%' AND
            translations IS NOT NULL
    )
    SELECT
        jsonb_strip_nulls(jsonb_object_agg(
            key, jsonb_build_object(
                'label', jsonb_build_object(
                    'fr', capitalize(key_translations->'@default'->>_lang)
                ),
                'values', (
                    SELECT
                        jsonb_object_agg(
                            key, jsonb_build_object(
                                'label', jsonb_build_object(
                                    'fr', capitalize(value->'@default:full'->>_lang)
                                )
                            )
                        )
                    FROM
                        json_each(values_translations)
                )
            )
        ))::text
    FROM (
        SELECT * FROM translations
        UNION ALL
        SELECT * FROM translation_fields
        UNION ALL
        SELECT * FROM translations_local
    ) AS translations
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;
