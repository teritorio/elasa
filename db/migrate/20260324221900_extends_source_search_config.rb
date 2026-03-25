# frozen_string_literal: true

class ExtendsSourceSearchConfig < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      UPDATE directus_fields SET options = '{"search_config":{"_and":[{"_or":[{"extends_poi_id":{"properties_tags_name":{"_icontains":"$SEARCH"}}},{"extends_poi_id":{"properties_id":{"_icontains":"$SEARCH"}}}]}]}}' WHERE collection LIKE 'local-%ext\_%' AND field = '_search_config';
    SQL
  end
end
