CREATE SCHEMA IF NOT EXISTS api01;
SET search_path TO api01,public;

DROP FUNCTION IF EXISTS capitalize;
CREATE FUNCTION capitalize(str text) RETURNS text AS $$
    SELECT
        upper(substring(str from 1 for 1)) ||
        substring(str from 2 for length(str))
    ;
$$ LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE;


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
    jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.name) AS name
FROM
    projects
    JOIN projects_translations AS trans ON
        trans.projects_id = projects.id
GROUP BY
    projects.id
;

DROP VIEW IF EXISTS articles_join;
CREATE VIEW articles_join AS
SELECT
    articles.*,
    jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.title) AS title,
    jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.slug) AS slug,
    jsonb_object_agg(substring(trans.languages_code, 1, 2), trans.body) AS body
FROM
    articles
    JOIN articles_translations AS trans ON
        trans.articles_id = articles.id
GROUP BY
    articles.id
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

DROP VIEW IF EXISTS pois_join;
CREATE VIEW pois_join AS
WITH
pois AS (
    SELECT
        pois.*,
        nullif(jsonb_agg(to_jsonb(
            -- _base_url || '/assets/' || pois_files.directus_files_id::text || '/' || directus_files.filename_download
            '/assets/' || pois_files.directus_files_id::text || '/' || directus_files.filename_download
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
)
SELECT
    pois.id,
    pois.geom,
    pois.source_id,
    pois.properties,
    pois.website_details,
    pois.image,
    pois.slug_id,
    nullif(
        array_agg(pois_pois.children_pois_id ORDER BY index),
        ARRAY[NULL::integer]
    ) AS dep_ids
FROM
    pois
    LEFT JOIN pois_pois ON
        pois_pois.parent_pois_id = pois.id
GROUP BY
    pois.id,
    pois.geom,
    pois.source_id,
    pois.properties,
    pois.website_details,
    pois.image,
    pois.slug_id
;

DROP FUNCTION IF EXISTS project;
CREATE OR REPLACE FUNCTION project(
    _base_url text,
    _project_slug text
) RETURNS TABLE (
    d text
) AS $$
    SELECT
        jsonb_strip_nulls(
            to_jsonb(projects.*) - 'name' - 'polygon' - 'bbox_line' - 'icon_font_css_url' - 'api_key' - 'datasources_slug' ||
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
                'icon_font_css_url', _base_url || projects.icon_font_css_url,
                'attributions', coalesce((
                    SELECT
                        array_agg(DISTINCT attribution)
                    FROM
                        sources
                    WHERE
                        sources.project_id = projects.id AND
                        attribution IS NOT NULL
                ), array[]::text[]),
                'articles', (
                    SELECT
                        jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
                            'url', (SELECT _base_url || '/api/0.1/' || projects.slug || '/' || themes.slug || '/article/' || (articles.slug->>'fr') || '.html' FROM themes_join AS themes WHERE themes.project_id = projects.id LIMIT 1),
                            'title', articles.title->'fr'
                        )) ORDER BY projects_articles.index)
                    FROM
                        projects_articles
                        JOIN articles_join AS articles ON
                            articles.id = projects_articles.articles_id
                    WHERE
                        projects_articles.projects_id = projects.id
                ),
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


DROP TABLE IF EXISTS pois_local;
CREATE TABLE pois_local AS SELECT * FROM pois_join LIMIT 0;
ALTER TABLE pois_local ADD CONSTRAINT pois_local_pkey PRIMARY KEY (id);
ALTER TABLE pois_local ADD CONSTRAINT pois_local_source_id FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE CASCADE;
CREATE INDEX pois_local_idx_geom ON pois_local USING gist(geom);
CREATE INDEX pois_local_idx_source_id ON pois_local(source_id);
CREATE INDEX pois_local_idx_slug_id ON pois_local(slug_id);

-- trigger to replicate change of local-* table into pois_local
CREATE OR REPLACE FUNCTION pois_local_trigger(
    _op text,
    _table text,
    _id bigint
) RETURNS VOID AS $$
BEGIN
    IF _op = 'DELETE' THEN
        DELETE FROM api01.pois_local WHERE id = _id;
    ELSE
        EXECUTE '
            INSERT INTO
                api01.pois_local(id, geom, source_id, properties, website_details, image, slug_id, dep_ids)
            SELECT
                id, geom, source_id, properties, NULL AS website_details, image, slug_id, NULL AS dep_ids
            FROM
                "' || substring(_table, 1, 63 - 2) || '_v" WHERE id = ' || _id || '
            ON CONFLICT (id) DO UPDATE SET
                geom = EXCLUDED.geom,
                source_id = EXCLUDED.source_id,
                properties = EXCLUDED.properties,
                website_details = EXCLUDED.website_details,
                image = EXCLUDED.image,
                slug_id = EXCLUDED.slug_id,
                dep_ids = EXCLUDED.dep_ids
        ';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pois_local_trigger()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM api01.pois_local_trigger(TG_OP, TG_TABLE_NAME, coalesce(NEW.id, OLD.id));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pois_local_it_trigger()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM api01.pois_local_trigger(TG_OP, left(TG_TABLE_NAME, -2), coalesce(NEW.pois_id, OLD.pois_id));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS create_pois_local_view;
CREATE OR REPLACE FUNCTION create_pois_local_view(
    _source_id integer,
    _table_name text
) RETURNS TABLE(
    name text
) AS $$
DECLARE
    source record;
BEGIN
    FOR source IN
        SELECT
            _source_id AS id,
            tables.table_name,
            regexp_replace(tables.table_name, 'local-[a-z0-9_]+-', '') || '_id' AS local_id,
            tables_t.table_name AS table_name_t,
            tables_i.table_name AS table_name_i,
            array_agg(key_column_usage.column_name) AS file_fields
        FROM
            information_schema.tables
            -- Translations
            LEFT JOIN information_schema.tables AS tables_t ON
                tables_t.table_name = substring(tables.table_name, 1, 63 - 2) || '_t'
            -- Many files fields
            LEFT JOIN information_schema.tables AS tables_i ON
                tables_i.table_name = substring(tables.table_name, 1, 63 - 2) || '_i'
            -- One file fields
            LEFT JOIN information_schema.table_constraints ON
                table_constraints.table_name = tables.table_name AND
                table_constraints.table_schema = 'public' AND
                table_constraints.constraint_type = 'FOREIGN KEY'
            LEFT JOIN information_schema.key_column_usage ON
                key_column_usage.constraint_name = table_constraints.constraint_name AND
                key_column_usage.table_schema = 'public' AND
                key_column_usage.table_name = tables.table_name AND
                key_column_usage.column_name != 'project_id'
        WHERE
            tables.table_name = _table_name
        GROUP BY
            tables.table_name,
            tables_t.table_name,
            tables_i.table_name
    LOOP
        EXECUTE 'DROP VIEW IF EXISTS public."' || substring(source.table_name, 1, 63 - 2) || '_v" CASCADE';
        EXECUTE '
            CREATE OR REPLACE VIEW public."' || substring(source.table_name, 1, 63 - 2) || '_v" AS
            WITH ' ||
            CASE WHEN source.table_name_t IS NULL THEN '' ELSE '
            j AS (
                SELECT
                    pois_id AS id,
                    languages_code AS languages_code,
                    (jsonb_each_text(row_to_json(t.*)::jsonb - ''id'' - ''languages_code'' - ''pois_id'')).key,
                    (jsonb_each_text(row_to_json(t.*)::jsonb - ''id'' - ''languages_code'' - ''pois_id'')).value
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
                        ''__base_url__/assets/'' || pois_files.directus_files_id::text || ''/'' || directus_files.filename_download
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
                t.project_id,
                t.id,
                geom,
                jsonb_strip_nulls(jsonb_build_object(
                    ''id'', t.id,
                    ''source'', NULL,
                    ''updated_at'', NULL,
                    ''natives'', (SELECT jsonb_object_agg(replace(key, ''___'', '':''), value) FROM jsonb_each(jsonb_strip_nulls(
                        row_to_json(t.*)::jsonb - ''id'' - ''project_id'' - ''geom'' || ' ||
                        CASE WHEN source.table_name_t IS NULL THEN '''{}''::jsonb' ELSE '
                        trans.jsonb' END || ' ||
                        jsonb_build_object(' ||
                            (SELECT array_to_string(array_agg('''' || f || ''', ''__base_url__/assets/'' || "directus_files_' || f || '".id::text || ''/'' || "directus_files_' || f || '".filename_download'), ', ') FROM unnest(source.file_fields) AS fields(f)) ||
                        ')
                    )))
                )) AS properties, ' ||
                CASE WHEN source.table_name_i IS NULL
                THEN 'NULL::jsonb'
                ELSE 'pois_files.image'
                END || ' AS image,
                ' || _source_id || ' AS source_id,
                json_build_object(''original_id'', t.id) AS slugs,
                t.id AS slug_id
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
        '';
        name :=  substring(source.table_name, 1, 63 - 2) || '_v';

        EXECUTE '
            DROP TRIGGER IF EXISTS "' || substring(source.table_name, 1, 63 - 2) || '_t" ON "' || source.table_name || '";
            CREATE TRIGGER "' || substring(source.table_name, 1, 63 - 2) || '_t"
            AFTER INSERT OR UPDATE OR DELETE
            ON "' || source.table_name || '"
            FOR EACH ROW
            EXECUTE FUNCTION api01.pois_local_trigger();
        ';

        IF source.table_name_i IS NOT NULL THEN
            EXECUTE '
                DROP TRIGGER IF EXISTS "' || substring(source.table_name_i, 1, 63 - 2) || '_t" ON "' || source.table_name_i || '";
                CREATE TRIGGER "' || substring(source.table_name_i, 1, 63 - 2) || '_t"
                AFTER INSERT OR UPDATE OR DELETE
                ON "' || source.table_name_i || '"
                FOR EACH ROW
                EXECUTE FUNCTION api01.pois_local_it_trigger();
            ';
        END IF;

        IF source.table_name_t IS NOT NULL THEN
            EXECUTE '
                DROP TRIGGER IF EXISTS "' || substring(source.table_name_t, 1, 63 - 2) || '_t" ON "' || source.table_name_t || '";
                CREATE TRIGGER "' || substring(source.table_name_t, 1, 63 - 2) || '_t"
                AFTER INSERT OR UPDATE OR DELETE
                ON "' || source.table_name_t || '"
                FOR EACH ROW
                EXECUTE FUNCTION api01.pois_local_it_trigger();
            ';
        END IF;

        -- Touch all data to force update of pois_local
        EXECUTE '
            UPDATE "' || source.table_name ||'" SET id = id
        ';

        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql PARALLEL SAFE;

DROP FUNCTION IF EXISTS create_project_pois_local_view;
CREATE OR REPLACE FUNCTION create_project_pois_local_view(
    _project_slug text
) RETURNS TABLE(
    project_id integer,
    name text,
    count integer
) AS $$
    SELECT
        projects.id AS id,
        projects.slug AS slug,
        count(*) AS count
    FROM
        projects
        JOIN sources ON
            sources.project_id = projects.id
        JOIN LATERAL create_pois_local_view(
                sources.id,
                substring('local-' || projects.slug || '-' || sources.slug, 1, 63)
            ) AS view ON true
    WHERE
        _project_slug IS NULL OR projects.slug = _project_slug
    GROUP BY
        projects.id
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;

SELECT * FROM create_project_pois_local_view(NULL);


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
            pois.properties
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
            pois.properties
        FROM
            pois_local AS pois
            JOIN sources ON
                sources.id = pois.source_id
        WHERE
            jsonb_pois_keys_array(properties) @> ARRAY[split_part(_property, ':', 1)]
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
                    'name', jsonb_build_object(
                        'fr', capitalize(fields.values_translations->value->'@default:full'->>'fr-FR')
                    )
                )
            )
        ) AS filter_values
    FROM
        values_uniq
        LEFT JOIN fields ON
            fields.project_id = values_uniq.project_id AND
            fields.field = _property
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
                        'property', fields_multiselection.field,
                        'values', coalesce(
                            (SELECT filter_values FROM filter_values(_base_url, _project_slug, fields_multiselection.field) AS f WHERE f.project_id = menu_items.project_id AND f.menu_items_id = menu_items.id),
                            '[]'::jsonb
                        )
                    )
                WHEN 'checkboxes_list' THEN
                    jsonb_build_object(
                        'property', fields_checkboxes_list.field,
                        'values', coalesce(
                            (SELECT filter_values FROM filter_values(_base_url, _project_slug, fields_checkboxes_list.field) AS f WHERE f.project_id = menu_items.project_id AND f.menu_items_id = menu_items.id),
                            '[]'::jsonb
                        )
                    )
                WHEN 'boolean' THEN
                    jsonb_build_object(
                        'property', fields_boolean.field
                    )
                WHEN 'date_range' THEN
                    jsonb_build_object(
                        'property_begin', fields_date_range_begin.field,
                        'property_end', fields_date_range_end.field
                    )
                WHEN 'number_range' THEN
                    jsonb_build_object(
                        'property', fields_number_range.field,
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
            LEFT JOIN fields AS fields_checkboxes_list ON
                fields_checkboxes_list.id = filters.checkboxes_list_property AND
                fields_checkboxes_list.type = 'field'
            LEFT JOIN fields AS fields_boolean ON
                fields_boolean.id = filters.boolean_property AND
                fields_boolean.type = 'field'
            LEFT JOIN fields AS fields_date_range_begin ON
                fields_date_range_begin.id = filters.property_begin AND
                fields_date_range_begin.type = 'field'
            LEFT JOIN fields AS fields_date_range_end ON
                fields_date_range_end.id = filters.property_end AND
                fields_date_range_end.type = 'field'
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


DROP TYPE IF EXISTS field_size_t CASCADE;
CREATE TYPE field_size_t AS ENUM ('small', 'large');

DROP FUNCTION IF EXISTS fields;
CREATE OR REPLACE FUNCTION fields(
    _root_field_id integer,
    field_size field_size_t
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
                'label', nullif(
                    CASE field_size
                        WHEN 'small'::field_size_t THEN fields.label_small
                        WHEN 'large'::field_size_t THEN fields.label_large
                    END,
                    false
                ),
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
                'label', nullif(
                    CASE field_size
                        WHEN 'small'::field_size_t THEN fields.label_small
                        WHEN 'large'::field_size_t THEN fields.label_large
                    END,
                    false
                ),
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
    RETURN ret;
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
    RETURN ret;
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS pois_;
CREATE OR REPLACE FUNCTION pois_(
    _base_url text,
    _project_id integer,
    _theme_slug text,
    _category_id bigint,
    _poi_ids bigint[],
    _geometry_as text,
    _short_description boolean,
    _start_date text,
    _end_date text,
    _with_deps boolean,
    _cliping_polygon geometry(Geometry, 4326)
) RETURNS TABLE (
    d text
) AS $$
    WITH
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
            (
                SELECT
                    *,
                    fields(menu_items.popup_fields_id, 'small'::field_size_t)->'fields' AS popup_fields,
                    fields(menu_items.details_fields_id, 'large'::field_size_t)->'fields' AS details_fields,
                    fields(menu_items.list_fields_id, NULL)->'fields' AS list_fields
                FROM
                    menu_items_join AS menu_items
            ) AS menu_items
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
            JOIN pois_join ON
                pois_join.source_id = menu.source_id AND
                pois_join.id = pois.id AND
                (
                    _poi_ids IS NULL OR
                    pois_join.slug_id = ANY(_poi_ids)
                )

        UNION ALL

        SELECT
            menu_id,
            pois_join.*
        FROM
            menu
            JOIN pois_local AS pois ON
                menu.source_id = pois.source_id AND
                (
                    _cliping_polygon IS NULL OR
                    ST_Intersects(pois.geom, _cliping_polygon)
                )
            JOIN pois_local AS pois_join ON
                pois_join.source_id = menu.source_id AND
                pois_join.id = pois.id AND
                (
                    _poi_ids IS NULL OR
                    pois_join.slug_id = ANY(_poi_ids)
                )
    ),
    pois_with_deps AS (
        SELECT
            *
        FROM
            pois_selected

        UNION

        SELECT DISTINCT ON (pois_join.id)
            coalesce(menu_items.id, (SELECT menu_id FROM menu LIMIT 1)) AS menu_id,
            pois_join.*
        FROM
            pois_selected AS pois
            JOIN pois_join ON
                _with_deps = true AND
                pois_join.id = ANY(pois.dep_ids)
            JOIN sources ON
                sources.id = pois_join.source_id
            LEFT JOIN menu_items_sources ON
                menu_items_sources.sources_id = sources.id
            LEFT JOIN menu_items ON
                menu_items.id = menu_items_sources.menu_items_id
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
                    END
                )::jsonb,
                'bbox', CASE WHEN ST_Dimension(ST_Envelope(pois.geom)) > 0 THEN ST_Envelope(pois.geom) END,
                'properties',
                    coalesce(pois.properties->'tags', '{}'::jsonb)
                        - 'name' - 'official_name' - 'loc_name' - 'alt_name'
                        - 'description' - 'website:details'
                        - 'addr' - 'ref' - 'route' - 'source'
                        - 'colour' - 'colour:text' ||
                    coalesce(json_flat('addr', pois.properties->'tags'->'addr'), '{}'::jsonb) ||
                    coalesce(json_flat('ref', pois.properties->'tags'->'ref'), '{}'::jsonb) ||
                    coalesce(
                        CASE jsonb_typeof(pois.properties->'tags'->'route')
                            WHEN 'object' THEN json_flat('route',
                                    (pois.properties->'tags'->'route') - 'pdf' - 'waypoint:type' ||
                                    jsonb_build_object('pdf', pois.properties->'tags'->'route'->'pdf'->'fr-FR')
                                )
                            ELSE jsonb_build_object('route', pois.properties->'tags'->'route')
                        END, '{}'::jsonb) ||
                    coalesce(json_flat('source', pois.properties->'tags'->'source'), '{}'::jsonb) ||
                    (coalesce(pois.properties->'natives', '{}'::jsonb) - 'name' - 'description' - 'website:details') ||
                    (CASE WHEN pois.image IS NOT NULL THEN jsonb_build_object('image', pois.image) ELSE '{}'::jsonb END) ||
                    jsonb_build_object(
                        'name', coalesce(
                            pois.properties->'tags'->'name'->>'fr-FR',
                            pois.properties->'natives'->'name'->>'fr-FR',
                            menu.name_singular
                        ),
                        'official_name', pois.properties->'tags'->'official_name'->'fr-FR',
                        'loc_name', pois.properties->'tags'->'loc_name'->'fr-FR',
                        'alt_name', pois.properties->'tags'->'alt_name'->'fr-FR',
                        'description',
                            CASE _short_description
                            -- TODO strip html tags before substr
                            WHEN 'true' THEN short_description(coalesce(
                                pois.properties->'tags'->'description'->>'fr-FR',
                                pois.properties->'natives'->'short_description'->>'fr-FR',
                                pois.properties->'natives'->'description'->>'fr-FR'
                            ), 130)
                            ELSE coalesce(
                                pois.properties->'tags'->'description'->>'fr-FR',
                                pois.properties->'natives'->'description'->>'fr-FR',
                                pois.properties->'natives'->'short_description'->>'fr-FR'
                            )
                            END,
                        'short_description',
                            CASE _short_description
                            WHEN 'false' THEN
                                pois.properties->'natives'->'short_description'->>'fr-FR'
                            END,
                        'route:point:type',  replace(pois.properties->'tags'->'route'->>'waypoint:type', 'waypoint', 'way_point'),
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
                                END,
                            'dep_ids', dep_ids
                        ),
                        'editorial', menu.editorial || jsonb_build_object(
                            'website:details', coalesce(
                                pois.website_details,
                                CASE WHEN menu.use_external_details_link THEN coalesce(
                                    pois.properties->'tags'->'website:details'->>'fr-FR',
                                    pois.properties->'natives'->>'website:details'
                                ) END,
                                CASE WHEN menu.use_internal_details_link THEN _base_url || '/poi/' || pois.slug_id || '/details' END
                            )
                        ),
                        'display', menu.display || jsonb_strip_nulls(jsonb_build_object(
                            'color_fill', pois.properties->'tags'->'colour',
                            'color_line', pois.properties->'tags'->'colour',
                            'color_text', pois.properties->'tags'->'colour:text'
                        ))
                    )
            )) AS feature
        FROM
            menu
            JOIN pois_with_deps AS pois ON
                pois.menu_id = menu.menu_id
        WHERE
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
                UNION ALL
                SELECT source_id, geom, slug_id::text FROM pois_local
            ) AS pois ON
                pois.source_id = sources.id AND
                pois.slug_id = projects.polygons_extra->>_cliping_polygon_slug
            WHERE
                _cliping_polygon_slug IS NOT NULL
        LIMIT 1
    )
    SELECT * FROM pois_(
        _base_url,
        (SELECT id FROM projects),
        _theme_slug, _category_id, _poi_ids, _geometry_as, _short_description, _start_date, _end_date, _with_deps,
        (SELECT geom FROM cliping_polygon)
    )
$$ LANGUAGE sql STABLE PARALLEL SAFE;


CREATE OR REPLACE AGGREGATE jsonb_merge_agg(jsonb)
(
    sfunc = jsonb_concat,
    stype = jsonb,
    initcond = '{}'
);

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
                    substring(translations->0->>'language', 1, 2), translations->0->'translation'
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
            key, jsonb_build_object(
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
                'values', (
                    SELECT
                        jsonb_object_agg(
                            key, jsonb_build_object(
                                'label', jsonb_build_object(
                                    'fr', capitalize(value->'@default:full'->>'fr-FR')
                                )
                            )
                        )
                    FROM
                        jsonb_each(values_translations)
                )
            )
        ORDER BY key))::text
    FROM
        translation
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;
