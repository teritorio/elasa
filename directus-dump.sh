source .env
docker-compose exec postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" -n public --schema-only -t directus_* > directus-schema.sql
docker-compose exec postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" -n public --data-only -t directus_* -T directus_sessions -T directus_activity -T directus_revisions -T directus_migrations  > directus-data.sql
