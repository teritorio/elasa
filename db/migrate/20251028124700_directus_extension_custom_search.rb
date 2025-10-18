# frozen_string_literal: true

class DirectusExtensionCustomSearch < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL.squish
      INSERT INTO directus_extensions (enabled, id, folder, source, bundle) VALUES
      (true, 'db7ec639-4f69-4bd2-9ef1-e169ee869423', 'directus-extension-custom-search', 'local', NULL),
      (true, '49b617db-7261-41a9-a8d7-6a038482a869', 'intercept-search', 'local', 'db7ec639-4f69-4bd2-9ef1-e169ee869423'),
      (true, '63c95148-cb66-40ae-93ca-27c95e22f327', 'search-configuration', 'local', 'db7ec639-4f69-4bd2-9ef1-e169ee869423')
      ;

      INSERT INTO public.directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message) VALUES
      (603, 'projects', '_search_config', 'alias,no-data', 'search-configuration', '{"search_config":{"_and":[{"_or":[{"slug":{"_icontains":"$SEARCH"}},{"project_translations":{"name":{"_icontains":"$SEARCH"}}}]}]}}', NULL, NULL, false, false, 18, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
      (604, 'themes', '_search_config', 'alias,no-data', 'search-configuration', '{"search_config":{"_and":[{"_or":[{"slug":{"_icontains":"$SEARCH"}},{"theme_translations":{"name":{"_icontains":"$SEARCH"}}},{"theme_translations":{"site_url":{"_icontains":"$SEARCH"}}},{"theme_translations":{"main_url":{"_icontains":"$SEARCH"}}}]}]}}', NULL, NULL, false, false, 12, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
      (605, 'menu_items', '_search_config', 'alias,no-data', 'search-configuration', '{"search_config":{"_and":[{"_or":[{"menu_items_translations":{"name":{"_icontains":"$SEARCH"}}},{"menu_items_translations":{"name_singular":{"_icontains":"$SEARCH"}}},{"menu_items_translations":{"slug":{"_icontains":"$SEARCH"}}},{"sources":{"sources_id":{"slug":{"_icontains":"$SEARCH"}}}},{"href":{"_icontains":"$SEARCH"}}]}]}}', NULL, NULL, false, false, 13, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
      (606, 'filters', '_search_config', 'alias,no-data', 'search-configuration', '{"search_config":{"_and":[{"_or":[{"filters_translations":{"name":{"_icontains":"$SEARCH"}}},{"checkboxes_list_property":{"fields_translations":{"name":{"_icontains":"$SEARCH"}}}},{"checkboxes_list_property":{"fields_translations":{"name":{"_icontains":"$SEARCH"}}}},{"property_begin":{"fields_translations":{"name":{"_icontains":"$SEARCH"}}}},{"property_end":{"fields_translations":{"name":{"_icontains":"$SEARCH"}}}},{"number_range_property":{"fields_translations":{"name":{"_icontains":"$SEARCH"}}}}]}]}}', NULL, NULL, false, false, 10, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
      (607, 'fields', '_search_config', 'alias,no-data', 'search-configuration', '{"search_config":{"_and":[{"_or":[{"fields_translations":{"name":{"_icontains":"$SEARCH"}}},{"field":{"_icontains":"$SEARCH"}},{"group":{"_icontains":"$SEARCH"}}]}]}}', NULL, NULL, false, false, 9, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
      (608, 'articles', '_search_config', 'alias,no-data', 'search-configuration', '{"search_config":{"_and":[{"_or":[{"article_translations":{"title":{"_icontains":"$SEARCH"}}},{"article_translations":{"slug":{"_icontains":"$SEARCH"}}}]}]}}', NULL, NULL, false, false, 4, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
      (609, 'sources', '_search_config', 'alias,no-data', 'search-configuration', '{"search_config":{"_and":[{"_or":[{"slug":{"_icontains":"$SEARCH"}},{"sources_translations":{"name":{"_icontains":"$SEARCH"}}}]}]}}', NULL, NULL, false, false, 8, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL)
      ;
    SQL
  end
end
