#!/usr/bin/bash

set -e

source .env

PSQL="docker-compose exec postgres psql -v ON_ERROR_STOP=1 -U $POSTGRES_DB"

cat schema.sql | $PSQL


for table in \
    projects \
    themes \
    sources_osm \
    sources_tourinsoft \
    sources_cms \
    property_labels \
    categories \
    category_filters \
    categorie_sources_osm \
    categorie_sources_tourinsoft \
    categorie_sources_cms \
    menu_groups \
    menu_items \
; do
    echo ${table}
    cat import/${table}.tsv | $PSQL -c "COPY ${table} FROM STDIN DELIMITER E'\t' NULL AS 'NULL'"
done
