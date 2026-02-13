CREATE SCHEMA IF NOT EXISTS api02;
SET search_path TO api02,public;


DROP FUNCTION IF EXISTS capitalize;
CREATE FUNCTION capitalize(str text) RETURNS text AS $$
    SELECT
        upper(substring(str from 1 for 1)) ||
        substring(str from 2 for length(str))
    ;
$$ LANGUAGE sql STRICT IMMUTABLE PARALLEL SAFE;


CREATE TABLE IF NOT EXISTS pois_property_values (
    project_id integer REFERENCES projects(id) ON DELETE CASCADE,
    source_id integer REFERENCES sources(id) ON DELETE CASCADE,
    field_id integer REFERENCES fields(id) ON DELETE CASCADE,
    property_values jsonb,
    CONSTRAINT pois_property_values_pkey PRIMARY KEY (project_id, source_id, field_id)
);


DROP FUNCTION IF EXISTS pois_property_values_by_menu_item;
CREATE FUNCTION pois_property_values_by_menu_item(
    _project_id integer,
    _menu_items_id integer,
    _field_id integer
) RETURNS TABLE (
    project_id integer,
    field_id integer,
    property_values jsonb
) AS $$
    WITH t AS (
    SELECT DISTINCT ON (project_id, field_id, property_value->>'value')
        project_id,
        field_id,
        property_value
    FROM
        menu_items_sources
        JOIN pois_property_values ON
            pois_property_values.project_id = _project_id AND
            pois_property_values.source_id = menu_items_sources.sources_id AND
            pois_property_values.field_id = _field_id
        JOIN LATERAL jsonb_array_elements(property_values) AS t(property_value) ON true
    WHERE
        (_menu_items_id IS NULL OR menu_items_sources.menu_items_id = _menu_items_id)
    ORDER BY
        project_id,
        field_id,
        property_value->>'value'
    )
    SELECT
        project_id,
        field_id,
        jsonb_agg(property_value) AS property_values
    FROM
        t
    GROUP BY
        project_id,
        field_id
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS pois_property_extract_values;
CREATE OR REPLACE FUNCTION pois_property_extract_values(
    _project_id integer,
    _source_id integer,
    _property text
)  RETURNS TABLE (
    project_id integer,
    source_id integer,
    property text,
    property_values jsonb
) AS $$
    WITH
    pois AS (
        SELECT
            sources.project_id,
            sources.id AS source_id,
            pois.properties
        FROM
            sources
            JOIN pois ON
                pois.source_id = sources.id
        WHERE
            sources.project_id = _project_id AND
            (_source_id IS NULL OR sources.id = _source_id) AND
            jsonb_pois_keys_array(properties) @> ARRAY[split_part(_property, ':', 1)]
    ),
    properties_values AS (
        SELECT
            project_id,
            source_id,
            coalesce(
                jsonb_path_query_first((pois.properties->'tags')::jsonb, ('$.' || CASE
                    WHEN _property LIKE 'route:%' AND  _property != 'route:point:type'  THEN replace(replace(_property, 'route:', 'route."fr-FR".'), ':', '.')
                    WHEN _property LIKE 'addr:%' THEN replace(_property, ':', '.')
                    ELSE '"' || _property || '"' END
                )::jsonpath),
                jsonb_path_query_first((pois.properties->'natives')::jsonb, ('$.' || '"' || _property || '"')::jsonpath)
            ) AS property
        FROM
            pois
    ),
    values AS (
        SELECT
            project_id,
            source_id,
            jsonb_array_elements(
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
        SELECT DISTINCT ON (project_id, source_id, value)
            project_id,
            source_id,
            value
        FROM
            values
        ORDER BY
            project_id,
            source_id,
            value
    )
    SELECT
        values_uniq.project_id,
        source_id,
        _property AS property,
        jsonb_strip_nulls(
            jsonb_agg(
                jsonb_build_object(
                    'value', value,
                    'name', nullif(jsonb_strip_nulls(jsonb_build_object(
                        'fr', api02.capitalize(fields.values_translations->(value->>0)->'@default:full'->>'fr-FR')
                    )), '{}'::jsonb)
                )
                ORDER BY value
            )
        ) AS property_values
    FROM
        values_uniq
        LEFT JOIN fields ON
            fields.project_id = values_uniq.project_id AND
            fields.field = _property
    GROUP BY
        values_uniq.project_id,
        source_id
    ;
$$ LANGUAGE sql STABLE PARALLEL SAFE;


DROP FUNCTION IF EXISTS pois_property_values_update;
CREATE OR REPLACE FUNCTION pois_property_values_update(
    _project_slug text,
    _source_slug text,
    _field_id_old integer,
    _field_id_new integer
) RETURNS VOID AS $$
BEGIN
    DELETE FROM
      api02.pois_property_values
    USING
        projects
        JOIN sources ON
            sources.project_id = projects.id
        JOIN filters ON
            filters.project_id = projects.id
        JOIN fields ON
            (
                (_field_id_old IS NULL AND _field_id_new IS NULL) OR
                fields.id IN (_field_id_old, _field_id_new)
            ) AND
            fields.id = property
    WHERE
        (_project_slug IS NULL OR projects.slug = _project_slug) AND
        (_source_slug IS NULL OR sources.slug = _source_slug) AND
        pois_property_values.project_id = projects.id AND
        pois_property_values.source_id = sources.id
    ;

    INSERT INTO api02.pois_property_values
    SELECT DISTINCT ON (t.project_id, t.source_id, fields.id)
        t.project_id,
        t.source_id,
        fields.id,
        t.property_values
    FROM
        projects
        JOIN sources ON
            sources.project_id = projects.id
        JOIN filters ON
            filters.project_id = projects.id
        JOIN fields ON
            (
                (_field_id_old IS NULL AND _field_id_new IS NULL) OR
                fields.id = _field_id_new
            ) AND
            fields.id = property
        JOIN LATERAL api02.pois_property_extract_values(projects.id, sources.id, fields.field) AS t ON true
    WHERE
        (_project_slug IS NULL OR projects.slug = _project_slug) AND
        (_source_slug IS NULL OR sources.slug = _source_slug)
    ORDER BY
        t.project_id,
        t.source_id,
        fields.id
    ;
END;
$$ LANGUAGE plpgsql;


-- triggers to add new filters
DROP FUNCTION IF EXISTS filters_pois_property_values;
CREATE OR REPLACE FUNCTION filters_pois_property_values(
    field_id_old integer,
    field_id_new integer
) RETURNS VOID AS $$
DECLARE
    _project_slug text;
BEGIN
    _project_slug := (SELECT projects.slug FROM projects JOIN fields ON fields.project_id = projects.id WHERE fields.id = coalesce(field_id_old, field_id_new));

    IF field_id_old = field_id_new THEN
        PERFORM api02.pois_property_values_update(_project_slug, NULL, field_id_old, field_id_new);
    ELSE
        IF field_id_old IS NOT NULL THEN
            PERFORM api02.pois_property_values_update(_project_slug, NULL, field_id_old, field_id_new);
        END IF;
        IF field_id_new IS NOT NULL THEN
            PERFORM api02.pois_property_values_update(_project_slug, NULL, field_id_old, field_id_new);
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION filters_pois_property_values_trigger_from_filters()
RETURNS TRIGGER AS $$
DECLARE
    field_id_old integer;
    field_id_new integer;
BEGIN
    field_id_old := OLD.property;
    field_id_new := NEW.property;
    PERFORM api02.filters_pois_property_values(field_id_old, field_id_new);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION filters_pois_property_values_trigger_from_menu_items_filters()
RETURNS TRIGGER AS $$
DECLARE
    field_id_old integer;
    field_id_new integer;
BEGIN
    field_id_old := (SELECT property FROM filters WHERE filters.id = OLD.filters_id);
    field_id_new := (SELECT property FROM filters WHERE filters.id = NEW.filters_id);
    PERFORM api02.filters_pois_property_values(field_id_old, field_id_new);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS menu_items_filters_pois_property_values_trigger ON menu_items_filters;
CREATE TRIGGER menu_items_filters_pois_property_values_trigger
AFTER INSERT OR UPDATE OR DELETE
ON menu_items_filters
FOR EACH ROW
EXECUTE FUNCTION api02.filters_pois_property_values_trigger_from_menu_items_filters();

DROP TRIGGER IF EXISTS filters_pois_property_values_trigger ON filters;
CREATE TRIGGER filters_pois_property_values_trigger
AFTER INSERT OR UPDATE OF property OR DELETE
ON filters
FOR EACH ROW
EXECUTE FUNCTION api02.filters_pois_property_values_trigger_from_filters();
