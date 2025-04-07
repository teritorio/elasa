BEGIN;
DO $$
DECLARE
    source record;
BEGIN
    FOR source IN
        SELECT table_name FROM information_schema.columns WHERE table_name LIKE 'local-%' AND table_name NOT LIKE 'local-%_v'AND column_name = 'project_id'
    LOOP
        EXECUTE 'ALTER TABLE "' || source.table_name || '" DROP COLUMN project_id CASCADE';
    END LOOP;
END;
$$ LANGUAGE plpgsql;
COMMIT;

UPDATE directus_permissions SET permissions = '{}'::jsonb WHERE collection LIKE 'local-%';
