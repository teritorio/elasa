bash import/import.sh
bash import/import-directus.sh

docker-compose exec -u postgres postgres psql


docker-compose -f docker-compose.yaml -f docker-compose-tools.yaml build tools

docker-compose -f docker-compose.yaml -f docker-compose-tools.yaml run --rm test_api bash


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
