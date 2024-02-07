source ../../.env
docker-compose exec postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" -n public --schema-only -T directus_* -T local-* | grep -v "CREATE SCHEMA public" > elasa-schema.sql
docker-compose exec postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" -n public --data-only --column-inserts -T directus_* -T local_* -T pois > elasa-data-tmp.sql
perl pg_dump_sort.perl elasa-data-tmp.sql > elasa-data.sql && rm elasa-data-tmp.sql
