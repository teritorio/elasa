#!/usr/bin/bash

set -e

mysql -pryevXAkJ#A99 -ucdt40 -hlocalhost cdt40 -N -B < export.sql


rm *.tsv
mysql -pryevXAkJ#A99 -ucdt40 -hlocalhost cdt40 -N -B -e "SELECT * FROM tmp_export_projects" > projects.tsv
mysql -pryevXAkJ#A99 -ucdt40 -hlocalhost cdt40 -N -B -e "SELECT * FROM tmp_export_themes" > themes.tsv
mysql -pryevXAkJ#A99 -ucdt40 -hlocalhost cdt40 -N -B -e "SELECT * FROM tmp_export_sources_osm" > sources_osm.tsv
mysql -pryevXAkJ#A99 -ucdt40 -hlocalhost cdt40 -N -B -e "SELECT * FROM tmp_export_sources_tourinsoft" > sources_tourinsoft.tsv
mysql -pryevXAkJ#A99 -ucdt40 -hlocalhost cdt40 -N -B -e "SELECT * FROM tmp_export_sources_cms" > sources_cms.tsv
mysql -pryevXAkJ#A99 -ucdt40 -hlocalhost cdt40 -N -B -e "SELECT * FROM tmp_export_property_labels" > property_labels.tsv
mysql -pryevXAkJ#A99 -ucdt40 -hlocalhost cdt40 -N -B -e "SELECT * FROM tmp_export_categories" > categories.tsv
mysql -pryevXAkJ#A99 -ucdt40 -hlocalhost cdt40 -N -B -e "SELECT * FROM tmp_export_category_filters" > category_filters.tsv
mysql -pryevXAkJ#A99 -ucdt40 -hlocalhost cdt40 -N -B -e "SELECT * FROM tmp_export_categorie_sources_osm" > categorie_sources_osm.tsv
mysql -pryevXAkJ#A99 -ucdt40 -hlocalhost cdt40 -N -B -e "SELECT * FROM tmp_export_categorie_sources_tourinsoft" > categorie_sources_tourinsoft.tsv
mysql -pryevXAkJ#A99 -ucdt40 -hlocalhost cdt40 -N -B -e "SELECT * FROM tmp_export_categorie_sources_cms" > categorie_sources_cms.tsv
mysql -pryevXAkJ#A99 -ucdt40 -hlocalhost cdt40 -N -B -e "SELECT * FROM tmp_export_menu_groups" > menu_groups.tsv
mysql -pryevXAkJ#A99 -ucdt40 -hlocalhost cdt40 -N -B -e "SELECT * FROM tmp_export_menu_items" > menu_items.tsv
