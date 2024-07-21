Elasa

## Setup

Build
```
cp .env.template .env
docker compose build
docker compose up -d postgres
cat docker/directus/elasa-schema.sql | docker compose exec -T -u postgres postgres psql -v ON_ERROR_STOP=1
cat docker/directus/directus-schema.sql | docker compose exec -T -u postgres postgres psql -v ON_ERROR_STOP=1
cat docker/directus/directus-data.sql | docker compose exec -T -u postgres postgres psql -v ON_ERROR_STOP=1
cat lib/api-01.sql | docker compose exec -T -u postgres postgres psql -v ON_ERROR_STOP=1
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

## Create new project

```
docker compose run --rm api bundle exec rake project:new -- demo-bordeaux 905682 city https://city-demo-bordeaux.beta.appcarto.teritorio.xyz
```

## Import from remote API

Import from WP and load from Datasource
```
docker compose run --rm api bundle exec rake wp:import -- https://carte.seignanx.com/content/api.teritorio/geodata/v0.1 seignanx tourism https://datasources.teritorio.xyz/0.1
```

Update datasource only
```
docker compose run --rm api bundle exec rake sources:load -- https://datasources-dev.teritorio.xyz/0.1 seignanx
```

Compare original and new API results.
```
docker compose run --rm api bundle exec rake api:diff -- https://carte.seignanx.com/content/api.teritorio/geodata/v0.1/seignanx/tourism http://192.168.0.14:12000/api/0.1/seignanx/tourism
```

## Test

```
docker compose exec -u postgres postgres psql -c "CREATE DATABASE test"
```

```
docker compose run --rm api bundle exec rake test
```

```
docker compose run --rm api bundle exec rake api:validate -- http://192.168.0.14:12000/api/0.1/seignanx/tourism
```
