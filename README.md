Elasa

## Setup

Build
```
cp .env.template .env
docker-compose build
docker-compose up -d postgres
cat docker/directus/elasa-schema.sql | docker-compose exec -T -u postgres postgres psql -v ON_ERROR_STOP=1
cat docker/directus/directus-schema.sql | docker-compose exec -T -u postgres postgres psql -v ON_ERROR_STOP=1
cat docker/directus/directus-data.sql | docker-compose exec -T -u postgres postgres psql -v ON_ERROR_STOP=1
cat lib/api.sql | docker-compose exec -T -u postgres postgres psql
```

## Import from remote API

Import from WP and load from Datasource
```
docker-compose run --rm api bundle exec rake wp:import -- https://carte.seignanx.com/content/api.teritorio/geodata/v0.1 seignanx tourism https://datasources-dev.teritorio.xyz/0.1
```

Update datasource only
```
docker-compose run --rm api bundle exec rake sources:load -- https://datasources-dev.teritorio.xyz/0.1 seignanx
```

Compare original and new API results.
```
docker-compose run --rm api bundle exec rake api:diff -- https://dev.appcarto.teritorio.xyz/content/api.teritorio/geodata/v0.1/dev/tourism http://192.168.231.162:12000/api/0.1/dev/tourism
```

## Test

docker-compose run --rm api bundle exec rake test

docker-compose run --rm api bundle exec rake api:validate -- http://172.29.0.1:12000/api/0.1/seignanx/tourism
