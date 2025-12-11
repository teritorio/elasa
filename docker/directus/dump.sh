source ../../.env
docker compose exec postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" -n public --schema-only -T local-* -T pois_local | grep -v "CREATE SCHEMA public" > schema.sql
docker compose exec postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" -n public --data-only -t directus_* -T directus_sessions -T directus_activity -T directus_revisions -T directus_presets -T directus_folders -T directus_files -T directus_policies -T directus_roles -T directus_users -T directus_access > data-tmp.sql
perl pg_dump_sort.perl data-tmp.sql | \
    grep -v '^local-' | \
    grep -v "^[0-9]\+\slocal-" \
    > data.sql && rm data-tmp.sql
sed -i "s/public.directus_activity_id_seq', [0-9]\+/public.directus_activity_id_seq', 1/" data.sql
sed -i "s/public.directus_revisions_id_seq', [0-9]\+/public.directus_revisions_id_seq', 1/" data.sql
sed -i "s/public.directus_presets_id_seq', [0-9]\+/public.directus_presets_id_seq', 1/" data.sql
