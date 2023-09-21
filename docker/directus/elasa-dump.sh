source ../../.env
docker-compose exec postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" --clean --if-exists -n public --schema-only -T directus_* --clean > elasa-schema.sql
docker-compose exec postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" -n public --data-only -T directus_* -T pois > elasa-data-tmp.sql
perl pg_dump_sort.perl elasa-data-tmp.sql > elasa-data.sql && rm elasa-data-tmp.sql
