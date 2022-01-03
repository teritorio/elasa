#!/usr/bin/bash

set -e

cat directus.sql | docker-compose exec database psql -U directus
