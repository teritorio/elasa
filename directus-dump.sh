source .env
docker-compose exec postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" -n public --schema-only -t directus_* --clean > directus-schema.sql
docker-compose exec postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" -n public --data-only -t directus_* -T directus_sessions -T directus_activity -T directus_revisions -T directus_migrations -T directus_presets > directus-data-tmp.sql
perl tools/pg_dump_sort.perl directus-data-tmp.sql > directus-data.sql && rm directus-data-tmp.sql
sed -i "s/public.directus_activity_id_seq', [0-9]\+/public.directus_activity_id_seq', 1/" directus-data.sql
sed -i "s/public.directus_revisions_id_seq', [0-9]\+/public.directus_revisions_id_seq', 1/" directus-data.sql
sed -i "s/public.directus_presets_id_seq', [0-9]\+/public.directus_presets_id_seq', 1/" directus-data.sql
