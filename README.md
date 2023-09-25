bash import/import.sh
bash import/import-directus.sh

docker-compose exec -u postgres postgres psql


docker-compose -f docker-compose.yaml -f docker-compose-tools.yaml build tools

docker-compose -f docker-compose.yaml -f docker-compose-tools.yaml run --rm test_api bash


## Import from remote API

docker-compose run --rm api bundle exec rake wp:import -- https://carte.seignanx.com/content/api.teritorio/geodata/v0.1 seignanx tourism

docker-compose run --rm api bundle exec rake sources:load -- https://datasources-dev.teritorio.xyz/0.1 seignanx


## Load Sources and POIs

docker-compose run --rm api bundle exec rake sources:load
docker-compose run --rm api bundle exec rake sources:load[dev]


## Test

docker-compose run --rm api bundle exec rake test

docker-compose run --rm api bundle exec rake api:validate -- http://172.29.0.1:12000/api/0.1/seignanx/tourism
