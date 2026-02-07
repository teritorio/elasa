CREATE SCHEMA IF NOT EXISTS api02;
SET search_path TO api02,public;


DROP FUNCTION IF EXISTS capitalize;
CREATE FUNCTION capitalize(str text) RETURNS text AS $$
    SELECT
        upper(substring(str from 1 for 1)) ||
        substring(str from 2 for length(str))
    ;
$$ LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE;


CREATE OR REPLACE AGGREGATE jsonb_merge_agg(jsonb)
(
    sfunc = jsonb_concat,
    stype = jsonb,
    initcond = '{}'
);


DROP FUNCTION IF EXISTS id_from_slugs CASCADE;
CREATE FUNCTION id_from_slugs(slugs json, id integer) RETURNS bigint AS $$
    SELECT
        coalesce(
            (slugs->>'original_id')::bigint,
            id
        )
    ;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS id_from_slugs_menu_item CASCADE;
CREATE FUNCTION id_from_slugs_menu_item(slugs jsonb, id integer) RETURNS bigint AS $$
    SELECT
        coalesce(
            CASE WHEN slugs->>'fr' ~ E'^\\d+$' THEN (slugs->>'fr')::bigint END,
            id
        )
    ;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;


DROP VIEW IF EXISTS projects_join;
CREATE VIEW projects_join AS
SELECT
    projects.*,
    nullif(jsonb_strip_nulls(jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.name) FILTER (WHERE trans.languages_code IS NOT NULL)), '{}'::jsonb) AS name
FROM
    projects
    LEFT JOIN projects_translations AS trans ON
        trans.projects_id = projects.id
GROUP BY
    projects.id
;

DROP VIEW IF EXISTS articles_join;
CREATE VIEW articles_join AS
SELECT
    articles.*,
    nullif(jsonb_strip_nulls(jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.title) FILTER (WHERE trans.languages_code IS NOT NULL)), '{}'::jsonb) AS title,
    nullif(jsonb_strip_nulls(jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.slug) FILTER (WHERE trans.languages_code IS NOT NULL)), '{}'::jsonb) AS slug,
    nullif(jsonb_strip_nulls(jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.body) FILTER (WHERE trans.languages_code IS NOT NULL)), '{}'::jsonb) AS body
FROM
    articles
    LEFT JOIN articles_translations AS trans ON
        trans.articles_id = articles.id
GROUP BY
    articles.id
;

DROP VIEW IF EXISTS themes_join;
CREATE VIEW themes_join AS
SELECT
    themes.*,
    nullif(jsonb_strip_nulls(jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.name) FILTER (WHERE trans.languages_code IS NOT NULL)), '{}'::jsonb) AS name,
    nullif(jsonb_strip_nulls(jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.description) FILTER (WHERE trans.languages_code IS NOT NULL)), '{}'::jsonb) AS description,
    nullif(jsonb_strip_nulls(jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.site_url) FILTER (WHERE trans.languages_code IS NOT NULL)), '{}'::jsonb) AS site_url,
    nullif(jsonb_strip_nulls(jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.main_url) FILTER (WHERE trans.languages_code IS NOT NULL)), '{}'::jsonb) AS main_url,
    nullif(jsonb_strip_nulls(jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.keywords) FILTER (WHERE trans.languages_code IS NOT NULL)), '{}'::jsonb) AS keywords,
    nullif(jsonb_strip_nulls(jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.cookies_consent_message) FILTER (WHERE trans.languages_code IS NOT NULL)), '{}'::jsonb) AS cookies_consent_message
FROM
    themes
    LEFT JOIN themes_translations AS trans ON
        trans.themes_id = themes.id
GROUP BY
    themes.id
;

DROP VIEW IF EXISTS pois_join CASCADE;
CREATE VIEW pois_join AS
SELECT
    pois.*,
    nullif(jsonb_agg(to_jsonb(
        '__base_url__' || '/assets/' || pois_files.directus_files_id::text || '/' || directus_files.filename_download
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
;

DROP VIEW IF EXISTS pois_join_without_deps;
CREATE VIEW pois_join_without_deps AS
SELECT
    pois.id,
    pois.geom,
    pois.source_id,
    pois.properties,
    pois.image,
    pois.slug_id,
    NULL::integer[] AS dep_ids,
    NULL::integer[] AS dep_original_ids
FROM
    pois_join AS pois
;

DROP VIEW IF EXISTS pois_join_with_deps;
CREATE VIEW pois_join_with_deps AS
SELECT
    pois.id,
    pois.geom,
    pois.source_id,
    pois.properties,
    pois.image,
    pois.slug_id,
    nullif(
        array_agg(pois_pois.children_pois_id ORDER BY index),
        ARRAY[NULL::integer]
    ) AS dep_ids,
    nullif(
        array_agg(coalesce((dep_pois.slugs->>'original_id')::integer, pois_pois.children_pois_id) ORDER BY index),
        ARRAY[NULL::integer]
    ) AS dep_original_ids
FROM
    pois_join AS pois
    LEFT JOIN pois_pois ON
        pois_pois.parent_pois_id = pois.id
    LEFT JOIN pois AS dep_pois ON
        dep_pois.id = pois_pois.children_pois_id
GROUP BY
    pois.id,
    pois.geom,
    pois.source_id,
    pois.properties,
    pois.image,
    pois.slug_id
;

DROP VIEW IF EXISTS menu_items_join;
CREATE VIEW menu_items_join AS
SELECT
    menu_items.*,
    nullif(jsonb_strip_nulls(jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.name) FILTER (WHERE trans.languages_code IS NOT NULL)), '{}'::jsonb) AS name,
    nullif(jsonb_strip_nulls(jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.name_singular) FILTER (WHERE trans.languages_code IS NOT NULL)), '{}'::jsonb) AS name_singular,
    nullif(jsonb_strip_nulls(jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.slug) FILTER (WHERE trans.languages_code IS NOT NULL)), '{}'::jsonb) AS slug,
    nullif(jsonb_agg(fields.field), '[null]'::jsonb) AS filterable_property
FROM
    menu_items
    JOIN menu_items_translations AS trans ON
        trans.menu_items_id = menu_items.id
    LEFT JOIN menu_items_sources ON
        menu_items_sources.menu_items_id = menu_items.id
    LEFT JOIN pois_property_values ON
        pois_property_values.source_id = menu_items_sources.sources_id
    LEFT JOIN fields ON
        fields.id = pois_property_values.field_id
GROUP BY
    menu_items.id
;

DROP VIEW IF EXISTS filters_join;
CREATE VIEW filters_join AS
SELECT
    filters.*,
    nullif(jsonb_strip_nulls(jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.name) FILTER (WHERE trans.languages_code IS NOT NULL)), '{}'::jsonb) AS name
FROM
    filters
    LEFT JOIN filters_translations AS trans ON
        trans.filters_id = filters.id
GROUP BY
    filters.id
;

DROP FUNCTION IF EXISTS projects;
CREATE OR REPLACE FUNCTION projects(
    _base_url text,
    _project_slug text,
    _theme_slug text
) RETURNS TABLE (
    d text
) AS $$
    SELECT
        jsonb_strip_nulls(jsonb_object_agg(projects.slug,
            to_jsonb(projects.*) - 'name' - 'polygon' - 'bbox_line' - 'icon_font_css_url' - 'api_key' - 'datasources_slug' ||
            jsonb_build_object(
                'name', projects.name->'fr',
                'polygon', jsonb_build_object(
                    'type', 'geojson',
                    'data', ST_AsGeoJSON(projects.polygon, 9, 0)::jsonb
                ),
                'polygons_extra', (
                    SELECT
                        jsonb_object_agg(
                            key,
                            jsonb_build_object(
                                'type', 'geojson',
                                'data', (SELECT _base_url || '/api/0.2/' || projects.slug || '/' || themes.slug || '/poi/' || (value::text) || '.geojson' FROM themes_join AS themes WHERE themes.project_id = projects.id LIMIT 1)
                            )
                        )
                    FROM
                        json_each_text(polygons_extra)
                ),
                'bbox_line', ST_AsGeoJSON(projects.bbox_line, 9, 0)::jsonb,
                'icon_font_css_url', _base_url || projects.icon_font_css_url,
                'attributions', coalesce((
                    SELECT
                        array_agg(DISTINCT
                            CASE
                                WHEN attribution NOT LIKE '<a%</a>' THEN split_attribution
                                WHEN split_attribution NOT LIKE '%</a>' THEN split_attribution || '</a>'
                                WHEN split_attribution NOT LIKE '<a%' THEN '<a' || split_attribution
                                ELSE split_attribution
                            END
                        )
                    FROM
                        sources
                        JOIN LATERAL string_to_table(attribution, '</a> <a') AS a(split_attribution) ON true
                    WHERE
                        sources.project_id = projects.id AND
                        attribution IS NOT NULL
                ), array[]::text[]),
                'image_proxy_hosts', nullif(projects.image_proxy_hosts, '[]'::jsonb),
                'themes', (
                    SELECT
                        jsonb_strip_nulls(jsonb_object_agg(themes.slug,
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
                                'favorites_mode', nullif(favorites_mode, true),
                                'articles', (
                                    SELECT
                                        jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
                                            'url', (SELECT _base_url || '/api/0.2/' || projects.slug || '/' || themes.slug || '/article/' || (articles.slug->>'fr') || '.html' FROM themes_join AS themes WHERE themes.project_id = projects.id LIMIT 1),
                                            'title', articles.title->'fr'
                                        )) ORDER BY themes_articles.index)
                                    FROM
                                        themes_articles
                                        JOIN articles_join AS articles ON
                                            articles.id = themes_articles.articles_id
                                    WHERE
                                        themes_articles.themes_id = themes.id
                                ),
                                'isochrone', nullif(themes.isochrone, false),
                                'report_issue_url', nullif(themes.report_issue, false),
                                'map_style_base_url', themes.map_style_base_url,
                                'map_style_satellite_url', themes.map_style_satellite_url,
                                'map_bicycle_style_url', themes.map_bicycle_style_url,
                                'matomo_url', themes.matomo_url,
                                'matomo_siteid', themes.matomo_siteid,
                                'google_site_verification', themes.google_site_verification,
                                'google_tag_manager_id', themes.google_tag_manager_id,
                                'cookies_consent_message', themes.cookies_consent_message,
                                'cookies_usage_detail_url', themes.cookies_usage_detail_url
                            )
                        ))
                    FROM
                        themes_join AS themes
                        LEFT JOIN directus_files AS directus_files_logo ON
                            directus_files_logo.id = themes.logo
                        LEFT JOIN directus_files AS directus_files_favicon ON
                            directus_files_favicon.id = themes.favicon
                    WHERE
                        themes.project_id = projects.id AND
                        (_theme_slug IS NULL OR themes.slug = _theme_slug)
                )
            )
        ))::text
    FROM
        projects_join AS projects
    WHERE
        _project_slug IS NULL OR projects.slug = _project_slug
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS article;
CREATE OR REPLACE FUNCTION article(
    _project_slug text,
    _article_slug text
) RETURNS TABLE (
    d text
) AS $$
    SELECT
        '<!DOCTYPE html>
<html lang="fr-FR">
<title>' || articles_translations.title || '</title>
<body>
<h1>' || articles_translations.title || '</h1>
' || articles_translations.body || '
</body>
</html>'
    FROM
        projects
        JOIN articles ON
            articles.project_id = projects.id
        JOIN articles_translations ON
            articles_translations.articles_id = articles.id AND
            articles_translations.slug = _article_slug
    WHERE
        projects.slug = _project_slug
    LIMIT 1
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS split_field;
CREATE OR REPLACE FUNCTION split_field(
    field text
) RETURNS text[] AS $$
    SELECT CASE
    WHEN field IS NULL THEN NULL
    WHEN field LIKE 'route:%' AND field != 'route:waypoint:type' THEN string_to_array(field, ':')
    WHEN field LIKE 'addr:%' THEN string_to_array(field, ':')
    ELSE array[field]
    END
$$ LANGUAGE sql STABLE PARALLEL SAFE;


DROP TYPE IF EXISTS field_size_t CASCADE;
CREATE TYPE field_size_t AS ENUM ('small', 'large');

DROP FUNCTION IF EXISTS fields;
CREATE OR REPLACE FUNCTION fields(
    _project_slug text,
    _root_field_id integer,
    field_size field_size_t
) RETURNS jsonb AS $$
    WITH
    -- Recursive down
    RECURSIVE a AS (
        WITH
            -- Ignore groups without fields
            fields AS (
                SELECT
                    fields.*
                FROM
                    projects
                    JOIN fields ON
                        fields.project_id = projects.id
                    LEFT JOIN fields_fields ON
                        fields_fields.fields_id = fields.id
                WHERE
                    projects.slug = _project_slug AND
                    (
                        fields.group IS NULL OR
                        fields_fields.id IS NOT NULL
                    )
                GROUP BY
                    fields.id
            )
        SELECT
            -1 AS parent_id,
            fields.id,
            NULL::integer AS "index",
            jsonb_strip_nulls(jsonb_build_object(
                -- 'field', null,
                'label', nullif(
                    CASE field_size
                        WHEN 'small'::field_size_t THEN fields.label_small
                        WHEN 'large'::field_size_t THEN fields.label_large
                    END,
                    false
                ),
                'group', fields."group",
                'display_mode', nullif(fields.display_mode, 'standard'),
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
                'field', split_field(fields.field),
                'label', nullif(
                    CASE field_size
                        WHEN 'small'::field_size_t THEN fields.label_small
                        WHEN 'large'::field_size_t THEN fields.label_large
                    END,
                    false
                ),
                'group', fields."group",
                'display_mode', nullif(fields.display_mode, 'standard'),
                'icon', coalesce(
                    fields.icon,
                    CASE
                        WHEN fields.field = 'facebook' THEN 'facebook'
                        WHEN fields.field = 'instagram' THEN 'instagram'
                        WHEN fields.field = 'linkedin' THEN 'linkedin'

                        WHEN fields.field = 'download' THEN 'arrow-circle-down'
                        WHEN fields.field = 'route:gpx_trace' THEN 'arrow-circle-down'
                        WHEN fields.field = 'route:pdf' THEN 'arrow-circle-down'
                    END
                ),
                -- 'fields', null
                'multilingual', CASE
                    -- Fields spec should rather be produced from locale tables schema
                    WHEN fields.field IN ('name', 'description', 'website:details') THEN true
                    WHEN fields."group" IS NULL THEN nullif(fields.multilingual, false)
                END,
                'array', CASE
                    -- Fields spec should rather be produced from locale tables schema
                    WHEN fields.field IN ('download', 'phone', 'email', 'website') THEN true
                    WHEN fields."group" IS NULL THEN nullif(fields.array, false)
                END,
                'render', CASE WHEN fields."group" IS NULL THEN coalesce(
                    CASE fields.role
                        WHEN 'opening_hours' THEN 'osm:opening_hours'
                        WHEN 'image' THEN 'image'
                        WHEN 'phone' THEN 'phone'
                        ELSE fields.role
                    END,
                    CASE fields.media_type
                        WHEN 'text/plain' THEN 'string'
                        WHEN 'text/html' THEN 'text'
                        WHEN 'text/x-uri' THEN 'weblink'
                        WHEN 'text/vnd.phone-number' THEN 'phone'
                        WHEN 'text/vnd.osm.opening_hours' THEN 'osm:opening_hours'
                        WHEN 'text/vnd.osm.html-color' THEN 'color'
                        WHEN 'text/vnd.osm.stars' THEN 'osm:stars'
                    END,
                    CASE -- osm tags
                        WHEN fields.field = 'string' THEN 'string'
                        WHEN fields.field = 'description' THEN 'text'
                        WHEN fields.field LIKE 'capacity' THEN 'integer'
                        WHEN fields.field LIKE 'capacity:%' THEN 'integer'
                        WHEN fields.field LIKE '%:capacity' THEN 'integer'
                        -- THEN 'boolean'
                        -- THEN 'color'

                        -- Links
                        WHEN fields.field = 'website' THEN 'weblink'
                        WHEN fields.field = 'website:%' THEN 'weblink'
                        WHEN fields.field = '%:website' THEN 'weblink'

                        WHEN fields.field = 'facebook' THEN 'weblink@social-network'
                        WHEN fields.field = 'instagram' THEN 'weblink@social-network'
                        WHEN fields.field = 'linkedin' THEN 'weblink@social-network'

                        WHEN fields.field = 'download' THEN 'weblink@download'
                        WHEN fields.field = 'route:gpx_trace' THEN 'weblink@download'
                        WHEN fields.field = 'route:pdf' THEN 'weblink@download'

                        -- Picture
                        WHEN fields.field = 'image' THEN 'image'
                        WHEN fields.field = 'mapillary' THEN 'mapillary'
                        WHEN fields.field = 'panoramax' THEN 'panoramax'

                        -- Tags
                        WHEN fields.field = 'cuisine' THEN 'tag'

                        -- Rating
                        WHEN fields.field = 'stars' THEN 'osm:stars'

                        -- Contact
                        WHEN fields.field = 'email' THEN 'email'
                        WHEN fields.field = 'phone' THEN 'phone'
                        WHEN fields.field = 'mobile' THEN 'phone'

                        -- Time
                        WHEN fields.field = 'date' THEN 'date'
                        WHEN fields.field = 'datetime' THEN 'datetime'
                        WHEN fields.field = 'duration' THEN 'duration'
                        WHEN fields.field = 'start_end_date' THEN 'start_end_date'

                        -- opening_hours & collection_times
                        WHEN fields.field = 'opening_hours' THEN 'osm:opening_hours'
                        WHEN fields.field LIKE 'opening_hours:%' THEN 'osm:opening_hours'
                        WHEN fields.field LIKE '%:opening_hours' THEN 'osm:opening_hours'
                        WHEN fields.field LIKE '%:opening_hours:%' THEN 'osm:opening_hours'
                        WHEN fields.field = 'smoking_hours' THEN 'osm:opening_hours'
                        WHEN fields.field = 'happy_hours' THEN 'osm:opening_hours'

                        WHEN fields.field = 'lit' THEN 'osm:opening_hours+values'
                        WHEN fields.field LIKE 'lit:%' THEN 'osm:opening_hours+values'
                        WHEN fields.field = 'breakfast' THEN 'osm:opening_hours+values'
                        WHEN fields.field LIKE 'breakfast:%' THEN 'osm:opening_hours+values'
                        WHEN fields.field = 'lunch' THEN 'osm:opening_hours+values'
                        WHEN fields.field LIKE 'lunch:%' THEN 'osm:opening_hours+values'
                        WHEN fields.field = 'dinner' THEN 'osm:opening_hours+values'
                        WHEN fields.field LIKE 'dinner:%' THEN 'osm:opening_hours+values'
                        WHEN fields.field = 'happy_hours' THEN 'osm:opening_hours+values'
                        WHEN fields.field LIKE 'happy_hours:%' THEN 'osm:opening_hours+values'

                        WHEN fields.field = 'collection_times' THEN 'osm:collection_times'
                        WHEN fields.field = 'service_times' THEN 'osm:collection_times'

                        -- Objects
                        WHEN fields.field = 'route' THEN 'route'
                        WHEN fields.field = 'addr' THEN 'addr'

                        -- Syntetic fields
                        WHEN fields.field = 'coordinates' THEN 'coordinates'
                    END,
                    'string'
                ) END
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


DROP FUNCTION IF EXISTS menu;
CREATE OR REPLACE FUNCTION menu(
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
            menu_items.icon_show,
            menu_items.display_mode,
            menu_items.search_indexed,
            menu_items.style_merge,
            menu_items.zoom,
            menu_items.color_fill,
            menu_items.color_line,
            menu_items.href,
            menu_items.style_class,
            menu_items.type,
            fields(_project_slug, menu_items.popup_fields_id, 'small'::field_size_t)->'fields' AS popup_fields,
            fields(_project_slug, menu_items.details_fields_id, 'large'::field_size_t)->'fields' AS details_fields,
            fields(_project_slug, menu_items.list_fields_id, NULL)->'fields' AS list_fields,
            menu_items.use_internal_details_link,
            menu_items.use_external_details_link,
            menu_items.name,
            menu_items.name_singular,
            menu_items.slug,
            menu_items.parent_slug_id,
            menu_items.filterable_property,
            nullif(jsonb_agg(
                jsonb_strip_nulls(jsonb_build_object(
                    'type', filters.type,
                    'name', nullif(CASE filters.type
                        WHEN 'boolean' THEN jsonb_strip_nulls(jsonb_build_object('fr', capitalize(coalesce(fields_boolean_translations.name_large, fields_boolean_translations.name, filters.name->>'fr-FR'))))
                        ELSE filters.name
                    END, '{}'::jsonb)
                )) ||
                CASE filters.type
                WHEN 'multiselection' THEN
                    jsonb_build_object(
                        'property', split_field(fields_multiselection.field),
                        'values', coalesce(filter_multiselection_values_global.property_values, '[]'::jsonb)
                    )
                WHEN 'checkboxes_list' THEN
                    jsonb_build_object(
                        'property', split_field(fields_checkboxes_list.field),
                        'values', coalesce(filter_checkboxes_list_values_global.property_values, '[]'::jsonb)
                    )
                WHEN 'boolean' THEN
                    jsonb_build_object(
                        'property', split_field(fields_boolean.field)
                    )
                WHEN 'date_range' THEN
                    jsonb_build_object(
                        'property', split_field(fields_date_range.field)
                    )
                WHEN 'number_range' THEN
                    jsonb_build_object(
                        'property', split_field(fields_number_range.field),
                        'min', filters.min,
                        'max', filters.max
                    )
                END
            ORDER BY menu_items_filters.index), '[null]'::jsonb) AS filters
        FROM
            theme_menu_items AS menu_items
            LEFT JOIN menu_items_filters ON
                menu_items_filters.menu_items_id = menu_items.id
            LEFT JOIN filters_join AS filters ON
                filters.id = menu_items_filters.filters_id
            LEFT JOIN fields AS fields_multiselection ON
                fields_multiselection.id = filters.multiselection_property AND
                fields_multiselection.type = 'field'
            LEFT JOIN pois_property_values_by_menu_item(menu_items.project_id, menu_items.id, fields_multiselection.id)  AS filter_multiselection_values_global ON
                filter_multiselection_values_global.project_id = filters.project_id AND
                filter_multiselection_values_global.field_id = filters.multiselection_property
            LEFT JOIN fields AS fields_checkboxes_list ON
                fields_checkboxes_list.id = filters.checkboxes_list_property AND
                fields_checkboxes_list.type = 'field'
            LEFT JOIN pois_property_values_by_menu_item(menu_items.project_id, menu_items.id, fields_checkboxes_list.id) AS filter_checkboxes_list_values_global ON
                filter_checkboxes_list_values_global.project_id = filters.project_id AND
                filter_checkboxes_list_values_global.field_id = filters.checkboxes_list_property
            LEFT JOIN fields AS fields_boolean ON
                fields_boolean.id = filters.boolean_property AND
                fields_boolean.type = 'field'
            LEFT JOIN fields_translations AS fields_boolean_translations ON
                fields_boolean_translations.fields_id = filters.boolean_property AND
                fields_boolean_translations.languages_code = 'fr-FR'
            LEFT JOIN fields AS fields_date_range ON
                fields_date_range.id = filters.property_date AND
                fields_date_range.type = 'field'
            LEFT JOIN fields AS fields_number_range ON
                fields_number_range.id = filters.number_range_property AND
                fields_number_range.type = 'field'
        GROUP BY
            menu_items.id,
            menu_items.index_order,
            menu_items.hidden,
            menu_items.selected_by_default,
            menu_items.parent_id,
            menu_items.project_id,
            menu_items.icon,
            menu_items.icon_show,
            menu_items.display_mode,
            menu_items.search_indexed,
            menu_items.style_merge,
            menu_items.zoom,
            menu_items.color_fill,
            menu_items.color_line,
            menu_items.href,
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
            menu_items.filterable_property
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
                        'display_mode', menu_items.display_mode,
                        'filters', menu_items.filters
                    )
                END,
                'category', CASE WHEN menu_items.type = 'category' THEN
                    jsonb_build_object(
                        -- 'slug', menu_items.slug->'fr',
                        'name', menu_items.name,
                        'search_indexed', menu_items.search_indexed,
                        'icon', menu_items.icon,
                        'icon_show', nullif(menu_items.icon_show, 'always'),
                        'color_fill', menu_items.color_fill,
                        'color_line', nullif(menu_items.color_line, menu_items.color_fill),
                        'display_mode', menu_items.display_mode,
                        'style_merge', menu_items.style_merge,
                        'style_class', nullif(menu_items.style_class, '[]'::jsonb),
                        'zoom', coalesce(menu_items.zoom, 16),
                        'filterable_property', menu_items.filterable_property,
                        'filters', menu_items.filters,
                        'editorial', jsonb_build_object(
                            'popup_fields', menu_items.popup_fields,
                            'details_fields', menu_items.details_fields,
                            'list_fields', menu_items.list_fields,
                            'class_label', nullif(jsonb_strip_nulls(jsonb_build_object('fr', menu_items.name->'fr')), '{}'::jsonb),
                            'class_label_popup', nullif(jsonb_strip_nulls(jsonb_build_object('fr', menu_items.name_singular->'fr')), '{}'::jsonb),
                            'class_label_details', nullif(jsonb_strip_nulls(jsonb_build_object('fr', menu_items.name_singular->'fr')), '{}'::jsonb)
                            -- 'unavoidable', menu_items.unavoidable -- TODO -------
                        )
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
            CASE
                WHEN j.key = '' THEN f.key
                ELSE concat(f.key, ':', j.key)
            END AS key,
            j.value
        FROM
            flat AS f,
            jsonb_each(f.value) AS j
        WHERE
            jsonb_typeof(f.value) = 'object'
    )
    SELECT
        jsonb_object_agg(
            CASE
                WHEN key = '' THEN _prefix
                ELSE _prefix || ':' || key
            END,
            value
        ) AS data
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


-- Function to decode HTML entities to their corresponding characters
CREATE OR REPLACE FUNCTION decode_html_entities(input_text TEXT)
RETURNS text AS $$
DECLARE
    result_text TEXT;
    decimal_match TEXT;
    hex_value TEXT;
BEGIN
    -- Handle null input
    IF input_text IS NULL THEN
        RETURN NULL;
    END IF;

    result_text := input_text;

    -- Replace common named HTML entities
    result_text := REPLACE(result_text, '&amp;', '&');
    result_text := REPLACE(result_text, '&lt;', '<');
    result_text := REPLACE(result_text, '&gt;', '>');
    result_text := REPLACE(result_text, '&quot;', '"');
    result_text := REPLACE(result_text, '&lsquo;', '‘');
    result_text := REPLACE(result_text, '&rsquo;', '’');
    result_text := REPLACE(result_text, '&laquo;', '«');
    result_text := REPLACE(result_text, '&raquo;', '»');
    result_text := REPLACE(result_text, '&ldquo;', '“');
    result_text := REPLACE(result_text, '&rdquo;', '”');
    result_text := REPLACE(result_text, '&#39;', '''');
    result_text := REPLACE(result_text, '&apos;', '''');
    result_text := REPLACE(result_text, '&nbsp;', ' ');
    result_text := REPLACE(result_text, '&ndash;', '–');
    result_text := REPLACE(result_text, '&mdash;', '—');
    result_text := REPLACE(result_text, '&hellip;', '…');

    -- Additional common entities
    result_text := REPLACE(result_text, '&copy;', '©');
    result_text := REPLACE(result_text, '&reg;', '®');
    result_text := REPLACE(result_text, '&trade;', '™');
    result_text := REPLACE(result_text, '&euro;', '€');
    result_text := REPLACE(result_text, '&pound;', '£');
    result_text := REPLACE(result_text, '&yen;', '¥');
    result_text := REPLACE(result_text, '&cent;', '¢');

    -- Accented characters
    result_text := REPLACE(result_text, '&Agrave;','À');
    result_text := REPLACE(result_text, '&Aacute;','Á');
    result_text := REPLACE(result_text, '&Acirc;','Â');
    result_text := REPLACE(result_text, '&Atilde;','Ã');
    result_text := REPLACE(result_text, '&Auml;','Ä');
    result_text := REPLACE(result_text, '&AElig;','Æ');
    result_text := REPLACE(result_text, '&Ccedil;','Ç');
    result_text := REPLACE(result_text, '&Egrave;','È');
    result_text := REPLACE(result_text, '&Eacute;','É');
    result_text := REPLACE(result_text, '&Ecirc;','Ê');
    result_text := REPLACE(result_text, '&Euml;','Ë');
    result_text := REPLACE(result_text, '&Igrave;','Ì');
    result_text := REPLACE(result_text, '&Iacute;','Í');
    result_text := REPLACE(result_text, '&Icirc;','Î');
    result_text := REPLACE(result_text, '&Iuml;','Ï');
    result_text := REPLACE(result_text, '&ETH;','Ð');
    result_text := REPLACE(result_text, '&Ntilde;','Ñ');
    result_text := REPLACE(result_text, '&Ograve;','Ò');
    result_text := REPLACE(result_text, '&Oacute;','Ó');
    result_text := REPLACE(result_text, '&Ocirc;','Ô');
    result_text := REPLACE(result_text, '&Otilde;','Õ');
    result_text := REPLACE(result_text, '&Ouml;','Ö');
    result_text := REPLACE(result_text, '&Oslash;','Ø');
    result_text := REPLACE(result_text, '&Ugrave;','Ù');
    result_text := REPLACE(result_text, '&Uacute;','Ú');
    result_text := REPLACE(result_text, '&Ucirc;','Û');
    result_text := REPLACE(result_text, '&Uuml;','Ü');
    result_text := REPLACE(result_text, '&Yacute;','Ý');
    result_text := REPLACE(result_text, '&THORN;','Þ');
    result_text := REPLACE(result_text, '&szlig;','ß');
    result_text := REPLACE(result_text, '&agrave;','à');
    result_text := REPLACE(result_text, '&aacute;','á');
    result_text := REPLACE(result_text, '&acirc;','â');
    result_text := REPLACE(result_text, '&atilde;','ã');
    result_text := REPLACE(result_text, '&auml;','ä');
    result_text := REPLACE(result_text, '&aring;','å');
    result_text := REPLACE(result_text, '&aelig;','æ');
    result_text := REPLACE(result_text, '&ccedil;','ç');
    result_text := REPLACE(result_text, '&egrave;','è');
    result_text := REPLACE(result_text, '&eacute;','é');
    result_text := REPLACE(result_text, '&ecirc;','ê');
    result_text := REPLACE(result_text, '&euml;','ë');
    result_text := REPLACE(result_text, '&igrave;','ì');
    result_text := REPLACE(result_text, '&iacute;','í');
    result_text := REPLACE(result_text, '&icirc;','î');
    result_text := REPLACE(result_text, '&iuml;','ï');
    result_text := REPLACE(result_text, '&eth;','ð');
    result_text := REPLACE(result_text, '&ntilde;','ñ');
    result_text := REPLACE(result_text, '&ograve;','ò');
    result_text := REPLACE(result_text, '&oacute;','ó');
    result_text := REPLACE(result_text, '&ocirc;','ô');
    result_text := REPLACE(result_text, '&otilde;','õ');
    result_text := REPLACE(result_text, '&ouml;','ö');
    result_text := REPLACE(result_text, '&oslash;','ø');
    result_text := REPLACE(result_text, '&ugrave;','ù');
    result_text := REPLACE(result_text, '&uacute;','ú');
    result_text := REPLACE(result_text, '&ucirc;','û');
    result_text := REPLACE(result_text, '&uuml;','ü');
    result_text := REPLACE(result_text, '&yacute;','ý');
    result_text := REPLACE(result_text, '&thorn;','þ');
    result_text := REPLACE(result_text, '&yuml;','ÿ');

    result_text := REPLACE(result_text, '&OElig;','Œ');
    result_text := REPLACE(result_text, '&oelig;','œ');

    -- Handle hexadecimal numeric entities (&#xhhhh;)
    result_text := regexp_replace(result_text, '&#x([0-9a-fA-F]+);', E'\\x\\1', 'g');

    -- Handle numeric entities (decimal format &#nnn;)
    LOOP
        -- Find the first decimal entity
        SELECT substring(result_text from '&#([0-9]+);') INTO decimal_match;
        -- Exit if no more matches
        EXIT WHEN decimal_match IS NULL;
        -- Convert decimal to hex
        hex_value := to_hex(decimal_match::integer);
        -- Replace the first occurrence
        result_text := regexp_replace(result_text, '&#' || decimal_match || ';', chr(decimal_match::integer), '');
    END LOOP;

    RETURN result_text;
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS short_description;
CREATE OR REPLACE FUNCTION short_description(
    _description text,
    _min_length integer
) RETURNS text AS $$
DECLARE
    ret text;
BEGIN
    SELECT
        trim(regexp_replace(
            trim((xpath(
                'string(.)',
                xmlparse(document '<root>' || _description || '</root>')
            ))[1]::text),
            '((?:.{' || _min_length || '}[^\s]*)).*', '\1'
        ))
    INTO
        ret
    ;
    RETURN decode_html_entities(ret);
EXCEPTION WHEN OTHERS THEN
    -- Let's do the hack
    SELECT
        trim(regexp_replace(
            trim(
                regexp_replace(_description, '<[^>]+>', '', 'g')
            ),
            '((?:.{' || _min_length || '}[^\s]*)).*', '\1'
        ))
    INTO
        ret
    ;
    RETURN decode_html_entities(ret);
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS description_i18n;
CREATE OR REPLACE FUNCTION description_i18n(
    _description jsonb,
    _short_to_length integer
) RETURNS jsonb AS $$
    SELECT
        nullif(jsonb_strip_nulls(jsonb_object_agg(
            key,
            nullif(jsonb_strip_nulls(
                CASE
                WHEN _short_to_length IS NOT NULL AND short_description(value, _short_to_length) != short_description(value, NULL) THEN
                    jsonb_build_object(
                        'html', false,
                        'value', short_description(value, _short_to_length) || '…',
                        'is_shortened', true
                    )
                WHEN _short_to_length IS NOT NULL THEN
                    jsonb_build_object(
                        'html', false,
                        'value', short_description(value, _short_to_length)
                    )
                ELSE
                    jsonb_build_object(
                        'value', value
                    )
                END
            ), '{}'::jsonb)
        )), '{} '::jsonb)
    FROM
        jsonb_each_text(_description)
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;


CREATE OR REPLACE FUNCTION array_unique (a bigint[]) RETURNS bigint[] AS $$
  SELECT ARRAY (
    SELECT DISTINCT V FROM UNNEST(A) AS B(V) WHERE V IS NOT NULL
  )
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS pois_json_schema;
CREATE OR REPLACE FUNCTION pois_json_schema(
    _project_slug text
) RETURNS TABLE (
    d text
) AS $$
    WITH
    properties_schema AS (
        SELECT
            field AS property_name,
            "array",
            multilingual,
            json_schema
        FROM
            projects
            JOIN fields ON
                fields.project_id = projects.id AND
                fields.type = 'field' AND
                fields.json_schema IS NOT NULL AND
                fields.field NOT IN ('ref', 'source', 'coordinates')
        WHERE
            projects.slug = _project_slug
        ORDER BY
            field
    ),
    properties_schema_array AS (
        SELECT
            property_name,
            multilingual,
            CASE WHEN "array" THEN
                jsonb_build_object(
                    'type', 'array',
                    'items', json_schema
                )
            ELSE
                json_schema
            END AS json_schema
        FROM
            properties_schema
    ),
    properties_schema_multilingual AS (
        SELECT
            property_name,
            CASE WHEN multilingual THEN
                jsonb_build_object(
                    'type', 'object',
                    'properties', json_schema
                )
            ELSE
                json_schema
            END AS json_schema
        FROM
            properties_schema_array
    )
    SELECT
        ('{
            "type": "object",
            "required": ["type", "features"],
            "additionalProperties": false,
            "properties": {
                "type": {
                    "type": "string",
                    "enum": ["FeatureCollection"]
                },
                "features": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "required": ["type", "geometry", "properties"],
                        "additionalProperties": false,
                        "properties": {
                            "type": {
                                "type": "string",
                                "enum": ["Feature"]
                            },
                            "bbox": {
                                "type": "array",
                                "items": {
                                    "type": "number"
                                },
                                "minItems": 4,
                                "maxItems": 4
                            },
                            "geometry": {
                                "type": "object"
                            },
                            "properties": {
                                "type": "object",
                                "additionalProperties": true,
                                "properties":
' || jsonb_object_agg(property_name, json_schema)::text || '
                            }
                        }
                    }
                }
            }
        }') AS d
    FROM
        properties_schema_multilingual
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;


DROP TYPE IF EXISTS ref_kv CASCADE;
CREATE TYPE ref_kv AS (key text, value text);

DROP FUNCTION IF EXISTS pois_;
CREATE OR REPLACE FUNCTION pois_(
    _base_url text,
    _project_id integer,
    _project_slug text,
    _theme_slug text,
    _category_id bigint,
    _poi_ids bigint[],
    _poi_refs ref_kv[], -- array of set(ref, value)
    _geometry_as text,
    _short_description text,
    _start_date text,
    _end_date text,
    _with_deps text,
    _cliping_polygon geometry(Geometry, 4326)
) RETURNS TABLE (
    feature text,
    report_issue_url_template text,
    report_issue_values jsonb
) AS $$
    WITH
    menu AS (
        SELECT
            sources.id AS source_id,
            menu_items.slug,
            menu_items.id AS menu_id,
            coalesce(menu_items.name, '{}'::jsonb) || coalesce(menu_items.name_singular, '{}'::jsonb) AS name_singular,
            menu_items.use_internal_details_link,
            menu_items.use_external_details_link,
            sources.report_issue
        FROM
            menu_items_join AS menu_items
            JOIN menu_items_sources ON
                menu_items_sources.menu_items_id = menu_items.id
            JOIN sources ON
                sources.project_id = _project_id AND
                sources.id = menu_items_sources.sources_id
        WHERE
            menu_items.project_id = _project_id AND
            (_category_id IS NULL OR id_from_slugs_menu_item(menu_items.slug, menu_items.id) = _category_id)
    ),
    pois_selected AS (
        SELECT
            menu_id,
            pois_join.*
        FROM
            menu
            JOIN pois ON
                menu.source_id = pois.source_id AND
                (
                    _cliping_polygon IS NULL OR
                    ST_Intersects(pois.geom, _cliping_polygon)
                )
            JOIN pois_join_with_deps AS pois_join ON
                pois_join.source_id = menu.source_id AND
                pois_join.id = pois.id AND
                (
                    (
                        nullif(_poi_ids, '{}'::bigint[]) IS NULL AND
                        nullif(_poi_refs, ARRAY[]::ref_kv[]) IS NULL
                    ) OR
                    (
                        nullif(_poi_ids, '{}'::bigint[]) IS NOT NULL AND
                        pois_join.slug_id = ANY(_poi_ids)
                    ) OR
                    (
                        nullif(_poi_refs, ARRAY[]::ref_kv[]) IS NOT NULL AND (
                            pois_join.properties->'tags' ? 'ref' AND
                            pois_join.properties->'tags'->'ref' ?| (SELECT array_agg(DISTINCT key) FROM unnest(_poi_refs)) AND
                            jsonb_to_text_array(pois_join.properties->'tags'->'ref') && (SELECT array_agg(key || '=' || value) FROM unnest(_poi_refs))
                        )
                    )
                )
    ),
    pois_with_deps AS (
        SELECT
            *
        FROM
            pois_selected

        UNION

        SELECT
            menu_items.id AS menu_id,
            pois_join.*
        FROM
            pois_selected AS pois
            JOIN pois_join_without_deps AS pois_join ON
                pois_join.id = ANY(pois.dep_ids)
            JOIN sources ON
                sources.id = pois_join.source_id
            LEFT JOIN menu_items_sources ON
                menu_items_sources.sources_id = sources.id
            LEFT JOIN menu_items ON
                menu_items.id = menu_items_sources.menu_items_id
        WHERE
            _with_deps = 'true'
    ),
    json_pois AS (
        SELECT
            row_number() OVER (PARTITION BY pois.slug_id) = 1 AS first_one,
            CASE WHEN menu.report_issue->>'url_template' IS NOT NULL THEN pois.geom END AS geom,
            menu.report_issue->>'url_template' AS report_issue_url_template,
            menu.report_issue->'value_extractors' AS report_issue_value_extractors,
            jsonb_strip_nulls(jsonb_build_object(
                'type', 'Feature',
                'geometry', ST_AsGeoJSON(
                    CASE _geometry_as
                    WHEN 'point' THEN
                        CASE
                        WHEN ST_Dimension(pois.geom) = 0 THEN pois.geom
                        WHEN ST_Dimension(pois.geom) = 1 AND (jsonb_path_exists(pois.properties, '$.tags.route') OR jsonb_path_exists(pois.properties, '$.natives.route')) THEN ST_StartPoint(pois.geom)
                        ELSE ST_PointOnSurface(pois.geom)
                        END
                    WHEN 'bbox' THEN -- ST_Envelope(pois.geom)
                        -- When require bbox, geom should stay a point,
                        -- while using the dedicated bbox geojson attrib for bbox
                        CASE ST_Dimension(pois.geom)
                        WHEN 0 THEN pois.geom
                        ELSE ST_PointOnSurface(pois.geom)
                        END
                    WHEN 'point_or_bbox' THEN
                        CASE ST_Dimension(pois.geom)
                        WHEN 0 THEN pois.geom
                        ELSE ST_Envelope(pois.geom)
                        END
                    ELSE pois.geom
                    END,
                    9, 0)::jsonb,
                'bbox', CASE WHEN ST_Dimension(ST_Envelope(pois.geom)) > 0 THEN ST_AsGeoJSON(ST_Envelope(pois.geom), 9, 1)::jsonb->'bbox' END,
                'properties',
                    coalesce(pois.properties->'tags', '{}'::jsonb)
                        - 'name' - 'official_name' - 'loc_name' - 'alt_name'
                        - 'description' - 'website:details'
                        - 'route'
                        - 'ref' - 'source'
                        - 'colour' - 'colour:text' ||
                    coalesce(json_flat('ref', pois.properties->'tags'->'ref'), '{}'::jsonb) ||
                    coalesce(json_flat('source', pois.properties->'tags'->'source'), '{}'::jsonb) ||
                    (coalesce(pois.properties->'natives', '{}'::jsonb)
                        - 'name' - 'description' - 'short_description'
                        - 'website:details'
                        - 'route'
                        - 'route:waypoint:type'
                        - 'color_fill' - 'color_line'
                        - 'download'
                    ) ||
                    (CASE WHEN pois.image IS NOT NULL THEN jsonb_build_object('image', pois.image) ELSE '{}'::jsonb END) ||
                    jsonb_build_object(
                        'name', nullif(
                            coalesce(jsonb_strip_nulls(jsonb_build_object('fr-FR', menu.name_singular->'fr')), '{}'::jsonb) ||
                            coalesce(pois.properties->'natives'->'name', '{}'::jsonb) ||
                            coalesce(pois.properties->'tags'->'name', '{}'::jsonb),
                            '{}'::jsonb
                        ),
                        'official_name', pois.properties->'tags'->'official_name',
                        'loc_name', pois.properties->'tags'->'loc_name',
                        'alt_name', pois.properties->'tags'->'alt_name',
                        'description', CASE
                            WHEN _short_description = 'true' THEN description_i18n(
                                coalesce(pois.properties->'natives'->'description', '{}'::jsonb) ||
                                coalesce(pois.properties->'natives'->'short_description', '{}'::jsonb) ||
                                coalesce(pois.properties->'tags'->'description', '{}'::jsonb),
                                130
                            )
                            ELSE description_i18n(
                                coalesce(pois.properties->'natives'->'short_description', '{}'::jsonb) ||
                                coalesce(pois.properties->'natives'->'description', '{}'::jsonb) ||
                                coalesce(pois.properties->'tags'->'description', '{}'::jsonb),
                                NULL
                            )
                            END,
                        'download',
                            CASE jsonb_typeof(pois.properties->'natives'->'download')
                                WHEN 'string' THEN jsonb_build_array(pois.properties->'natives'->'download')
                                ELSE pois.properties->'natives'->'download'
                            END,
                        'route', coalesce(
                            nullif(jsonb_strip_nulls(jsonb_build_object('fr-FR', nullif(jsonb_strip_nulls((pois.properties->'tags'->'route'->'fr-FR') - 'waypoint:type'), '{}'::jsonb))), '{}'::jsonb),
                            nullif(jsonb_strip_nulls(jsonb_build_object('fr-FR', nullif(jsonb_strip_nulls((pois.properties->'natives'->'route'->'fr-FR') ||
                                coalesce(
                                    CASE ST_Dimension(pois.geom) WHEN 1 THEN jsonb_strip_nulls(jsonb_build_object('gpx_trace', _base_url || '/api/0.2/' || _project_slug || '/' || _theme_slug || '/poi/' || pois.slug_id || '/deps.gpx')) END,
                                    '{}'::jsonb
                                )
                            ), '{}'::jsonb))), '{}'::jsonb)
                        ),
                        'route:point:type', coalesce(
                            pois.properties->'tags'->'route'->'fr-FR'->'waypoint:type',
                            pois.properties->'natives'->'route:waypoint:type'
                        ),
                        'metadata', jsonb_build_object(
                            'id', pois.slug_id,
                            -- cartocode
                            'category_ids', nullif(array_unique(array_agg(id_from_slugs_menu_item(menu.slug, menu.menu_id)) OVER (PARTITION BY pois.slug_id)), ARRAY[]::bigint[]),
                            'updated_at', pois.properties->'updated_at',
                            'source', pois.properties->'source',
                            'osm_id', CASE WHEN pois.properties->>'source' LIKE '%openstreetmap%' AND pois.properties->>'id' ~ E'^.\\d+$' THEN substr(pois.properties->>'id', 2)::bigint END,
                            'osm_type',
                                CASE WHEN pois.properties->>'source' LIKE '%openstreetmap%' THEN
                                    CASE substr(pois.properties->>'id', 1, 1)
                                    WHEN 'n' THEN 'node'
                                    WHEN 'w' THEN 'way'
                                    WHEN 'r' THEN 'relation'
                                    END
                                END,
                            'dep_ids', dep_original_ids,
                            'report_issue_url', CASE WHEN menu.report_issue->>'url_template' IS NOT NULL THEN '__report_issue_url_template__' END
                        ),
                        'editorial', nullif(jsonb_strip_nulls(jsonb_build_object(
                            'website:details', nullif(jsonb_strip_nulls(jsonb_build_object('fr-FR', coalesce(
                                CASE WHEN menu.use_external_details_link THEN coalesce(
                                    pois.properties->'tags'->'website:details'->>'fr-FR',
                                    pois.properties->'natives'->'website:details'->>'fr-FR'
                                ) END,
                                CASE WHEN menu.use_internal_details_link THEN _base_url || '/poi/' || pois.slug_id || '/details' END
                            ))), '{}'::jsonb)
                        )), '{}'::jsonb),
                        'display', nullif(jsonb_strip_nulls(jsonb_build_object(
                            'color_fill', coalesce(pois.properties->'natives'->>'color_fill', pois.properties->'tags'->>'colour'),
                            'color_line', coalesce(pois.properties->'natives'->>'color_line', pois.properties->'tags'->>'colour'),
                            'color_text', pois.properties->'tags'->>'colour:text'
                        )), '{}'::jsonb)
                    )
            )) AS feature
        FROM
            pois_with_deps AS pois
            LEFT JOIN menu ON
                menu.menu_id = pois.menu_id AND
                menu.source_id = pois.source_id
        WHERE
            (
                _start_date IS NULL OR
                coalesce(pois.properties->'tags'->'start_end_date'->>'start_date', pois.properties->'natives'->'start_end_date'->>'start_date') IS NULL OR
                coalesce(pois.properties->'tags'->'start_end_date'->>'start_date', pois.properties->'natives'->'start_end_date'->>'start_date') <= _start_date
            ) AND
            (
                _end_date IS NULL OR
                coalesce(pois.properties->'tags'->'start_end_date'->>'end_date', pois.properties->'natives'->'start_end_date'->>'end_date') IS NULL OR
                coalesce(pois.properties->'tags'->'start_end_date'->>'end_date', pois.properties->'natives'->'start_end_date'->>'end_date') >= _end_date
            )
        ORDER BY
            menu.menu_id,
            pois.slug_id
    ),
    json_pois_report_issue AS (
        SELECT
            feature,
            report_issue_url_template,
            (
                SELECT
                     jsonb_object_agg(
                        key,
                        CASE value
                            WHEN '[[geom.lon]]' THEN ST_X(ST_PointOnSurface(geom))::text::jsonb
                            WHEN '[[geom.lat]]' THEN ST_Y(ST_PointOnSurface(geom))::text::jsonb
                            ELSE (SELECT * FROM jsonb_path_query(feature->'properties', value::jsonpath) LIMIT 1)
                        END
                    )
                FROM
                    jsonb_each_text(report_issue_value_extractors)
            ) AS report_issue_values
        FROM
            json_pois
    WHERE
        first_one
    )
    SELECT
        replace(feature::text, '__base_url__', _base_url) AS feature,
        report_issue_url_template,
        report_issue_values
    FROM
        json_pois_report_issue
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;

DROP FUNCTION IF EXISTS pois;
CREATE OR REPLACE FUNCTION pois(
    _base_url text,
    _project_slug text,
    _theme_slug text,
    _category_id bigint,
    _poi_ids bigint[],
    _poi_refs jsonb, -- array of object of one key [{ref: value}, ...]
    _geometry_as text,
    _short_description text,
    _start_date text,
    _end_date text,
    _with_deps text,
    _cliping_polygon_slug text
) RETURNS TABLE (
    feature text,
    report_issue_url_template text,
    report_issue_values jsonb
) AS $$
    WITH
    projects AS (
        SELECT
            id,
            polygons_extra
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
                SELECT source_id, geom, slugs->>'original_id' AS slug_id FROM pois
            ) AS pois ON
                pois.source_id = sources.id AND
                pois.slug_id = projects.polygons_extra->>_cliping_polygon_slug
            WHERE
                _cliping_polygon_slug IS NOT NULL
        LIMIT 1
    )
    SELECT * FROM pois_(
        _base_url,
        (SELECT id FROM projects), _project_slug, _theme_slug,
        _category_id, _poi_ids,
        (SELECT array_agg(row((t.t).key, (t.t).value)::ref_kv) FROM (SELECT jsonb_each_text(j) FROM jsonb_array_elements(_poi_refs) AS t(j)) AS t(t)), _geometry_as, _short_description, _start_date, _end_date, _with_deps,
        (SELECT geom FROM cliping_polygon)
    )
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
    translation_fields AS (
        SELECT
            coalesce(fields.group, fields.field) AS key,
            CASE WHEN fields_translations.name IS NULL THEN NULL ELSE json_build_object(
                '@default', json_build_object(
                    languages_code, fields_translations.name
                ),
                '@small', json_build_object(
                    languages_code, fields_translations.name_small
                ),
                '@large', json_build_object(
                    languages_code, fields_translations.name_large
                ),
                '@title', json_build_object(
                    languages_code, fields_translations.name_title
                )
            ) END AS key_translations,
            values_translations
        FROM
            projects
            JOIN fields ON
                fields.project_id = projects.id
            LEFT JOIN fields_translations ON
                starts_with(fields_translations.languages_code, _lang) AND
                fields_translations.fields_id = fields.id
        WHERE
            projects.slug = _project_slug
    ),
    translations_local AS (
        SELECT
            replace(field, '___', ':') AS key,
            json_build_object(
                '@default', json_build_object(
                    -- TODO loop to get the right language translations
                    translations->0->>'language', translations->0->'translation'
                )
            ) AS key_translations,
            NULL::json AS values_translations
        FROM
            directus_fields
        WHERE
            directus_fields.collection LIKE 'local-' || _project_slug || '-%' AND
            translations IS NOT NULL
    ),
    translation AS (
        SELECT
            key,
            jsonb_merge_agg(coalesce(key_translations::jsonb, '{}'::jsonb)) AS key_translations,
            jsonb_merge_agg(coalesce(values_translations::jsonb, '{}'::jsonb)) AS values_translations
        FROM (
            SELECT * FROM translation_fields
            UNION ALL
            SELECT * FROM translations_local
        )
        GROUP BY
            key
    )
    SELECT
        jsonb_strip_nulls(jsonb_object_agg(
            key, nullif(jsonb_strip_nulls(jsonb_build_object(
                'label', CASE WHEN key_translations->'@default'->>'fr-FR' IS NOT NULL THEN jsonb_build_object(
                    'fr', capitalize(key_translations->'@default'->>'fr-FR')
                ) END,
                'label_popup', CASE WHEN key_translations->'@small'->>'fr-FR' IS NOT NULL THEN jsonb_build_object(
                    'fr', capitalize(key_translations->'@small'->>'fr-FR')
                ) END,
                'label_details', CASE WHEN key_translations->'@large'->>'fr-FR' IS NOT NULL THEN jsonb_build_object(
                    'fr', capitalize(key_translations->'@large'->>'fr-FR')
                ) END,
                'label_list', CASE WHEN key_translations->'@title'->>'fr-FR' IS NOT NULL THEN jsonb_build_object(
                    'fr', capitalize(key_translations->'@title'->>'fr-FR')
                ) END,
                'values', nullif(jsonb_strip_nulls((
                    SELECT
                        jsonb_object_agg(
                            key, nullif(jsonb_strip_nulls(jsonb_build_object(
                                'label', nullif(jsonb_strip_nulls(jsonb_build_object(
                                    'fr', capitalize(value->'@default:full'->>'fr-FR')
                                )), '{}'::jsonb),
                                'label_list', nullif(jsonb_strip_nulls(jsonb_build_object(
                                    'fr', capitalize(value->'@default:short'->>'fr-FR')
                                )), '{}'::jsonb)
                            )), '{}'::jsonb)
                        )
                    FROM
                        jsonb_each(values_translations)
                )), '{}'::jsonb)
            )), '{}'::jsonb)
        ORDER BY key))::text
    FROM
        translation
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;
