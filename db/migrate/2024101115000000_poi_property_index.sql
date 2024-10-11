CREATE FUNCTION jsonb_pois_keys_array(jsonb) returns text[] LANGUAGE sql IMMUTABLE AS $$
    SELECT array_agg(jsonb_object_keys) FROM (
        SELECT * FROM jsonb_object_keys($1->'tags')
        UNION ALL
        SELECT * FROM jsonb_object_keys($1->'natives')
    ) AS t
$$;

CREATE INDEX pois_keys_idx ON pois USING GIN(jsonb_pois_keys_array(properties));
