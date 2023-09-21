bash import/import.sh
bash import/import-directus.sh

docker-compose exec -u postgres postgres psql


docker-compose -f docker-compose.yaml -f docker-compose-tools.yaml build tools

docker-compose -f docker-compose.yaml -f docker-compose-tools.yaml run --rm test_api bash


## Import from remote API

docker-compose run --rm api bundle exec rake wp:import[seignanx,tourism]


## Load Sources and POIs

docker-compose run --rm api bundle exec rake sources:load
docker-compose run --rm api bundle exec rake sources:load[dev]


## Test

docker-compose run --rm api bundle exec rake test
