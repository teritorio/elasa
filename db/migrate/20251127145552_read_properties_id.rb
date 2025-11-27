# frozen_string_literal: true

class ReadPropertiesTagsName < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      UPDATE directus_permissions SET fields = 'id,source_id,geom,properties,slugs,override,image,website_details,properties_tags_name,properties_id' WHERE id = 83;
    SQL
  end
end
