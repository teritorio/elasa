# frozen_string_literal: true

class ArticleToTheme < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      ALTER TABLE projects_articles RENAME TO themes_articles;

      ALTER TABLE themes_articles ADD COLUMN themes_id INTEGER REFERENCES themes(id);
      UPDATE themes_articles
      SET themes_id = themes.id
      FROM themes
      WHERE themes.project_id = themes_articles.projects_id
      ;
      ALTER TABLE themes_articles ALTER COLUMN themes_id SET NOT NULL;

      ALTER TABLE themes_articles DROP COLUMN projects_id;

      ALTER TABLE themes_articles RENAME CONSTRAINT projects_articles_pkey TO themes_articles_pkey;
      ALTER TABLE themes_articles RENAME CONSTRAINT projects_articles_articles_id_foreign TO themes_articles_articles_id_foreign;
      ALTER SEQUENCE projects_articles_id_seq RENAME TO themes_articles_id_seq;

      UPDATE directus_collections SET collection = 'themes_articles' WHERE collection = 'projects_articles';
      UPDATE directus_fields SET collection = 'themes_articles' WHERE collection = 'projects_articles';
      UPDATE directus_fields SET field = 'themes_id' WHERE collection = 'themes_articles' AND field = 'projects_id';
      UPDATE directus_fields SET
        collection = 'themes',
        options = '{"filter":{"_and":[{"project_id":{"_eq":"{{project_id}}"}}]}}'::json,
        sort = 10
      WHERE collection = 'projects' AND field = 'articles'
      ;

      UPDATE directus_permissions SET collection = 'themes_articles' WHERE collection = 'projects_articles';
      UPDATE directus_permissions SET permissions = '{"_and":[{"themes_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}'::jsonb WHERE collection = 'themes_articles' AND action IN ('read', 'update', 'delete');
      UPDATE directus_permissions SET fields = replace(fields, ',articles', '') WHERE collection = 'projects' AND action = 'update';
      UPDATE directus_permissions SET fields = fields || ',articles' WHERE collection = 'themes' AND action = 'update';

      UPDATE directus_relations SET many_collection = 'themes_articles', junction_field = 'themes_id' WHERE many_collection = 'projects_articles' AND many_field = 'articles_id';
      UPDATE directus_relations SET many_collection = 'themes_articles', many_field = 'themes_id', one_collection = 'themes' WHERE many_collection = 'projects_articles' AND many_field = 'projects_id';
      UPDATE directus_relations SET many_field = 'themes_id', one_collection = 'themes' WHERE many_collection = 'articles';
    SQL
  end
end
