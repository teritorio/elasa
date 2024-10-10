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
                        themes_join AS themes
                    WHERE
                        themes.project_id = projects.id
                )
            )
        ) AS project
    FROM
        projects_join AS projects
    WHERE
        projects.slug = _project_slug
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS pois_local;
CREATE OR REPLACE FUNCTION pois_local(
    _project_slug text,
    _source_ids integer[]
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
        SELECT
            sources.id,
            table_name,
            regexp_replace(table_name, 'local-[a-z_]+-', '') || '_id' AS local_id
        FROM
            information_schema.tables
            JOIN sources ON
                (_source_ids IS NULL OR sources.id = ANY (_source_ids)) AND
                table_name = 'local-' || _project_slug || '-' || sources.slug
        WHERE
            table_type = 'BASE TABLE' AND
            table_schema = 'public'
    LOOP
        FOR poi IN EXECUTE '
            WITH
            j AS (
                SELECT
                    "' || source.local_id || '" AS id,
                    substring(languages_code, 1, 2) AS languages_code,
                    (jsonb_each_text(row_to_json(t.*)::jsonb - ''id'' - ''languages_code'' - ''' || source.local_id || ''')).key,
                    (jsonb_each_text(row_to_json(t.*)::jsonb - ''id'' - ''languages_code'' - ''' || source.local_id || ''')).value
                FROM
                    "' || source.table_name || '_t" AS t
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
            )
            SELECT
                t.id,
                geom,
                jsonb_build_object(
                    ''id'', t.id,
                    ''source'', NULL,
                    ''updated_at'', NULL,
                    ''natives'', row_to_json(t.*)::jsonb - ''id'' - ''geom'' || trans.jsonb
                ) AS properties
            FROM
                "' || source.table_name || '" AS t
                JOIN trans ON
                    trans.id = t.id
        '
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
    _project_slug text,
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
            project_id = _project_id AND
            key = _property
        LIMIT 1
    ),
    sources AS (
        SELECT
            sources.id AS id
        FROM
            menu_items_sources
            JOIN sources ON
                sources.id = menu_items_sources.sources_id
        WHERE
            menu_items_sources.menu_items_id = _menu_items_id
    ),
    pois AS (
        SELECT pois.* FROM pois JOIN sources ON sources.id = pois.source_id
        UNION ALL
        SELECT * FROM pois_local(_project_slug, (SELECT array_agg(id) FROM sources))
    ),
    properties AS (
        SELECT
            coalesce(
                jsonb_path_query_first((pois.properties->'tags')::jsonb, ('$.' || CASE WHEN _property LIKE 'route:%' OR _property LIKE 'addr:%' THEN replace(_property, ':', '.') ELSE '"' || _property || '"' END)::jsonpath),
                jsonb_path_query_first((pois.properties->'natives')::jsonb, ('$.' || '"' || _property || '"')::jsonpath)
            ) AS property
        FROM
            pois
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
            property IS NOT NULL AND
            property != 'null'::jsonb
    ),
    values_uniq AS (
        SELECT DISTINCT ON (upper(value))
            value
        FROM
            values
        ORDER BY
            upper(value)
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
$$ LANGUAGE sql STABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS menu;
CREATE OR REPLACE FUNCTION menu(
    _project_slug text,
    _theme_slug text
) RETURNS TABLE (
    d jsonb
) AS $$
    WITH
    RECURSIVE theme_menu_items AS (
        SELECT
            menu_items.*,
            projects.id AS project_id,
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
            project_id,
            id_from_slugs_menu_item(theme_menu_items.slug, theme_menu_items.id) AS parent_slug_id
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
            menu_items.theme_id,
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
            menu_items.use_details_link,
            menu_items.name,
            menu_items.name_singular,
            menu_items.slug,
            menu_items.parent_slug_id,
            jsonb_agg(
                jsonb_build_object(
                    'type', filters.type,
                    'name', filters.name
                ) ||
                CASE filters.type
                WHEN 'multiselection' THEN
                    jsonb_build_object(
                        'property', filters.multiselection_property,
                        'values', filter_values(_project_slug, menu_items.project_id, menu_items.id, filters.multiselection_property)
                    )
                WHEN 'checkboxes_list' THEN
                    jsonb_build_object(
                        'property', filters.checkboxes_list_property,
                        'values', filter_values(_project_slug, menu_items.project_id, menu_items.id, filters.checkboxes_list_property)
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
            ) AS filters
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
            menu_items.theme_id,
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
            menu_items.use_details_link,
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
                        'slug', menu_items.slug->'fr',
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
                'label', nullif(label, false),
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
                'label', nullif(label, false),
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
            fields.label,
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
                'label', nullif(label, false),
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
            fields.label,
            fields."group",
            fields.display_mode,
            fields.icon
    )
    SELECT
        json
    FROM
        d
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
    _project_slug text,
    _theme_slug text,
    _category_id bigint,
    _poi_ids bigint[],
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
        SELECT DISTINCT ON (menu_items.id, pois.id)
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
                        - 'description' - 'website:details' - 'colour'
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
                    jsonb_build_object(
                        'name', coalesce(
                            pois.properties->'tags'->'name'->>'fr',
                            pois.properties->'natives'->'name'->>'fr',
                            menu_items.name_singular->>'fr'
                        ),
                        'official_name', pois.properties->'tags'->'official_name'->>'fr',
                        'loc_name', pois.properties->'tags'->'loc_name'->>'fr',
                        'alt_name', pois.properties->'tags'->'alt_name'->>'fr',
                        'description',
                            CASE _short_description
                            -- TODO strip html tags before substr
                            WHEN 'true' THEN substr(coalesce(
                                pois.properties->'tags'->'description'->>'fr',
                                pois.properties->'natives'->'description'->>'fr'
                            ), 1, 20)
                            ELSE coalesce(
                                pois.properties->'tags'->'description'->>'fr',
                                pois.properties->'natives'->'description'->>'fr'
                            )
                            END,
                        'metadata', jsonb_build_object(
                            'id', id_from_slugs(pois.slugs, pois.id), -- use slug as original POI id
                            -- cartocode
                            'category_ids', array[id_from_slugs_menu_item(menu_items.slug, menu_items.id)], -- FIXME Should be all menu_items.id
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
                            'popup_fields', menu_items.popup_fields,
                            'details_fields', menu_items.details_fields,
                            'list_fields', menu_items.list_fields,
                            'class_label', jsonb_build_object('fr', menu_items.name->'fr'),
                            'class_label_popup', jsonb_build_object('fr', menu_items.name_singular->'fr'),
                            'class_label_details', jsonb_build_object('fr', menu_items.name_singular->'fr'),
                            'website:details', CASE WHEN menu_items.use_details_link THEN
                                coalesce(
                                    pois.properties->'tags'->'website:details'->>'fr',
                                    pois.properties->'natives'->>'website:details',
                                    themes.site_url->>'fr' || '/poi/' || id_from_slugs(pois.slugs, pois.id) || '/details' -- use slug as original POI id
                                )
                            END
                            -- 'unavoidable', menu_items.unavoidable -- TODO -------
                        ),
                        'display', jsonb_build_object(
                            'icon', menu_items.icon,
                            'color_fill', coalesce(pois.properties->'tags'->>'colour', menu_items.color_fill),
                            'color_line', coalesce(pois.properties->'tags'->>'colour', menu_items.color_line),
                            'style_class', array_to_json(menu_items.style_class)
                        )
                    )
            )) AS feature
        FROM
            -- TODO only for not hidden menu_items, recursively from theme
            projects
            JOIN themes_join AS themes ON
                themes.project_id = projects.id AND
                themes.slug = _theme_slug
            JOIN (
                SELECT
                    *,
                    fields(menu_items.popup_fields_id)->'fields' AS popup_fields,
                    fields(menu_items.details_fields_id)->'fields' AS details_fields,
                    fields(menu_items.list_fields_id)->'fields' AS list_fields
                FROM
                    menu_items_join AS menu_items
            ) AS menu_items ON
                menu_items.theme_id = themes.id AND
                (_category_id IS NULL OR id_from_slugs_menu_item(menu_items.slug, menu_items.id) = _category_id)
            JOIN menu_items_sources ON
                menu_items_sources.menu_items_id = menu_items.id
            JOIN sources ON
                sources.project_id = projects.id AND
                sources.id = menu_items_sources.sources_id
            JOIN (
                SELECT * FROM pois
                UNION ALL
                SELECT * FROM pois_local(_project_slug, NULL)
            ) AS pois ON
                pois.source_id = sources.id
        WHERE
            projects.slug = _project_slug AND
            (_poi_ids IS NULL OR (
                id_from_slugs(pois.slugs, pois.id) = ANY(_poi_ids) OR
                (_with_deps = true AND pois.properties->>'id' = ANY (SELECT jsonb_array_elements_text(properties->'refs') FROM pois WHERE pois.slugs->>'original_id' = ANY(_poi_ids::text[])))
            )) AND
            (_start_date IS NULL OR pois.properties->'tag'->>'start_date' IS NULL OR pois.properties->'tag'->>'start_date' <= _start_date) AND
            (_end_date IS NULL OR pois.properties->'tag'->>'end_date' IS NULL OR pois.properties->'tag'->>'end_date' >= _end_date)
        ORDER BY
            menu_items.id,
            pois.id
    ) AS t
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS attribute_translations;
CREATE OR REPLACE FUNCTION attribute_translations(
    _project_slug text,
    _theme_slug text,
    _lang text
) RETURNS TABLE (
    d jsonb
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
        ))
    FROM (
        SELECT * FROM translations
        UNION ALL
        SELECT * FROM translations_local
    ) AS translations
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;
