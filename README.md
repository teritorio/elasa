Elasa

## Setup

Build
```
cp .env.template .env
docker compose --profile "*" build
docker compose up -d postgres
cat docker/directus/schema.sql docker/directus/data.sql docker/directus/seq.sql lib/locale-table.sql lib/api-02.sql | docker compose exec -T -u postgres postgres psql -v ON_ERROR_STOP=1
```

If required entrer to Postgres shell with
```
docker compose exec -u postgres postgres psql
```

## Run

Run all the containers using
```
docker compose up -d
```

The Directus Back Office is available at
```
http://localhost:8055
```

Default addmin acces to be changed: admin@example.com / d1r3ctu5

## Update

Update the database schema with
```
docker compose run --rm script bundle exec rails db:migrate
docker compose restart directus
```

## Create new project

```
docker compose run --rm script bundle exec rake project:new -- demo-bordeaux 905682 city city https://city-demo-bordeaux.beta.appcarto.teritorio.xyz
```

## Import from remote API

Import from WP and load from Datasource
```
docker compose run --rm script bundle exec rake wp:import -- https://carte.seignanx.com/content/api.teritorio/geodata/v0.1 seignanx tourism https://datasources.teritorio.xyz/0.1
```

Update datasource only
```
docker compose run --rm script bundle exec rake sources:load -- https://datasources.teritorio.xyz/0.1 [project_slug]
```

Compare original and new API results.
```
docker compose run --rm script bundle exec rake api02:diff -- https://tourism-seignanx.elasa.teritorio.xyz https://tourism-seignanx.elasa-dev.teritorio.xyz seignanx tourism
```

## Load dump from other instance

Dump
```
docker compose exec -u postgres postgres pg_dump --exclude-schema=topology | gzip > pg_dump-2025-11-17.gz
```

Load
```
docker compose up -d postgres
zcat pg_dump-2025-11-17.gz | docker compose exec -T -u postgres postgres psql -v ON_ERROR_STOP=1

# Optional, update database to current version
docker compose run --rm script bundle exec rails db:migrate
cat lib/locale-table-01.sql lib/api-02.sql | docker compose exec -T -u postgres postgres psql -v ON_ERROR_STOP=1

docker compose up -d
```

## Update Postgres version

First, adjust version in docker compose file.
```
# Init the new database
docker compose up postgres # And stop it once initialized with ctrl-c
# Migrate
docker compose --profile=* run --rm postgres-update
```

## Test

```
docker compose exec -u postgres postgres psql -c "CREATE DATABASE test"
```

```
docker compose run --rm script bundle exec rake test
```

```
docker compose run --rm script bundle exec rake api02:validate -- http://192.168.0.14:12000/api/0.1/seignanx/tourism
docker compose run --rm script bundle exec rake api02:validate_poi -- [project_slug]
```
