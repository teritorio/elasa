CREATE SCHEMA IF NOT EXISTS api01;
SET search_path TO api01,public;

-- trigger to replicate change of local-* table into pois_local
CREATE OR REPLACE FUNCTION pois_local_trigger(
    _op text,
    _table text,
    _id bigint
) RETURNS VOID AS $$
BEGIN
    IF _op = 'DELETE' THEN
        EXECUTE '
            DELETE FROM
                pois
            WHERE
                (pois.slugs->>''original_id'')::integer = ' || _id || ' AND
                pois.source_id = (
                    SELECT
                        sources.id
                    FROM
                        projects
                        JOIN sources ON
                            sources.project_id = projects.id
                    WHERE
                        projects.slug = split_part(''' || _table || ''', ''-'', 2) AND
                        sources.slug = split_part(''' || _table || ''', ''-'', 3)
                )
        ';
    ELSE
        EXECUTE '
            MERGE INTO
                pois
            USING (
                SELECT
                    geom, properties, source_id, jsonb_build_object(''original_id'', slug_id) AS slugs, NULL AS website_details
                FROM
                    "' || substring(_table, 1, 63 - 2) || '_v" WHERE id = ' || _id || '
            ) AS local_pois
            ON
                pois.source_id = local_pois.source_id AND
                pois.slugs->>''original_id'' = local_pois.slugs->>''original_id''
            WHEN NOT MATCHED THEN
                INSERT (geom, properties, source_id, slugs, website_details) VALUES
                    (local_pois.geom, local_pois.properties, local_pois.source_id, local_pois.slugs, local_pois.website_details)
            WHEN MATCHED THEN
                UPDATE SET
                    geom = local_pois.geom,
                    properties = local_pois.properties,
                    source_id = local_pois.source_id,
                    slugs = local_pois.slugs,
                    website_details = local_pois.website_details
        ';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pois_local_i_trigger(
    _op text,
    _table text,
    _poi_id bigint,
    _directus_files_id uuid,
    _index integer
) RETURNS VOID AS $$
BEGIN
    IF _op = 'DELETE' THEN
        EXECUTE '
            DELETE FROM
                pois_files
            USING
                "' || substring(_table, 1, 63 - 2) || '_v" AS local_pois,
                pois
            WHERE
                local_pois.id = ' || _poi_id || ' AND

                pois.source_id = local_pois.source_id AND
                (pois.slugs->>''original_id'')::integer = (local_pois.slugs->>''original_id'')::integer AND

                pois_files.pois_id = pois.id AND
                pois_files.directus_files_id = ''' || _directus_files_id || '''
        ';
    ELSE
        EXECUTE '
            INSERT INTO
                pois_files(pois_id, directus_files_id, index)
            SELECT
                pois.id, ''' || _directus_files_id || ''', ' || _index || '
            FROM
                "' || substring(_table, 1, 63 - 2) || '_v" AS local_pois
                JOIN pois ON
                    pois.source_id = local_pois.source_id AND
                    (pois.slugs->>''original_id'')::integer = (local_pois.slugs->>''original_id'')::integer
            WHERE
                local_pois.id = ' || _poi_id || '
            ON CONFLICT (pois_id, directus_files_id) DO UPDATE SET
                index = EXCLUDED.index
        ';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pois_local_p_trigger(
    _op text,
    _table text,
    _parent_pois_id bigint,
    _children_pois_id bigint,
    _index integer
) RETURNS VOID AS $$
BEGIN
    IF _op = 'DELETE' THEN
        EXECUTE '
            DELETE FROM
                pois_pois
            USING
                "' || substring(_table, 1, 63 - 2) || '_v" AS local_pois,
                pois
            WHERE
                local_pois.id = ' || _parent_pois_id || ' AND

                pois.source_id = local_pois.source_id AND
                (pois.slugs->>''original_id'')::integer = (local_pois.slugs->>''original_id'')::integer AND

                pois_pois.parent_pois_id = pois.id AND
                pois_pois.children_pois_id = ' || _children_pois_id || '
        ';
    ELSE
        EXECUTE '
            INSERT INTO
                pois_pois(parent_pois_id, children_pois_id, index)
            SELECT
                pois.id, ' || _children_pois_id || ', ' || _index || '
            FROM
                "' || substring(_table, 1, 63 - 2) || '_v" AS local_pois
                JOIN pois ON
                    pois.source_id = local_pois.source_id AND
                    (pois.slugs->>''original_id'')::integer = (local_pois.slugs->>''original_id'')::integer
            WHERE
                local_pois.id = ' || _parent_pois_id || '
            ON CONFLICT (parent_pois_id, children_pois_id) DO UPDATE SET
                index = EXCLUDED.index
        ';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pois_local_w_trigger(
    _op text,
    _table text,
    _parent_pois_id bigint,
    _children_pois_id bigint,
    _index integer
) RETURNS VOID AS $$
BEGIN
    IF _op = 'DELETE' THEN
        EXECUTE '
            DELETE FROM
                "local-' || split_part(_table, '-', 2) || '-waypoints"
            WHERE
                id = ' || _children_pois_id || '
        ';
        -- Then the trigger will delete the coresponding pois and the cascade the pois_pois
    ELSE
        EXECUTE '
            INSERT INTO
                pois_pois(parent_pois_id, children_pois_id, index)
            SELECT
                parent_pois.id, children_pois.id, ' || _index || '
            FROM
                "' || substring(_table, 1, 63 - 2) || '_v" AS local_pois
                JOIN pois AS parent_pois ON
                    parent_pois.source_id = local_pois.source_id AND
                    (parent_pois.slugs->>''original_id'')::integer = (local_pois.slugs->>''original_id'')::integer
                JOIN sources AS parent_sources ON
                    parent_sources.id = parent_pois.source_id
                JOIN pois AS children_pois ON
                    (children_pois.slugs->>''original_id'')::integer = ' || _children_pois_id || '
                JOIN sources AS children_sources ON
                    children_sources.id = children_pois.source_id AND
                    children_sources.project_id = parent_sources.project_id
            WHERE
                local_pois.id = ' || _parent_pois_id || '
            ON CONFLICT (parent_pois_id, children_pois_id) DO UPDATE SET
                index = EXCLUDED.index
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

CREATE OR REPLACE FUNCTION pois_local_t_trigger()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM api01.pois_local_trigger(TG_OP, left(TG_TABLE_NAME, -2), coalesce(NEW.pois_id, OLD.pois_id));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pois_local_i_trigger()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM api01.pois_local_i_trigger(TG_OP, left(TG_TABLE_NAME, -2), coalesce(NEW.pois_id, OLD.pois_id), coalesce(NEW.directus_files_id, OLD.directus_files_id), NEW.index);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pois_local_p_trigger()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM api01.pois_local_p_trigger(TG_OP, left(TG_TABLE_NAME, -2), coalesce(NEW.parent_pois_id, OLD.parent_pois_id), coalesce(NEW.children_pois_id, OLD.children_pois_id), NEW.index);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pois_local_w_trigger()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM api01.pois_local_w_trigger(TG_OP, left(TG_TABLE_NAME, -2), coalesce(NEW.parent_pois_id, OLD.parent_pois_id), coalesce(NEW.children_pois_id, OLD.children_pois_id), NEW.index);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS select_pois_local;
CREATE OR REPLACE FUNCTION select_pois_local(
    _table_name text
) RETURNS TABLE(
    table_name text,
    local_id text,
    table_name_t text,
    table_name_i text,
    table_name_p text,
    table_name_w text,
    file_fields text[]
) AS $$
    SELECT
        tables.table_name,
        regexp_replace(tables.table_name, 'local-[a-z0-9_]+-', '') || '_id' AS local_id,
        tables_t.table_name AS table_name_t,
        tables_i.table_name AS table_name_i,
        tables_p.table_name AS table_name_p,
        tables_w.table_name AS table_name_w,
        array_agg(key_column_usage.column_name) AS file_fields
    FROM
        information_schema.tables
        -- Translations
        LEFT JOIN information_schema.tables AS tables_t ON
            tables_t.table_name = substring(tables.table_name, 1, 63 - 2) || '_t'
        -- Images
        LEFT JOIN information_schema.tables AS tables_i ON
            tables_i.table_name = substring(tables.table_name, 1, 63 - 2) || '_i'
        -- Deps pois
        LEFT JOIN information_schema.tables AS tables_p ON
            tables_p.table_name = substring(tables.table_name, 1, 63 - 2) || '_p'
        -- Deps waypoints
        LEFT JOIN information_schema.tables AS tables_w ON
            tables_w.table_name = substring(tables.table_name, 1, 63 - 2) || '_w'
        -- Many files fields
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
        tables.table_name = substring(_table_name, 1, 63)
    GROUP BY
        tables.table_name,
        tables_t.table_name,
        tables_i.table_name,
        tables_p.table_name,
        tables_w.table_name
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;

DROP FUNCTION IF EXISTS create_pois_local_view;
CREATE OR REPLACE FUNCTION create_pois_local_view(
    _project_id integer,
    _source_id integer,
    _table_name text
) RETURNS TABLE(
    name text
) AS $$
DECLARE
    source record;
BEGIN
    FOR source IN SELECT * FROM api01.select_pois_local(_table_name)
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
            ),' END || '
            z AS (SELECT 0)
            SELECT
                ' || _project_id || ' AS project_id,
                t.id,
                geom,
                jsonb_strip_nulls(jsonb_build_object(
                    ''id'', t.id,
                    ''source'', NULL,
                    ''updated_at'', NULL,
                    ''natives'', (
                        WITH
                        kv AS (
                            SELECT
                                CASE WHEN (key LIKE ''route___%'' AND key != ''route___waypoint___type'') OR key LIKE ''addr___%'' THEN
                                    string_to_array(key, ''___'')
                                ELSE
                                    array[replace(key, ''___'', '':'')]
                                END AS key,
                                value
                            FROM
                                jsonb_each(jsonb_strip_nulls(
                                row_to_json(t.*)::jsonb - ''id'' - ''geom'' || ' ||
                                CASE WHEN source.table_name_t IS NOT NULL THEN ' coalesce(trans.jsonb, ''{}''::jsonb) || ' ELSE '' END || '
                                jsonb_build_object(' ||
                                    (SELECT array_to_string(array_agg('''' || f || ''', ''__base_url__/assets/'' || "directus_files_' || f || '".id::text || ''/'' || "directus_files_' || f || '".filename_download'), ', ') FROM unnest(source.file_fields) AS fields(f)) ||
                                ')
                            ))
                        ),
                        m AS (
                            SELECT
                                key[1] AS key,
                                value
                            FROM
                                ((
                                    SELECT * FROM kv WHERE array_length(key, 1) = 1
                                ) UNION ALL (
                                    SELECT
                                        array[key[1]] AS key,
                                        jsonb_object_agg(key[2], value) AS value
                                    FROM
                                        ((
                                            SELECT * FROM kv WHERE array_length(key, 1) = 2
                                        ) UNION ALL (
                                            SELECT
                                                array[key[1], key[2]] as key,
                                                jsonb_object_agg(key[3], value) AS value
                                            FROM
                                                kv
                                            WHERE
                                                array_length(key, 1) = 3
                                            GROUP BY
                                                key[1], key[2]
                                        )) AS t
                                    GROUP BY
                                        key[1]
                                )) AS t
                        ),
                        k AS (SELECT jsonb_object_agg(key, value) AS p FROM m)
                        SELECT p - ''route'' - ''start_date'' - ''end_date'' ||
                            jsonb_strip_nulls(jsonb_build_object(''route'', nullif(jsonb_strip_nulls(jsonb_build_object(''fr-FR'', p->''route'')), ''{}''::jsonb))) ||
                            jsonb_strip_nulls(jsonb_build_object(''start_end_date'', nullif(jsonb_strip_nulls(jsonb_build_object(
                                ''start_date'', p->''start_date'',
                                ''end_date'', p->''end_date''
                            )), ''{}''::jsonb)))
                        FROM k
                    )
                )) AS properties,
                ' || _source_id || ' AS source_id,
                json_build_object(''original_id'', t.id) AS slugs,
                t.id AS slug_id
            FROM
                "' || source.table_name || '" AS t ' ||
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

        IF source.table_name_t IS NOT NULL THEN
            EXECUTE '
                DROP TRIGGER IF EXISTS "' || substring(source.table_name_t, 1, 63 - 2) || '_t" ON "' || source.table_name_t || '";
                CREATE TRIGGER "' || substring(source.table_name_t, 1, 63 - 2) || '_t"
                AFTER INSERT OR UPDATE OR DELETE
                ON "' || source.table_name_t || '"
                FOR EACH ROW
                EXECUTE FUNCTION api01.pois_local_t_trigger();
            ';
        END IF;

        IF source.table_name_i IS NOT NULL THEN
            EXECUTE '
                DROP TRIGGER IF EXISTS "' || substring(source.table_name_i, 1, 63 - 2) || '_t" ON "' || source.table_name_i || '";
                CREATE TRIGGER "' || substring(source.table_name_i, 1, 63 - 2) || '_t"
                AFTER INSERT OR UPDATE OR DELETE
                ON "' || source.table_name_i || '"
                FOR EACH ROW
                EXECUTE FUNCTION api01.pois_local_i_trigger();
            ';
        END IF;

        IF source.table_name_p IS NOT NULL THEN
            EXECUTE '
                DROP TRIGGER IF EXISTS "' || substring(source.table_name_p, 1, 63 - 2) || '_t" ON "' || source.table_name_p || '";
                CREATE TRIGGER "' || substring(source.table_name_p, 1, 63 - 2) || '_t"
                AFTER INSERT OR UPDATE OR DELETE
                ON "' || source.table_name_p || '"
                FOR EACH ROW
                EXECUTE FUNCTION api01.pois_local_p_trigger();
            ';
        END IF;

        IF source.table_name_w IS NOT NULL THEN
            EXECUTE '
                DROP TRIGGER IF EXISTS "' || substring(source.table_name_w, 1, 63 - 2) || '_t" ON "' || source.table_name_w || '";
                CREATE TRIGGER "' || substring(source.table_name_w, 1, 63 - 2) || '_t"
                AFTER INSERT OR UPDATE OR DELETE
                ON "' || source.table_name_w || '"
                FOR EACH ROW
                EXECUTE FUNCTION api01.pois_local_w_trigger();
            ';
        END IF;

        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql PARALLEL SAFE;

DROP FUNCTION IF EXISTS force_update_pois_local;
CREATE OR REPLACE FUNCTION force_update_pois_local(
    _table_name text
) RETURNS TABLE(
    name text
) AS $$
DECLARE
    source record;
BEGIN
    FOR source IN SELECT * FROM api01.select_pois_local(_table_name)
    LOOP
        -- Touch all data to force update of pois
        EXECUTE 'UPDATE "' || source.table_name ||'" SET id = id';

        IF source.table_name_i IS NOT NULL THEN
            EXECUTE 'UPDATE "' || source.table_name_i ||'" SET id = id';
        END IF;

        IF source.table_name_p IS NOT NULL THEN
            EXECUTE 'UPDATE "' || source.table_name_p ||'" SET id = id';
        END IF;

        IF source.table_name_w IS NOT NULL THEN
            EXECUTE 'UPDATE "' || source.table_name_w ||'" SET id = id';
        END IF;

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
                projects.id,
                sources.id,
                'local-' || projects.slug || '-' || sources.slug
            ) AS view ON true
        JOIN LATERAL force_update_pois_local(
                'local-' || projects.slug || '-' || sources.slug ||
                CASE view.name IS NOT NULL WHEN true THEN '' END -- CASE just to force create_pois_local_view first
            ) AS force ON true
    WHERE
        _project_slug IS NULL OR projects.slug = _project_slug
    GROUP BY
        projects.id
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;

DROP FUNCTION IF EXISTS force_update_project_pois_local;
CREATE OR REPLACE FUNCTION force_update_project_pois_local(
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
        JOIN LATERAL api01.force_update_pois_local(
                'local-' || projects.slug || '-' || sources.slug
            ) AS force ON true
    WHERE
        _project_slug IS NULL OR projects.slug = _project_slug
    GROUP BY
        projects.id
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;

SELECT * FROM create_project_pois_local_view(NULL);
