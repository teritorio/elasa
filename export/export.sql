DELIMITER //
CREATE OR REPLACE FUNCTION wp_property(encoded text, property text)
   RETURNS text
   DETERMINISTIC
   BEGIN
      RETURN substring_index(substring_index(substring(encoded, locate(property, encoded)), '"', 3), '"', -1);
END//
DELIMITER ;


-- Modified from
-- https://stackoverflow.com/questions/5409831/mysql-stored-function-to-create-a-slug
DROP FUNCTION IF EXISTS `slugify`;
DELIMITER //
CREATE OR REPLACE FUNCTION `slugify`(dirty_string text)
RETURNS text
DETERMINISTIC
BEGIN
    DECLARE x, y , z Int;
    Declare temp_string, new_string text;
    Declare is_allowed Bool;
    Declare c, check_char VarChar(1);

    set temp_string = LOWER(dirty_string);

    Set temp_string = replace(temp_string, '&', ' and ');

    Select temp_string Regexp('[^a-z0-9\-]+') into x;
    If x = 1 then
        set z = 1;
        While z <= Char_length(temp_string) Do
            Set c = Substring(temp_string, z, 1);
            Set is_allowed = False;
            If !((ascii(c) = 45) or (ascii(c) >= 48 and ascii(c) <= 57) or (ascii(c) >= 97 and ascii(c) <= 122)) Then
                Set temp_string = Replace(temp_string, c, '-');
            End If;
            set z = z + 1;
        End While;
    End If;

    Select temp_string Regexp("^-|-$|'") into x;
    If x = 1 Then
        Set temp_string = Replace(temp_string, "'", '');
        Set z = Char_length(temp_string);
        Set y = Char_length(temp_string);
        Dash_check: While z > 1 Do
            If Strcmp(SubString(temp_string, -1, 1), '-') = 0 Then
                Set temp_string = Substring(temp_string,1, y-1);
                Set y = y - 1;
            Else
                Leave Dash_check;
            End If;
            Set z = z - 1;
        End While;
    End If;

    Repeat
        Select temp_string Regexp("--") into x;
        If x = 1 Then
            Set temp_string = Replace(temp_string, "--", "-");
        End If;
    Until x <> 1 End Repeat;

    If LOCATE('-', temp_string) = 1 Then
        Set temp_string = SUBSTRING(temp_string, 2);
    End If;

    Return temp_string;
END//
DELIMITER ;



-- Project
DROP VIEW IF EXISTS tmp_export_projects;
CREATE VIEW tmp_export_projects AS
SELECT
    1 AS id,
    (SELECT Value FROM sp_metadata WHERE `Key` = 'infos') AS slug,
    (SELECT Value FROM sp_metadata WHERE `Key` = 'nomlieu') AS name,
        -- (SELECT wp_property(option_value, 'citymap_footer_text_1') FROM wp_options WHERE option_name = 'theme_mods_citymap')
        -- (SELECT wp_property(option_value, 'citymap_footer_text_2') FROM wp_options WHERE option_name = 'theme_mods_citymap')
    NULL AS attributions, -- TODO
    'https://unpkg.com/@teritorio/font-teritorio-tourism@1.8.0/teritorio-tourism/teritorio-tourism.css' AS icon_font_css_url,
    concat('POLYGON((', (SELECT Value FROM sp_metadata WHERE `Key` = 'bbox_poly'), '))') AS polygon
;

-- Theme
DROP VIEW IF EXISTS tmp_export_themes;
CREATE VIEW tmp_export_themes AS
SELECT
    1 AS id,
    1 AS project_id,
    'tourism' AS slug,
    (SELECT json_object('fr', Value) FROM sp_metadata WHERE `Key` = 'site1_titre') AS name,
    NULL AS description, -- get_bloginfo('description', 'display'))
    (SELECT Value FROM sp_metadata WHERE `Key` = 'carte_url') AS site_url,
    (SELECT Value FROM sp_metadata WHERE `Key` = 'site1_main_url') AS main_url,
    (SELECT wp_property(option_value, 'themeslug_logo') FROM wp_options WHERE option_name = 'theme_mods_citymap') AS logo_url,
    (SELECT Value FROM sp_metadata WHERE `Key` = 'site1_favicon') AS favicon_url
;


-- Sources

DROP VIEW IF EXISTS tmp_export_sources_osm;
CREATE VIEW tmp_export_sources_osm AS
SELECT
    id,
    slug,
    nullif(json_object('fr', NULLIF(label, '')), '{"fr": null}') AS label, -- Default name for POI of this source.
    nullif(json_object('fr', NULLIF(NULLIF(label_infobulle, label), '')), '{"fr": null}') AS label_popup,
    nullif(json_object('fr', NULLIF(NULLIF(label_fiche, label), '')), '{"fr": null}') AS label_details,

    -- Popup
    CASE WHEN HasPopup='yes' AND (PopupListField != '' OR PopupAdress = 'yes') THEN -- Enable to display popup on POI
        replace(concat(
            '["', replace(PopupListField, ';', '","'),
            CASE WHEN PopupAdress = 'yes' THEN '","addr:*' ELSE '' END, '"]'
        ), '"",', '')
    END AS popup_properties, -- List of tags to be displyed

    -- Details
    hasfiche = 'yes' AS details_enable,

    -- OSM - Source de données (Source)
    OsmQuery AS overpass_query, -- Overpass API part of the query filter
    map_contrib AS map_contrib_theme_url, -- URL to a map contrib theme
    CASE WHEN specific_tags IS NOT NULL AND specific_tags != '' THEN
        concat('["', replace(specific_tags, ';', '","'), '"]')
    END AS extra_tags
FROM
    sp_menuniveau3
WHERE
    poi_type = 'osm'
;


DROP VIEW IF EXISTS tmp_export_sources_tourinsoft;
CREATE VIEW tmp_export_sources_tourinsoft AS
SELECT
    id,
    slug,
    nullif(json_object('fr', NULLIF(label, '')), '{"fr": null}') AS label, -- Default name for POI of this source.
    nullif(json_object('fr', NULLIF(NULLIF(label_infobulle, label), '')), '{"fr": null}') AS label_popup,
    nullif(json_object('fr', NULLIF(NULLIF(label_fiche, label), '')), '{"fr": null}') AS label_details,

    -- Popup
    CASE WHEN HasPopup='yes' AND (PopupListField != '' OR PopupAdress = 'yes') THEN -- Enable to display popup on POI
        replace(concat(
            '["', replace(PopupListField, ';', '","'),
            CASE WHEN PopupAdress = 'yes' THEN '","addr:*' ELSE '' END, '"]'
        ), '"",', '')
    END AS popup_properties, -- List of tags to be displyed

    -- Details
    hasfiche = 'yes' AS details_enable,

    -- TIS - Source de données (Source)
    concat(
        (SELECT Value FROM sp_metadata WHERE `Key` = 'tis_url'),
        (SELECT Value FROM sp_metadata WHERE `Key` = 'tis_account_name'),
        '/',
        trim(tis_syndicationId),
        '/Objects?$format=json',
        CASE WHEN (SELECT nullif(Value, '') FROM sp_metadata WHERE `Key` = 'tis_query_filter') IS NOT NULL
            THEN concat('&$filter=', (SELECT Value FROM sp_metadata WHERE `Key` = 'tis_query_filter'))
            ELSE ''
        END
    ) AS url,
    (SELECT Value FROM sp_metadata WHERE `Key` = 'tis_photos_base_url') AS photos_base_url
FROM
    sp_menuniveau3
WHERE
    poi_type = 'tis'
;


DROP VIEW IF EXISTS tmp_export_sources_cms;
CREATE VIEW tmp_export_sources_cms AS
SELECT
    id,
    slug,
    nullif(json_object('fr', NULLIF(label, '')), '{"fr": null}') AS label, -- Default name for POI of this source.
    nullif(json_object('fr', NULLIF(NULLIF(label_infobulle, label), '')), '{"fr": null}') AS label_popup,
    nullif(json_object('fr', NULLIF(NULLIF(label_fiche, label), '')), '{"fr": null}') AS label_details,

    -- Popup
    CASE WHEN HasPopup='yes' AND (PopupListField != '' OR PopupAdress = 'yes') THEN -- Enable to display popup on POI
        replace(concat(
            '["', replace(PopupListField, ';', '","'),
            CASE WHEN PopupAdress = 'yes' THEN '","addr:*' ELSE '' END, '"]'
        ), '"",', '')
    END AS popup_properties, -- List of tags to be displyed

    -- Details
    hasfiche = 'yes' AS details_enable,

    -- WP / Zone Projet - Source de données (Source)
    CASE WHEN ListeTags IS NOT NULL AND ListeTags != '' THEN
        concat('["', replace(ListeTags, ';', '","'), '"]')
    END AS extra_tags -- ??????????????????
FROM
    sp_menuniveau3
WHERE
    poi_type = 'wp'
;


-- SELECT
--     id,
-- FROM
--     sp_menuniveau3
-- WHERE
--     poi_type = 'zone'
-- ;


-- ???
--module_slug
--acf_groups
--taxonomy




DROP VIEW IF EXISTS tmp_wp_posts_wp_postmeta;
CREATE VIEW tmp_wp_posts_wp_postmeta AS
SELECT
    id,
    menu_order,

    -- Menu

    -- type ?
    -- ???
    -- JSON_Unquote(JSON_Extract(tags, '$._menu_item_classes') AS classes,
    -- int::text
    -- Menu parent
    CAST(JSON_Unquote(JSON_Extract(tags, '$._menu_item_menu_item_parent')) AS int) AS parent_id,
    -- Enum ("custom","entite","page")
    -- object_id type ?
    JSON_Unquote(JSON_Extract(tags, '$._menu_item_object')) AS object_type,
    -- ??????
    -- int::text
    CAST(JSON_Unquote(JSON_Extract(tags, '$._menu_item_object_id')) AS int) AS object_id,
    -- !! DEPRECATED - No values
    -- JSON_Unquote(JSON_Extract(tags, '$._menu_item_target')) AS target,
    -- Enum ("custom","post_type","taxonomy") (??)
    -- !! DEPRECATED
    --  JSON_Unquote(JSON_Extract(tags, '$._menu_item_type')) AS type,
    -- Hexa color / "1" ????
    -- !! DEPRECATED
    -- JSON_Unquote(JSON_Extract(tags, '$._menu_item_url')) AS url,
    -- Hexa color / "1" ????
    -- !! DEPRECATED Not in the code
    -- JSON_Unquote(JSON_Extract(tags, '$._menu_item_xfn')) AS xfn,
    -- Boolean ("0"/"1")
    -- Is menu enabled or not by default.
    CASE WHEN CAST(JSON_Unquote(JSON_Extract(tags, '$.enabled_by_default')) AS int) THEN 'true' ELSE 'false' END AS selected_by_default,
    -- Boolean ("0"/"1")
    -- Index content for full text search
    CASE WHEN NOT CAST(JSON_Unquote(JSON_Extract(tags, '$.menu_dont_index')) AS int) THEN 'true' ELSE 'false' END AS search_indexed,
    -- Boolean ("0"/"1")
    -- Hidden menu item
    CASE WHEN CAST(JSON_Unquote(JSON_Extract(tags, '$.menu_hide')) AS int) THEN 'true' ELSE 'false' END AS hidden,
    -- Hexa color / [SearchForm] ????
    -- JSON_Unquote(JSON_Extract(tags, '$.shortcode')) AS shortcode,

    -- UI

    -- Hexa color
    JSON_Unquote(JSON_Extract(tags, '$.color')) AS color,
    -- Class of CSS Font icon.
    JSON_Unquote(JSON_Extract(tags, '$.icon')) AS icon,
    -- !! DEPRECATED Not in the code
    -- JSON_Unquote(JSON_Extract(tags, '$.color_icon'))
    -- !! DEPRECATED Not in the code
    -- JSON_Unquote(JSON_Extract(tags, '$.color_text'))
    -- Enum "compact"/"large"
    -- Menu icon display mode
    ifnull(JSON_Unquote(JSON_Extract(tags, '$.display')), 'compact') AS display_mode,

    -- Categories / Sources

    post_title,
    -- int::text
    -- Zoom level to display this category
    CAST(JSON_Unquote(JSON_Extract(tags, '$.selection_zoom')) AS int) AS zoom,
    -- One up to three lenght array of class from data ontology.
    JSON_Unquote(JSON_Extract(tags, '$.tourism_style_class')) AS tourism_style_class,
    -- Boolean ("0"/"1")
    -- Is this category used in the vector tiles background map.
    CAST(JSON_Unquote(JSON_Extract(tags, '$.tourism_style_merge')) AS int) AS tourism_style_merge,
    -- Value ("1"...?) when sources_de_donnees_[N]_data_source available
    -- JSON_Unquote(JSON_Extract(tags, '$.sources_de_donnees')) AS sources_de_donnees,
    -- "1;osm;aires-covoiturages"
    -- Split on ";", first value as sp_menuniveau3 id
    cast(substring_index(nullif(JSON_Unquote(JSON_Extract(tags, '$.sources_de_donnees_0_data_source')), 'empty'), ';', 1) AS int) AS data_source_0,
    cast(substring_index(nullif(JSON_Unquote(JSON_Extract(tags, '$.sources_de_donnees_1_data_source')), 'empty'), ';', 1) AS int) AS data_source_1,
    cast(substring_index(nullif(JSON_Unquote(JSON_Extract(tags, '$.sources_de_donnees_2_data_source')), 'empty'), ';', 1) AS int) AS data_source_2,
    cast(substring_index(nullif(JSON_Unquote(JSON_Extract(tags, '$.sources_de_donnees_3_data_source')), 'empty'), ';', 1) AS int) AS data_source_3,
    cast(substring_index(nullif(JSON_Unquote(JSON_Extract(tags, '$.sources_de_donnees_4_data_source')), 'empty'), ';', 1) AS int) AS data_source_4
FROM (
SELECT
    wp_posts.id,
    menu_order,
    -- text
    -- Category title
    post_title,
    -- text / int::text
    -- ??
    -- post_name,
    JSON_ObjectAgg(meta_key, JSON_Unquote(nullif(meta_value, ''))) AS tags
FROM
    wp_posts
    JOIN wp_postmeta ON
        wp_postmeta.post_id = wp_posts.id AND
        meta_key IN (
            '_menu_item_classes',
            '_menu_item_menu_item_parent',
            '_menu_item_object',
            '_menu_item_object_id',
            '_menu_item_target',
            '_menu_item_type',
            '_menu_item_url',
            '_menu_item_xfn',
            'color',
            'color_icon',
            'color_text',
            'display',
            'enabled_by_default',
            'icon',
            'menu_dont_index',
            'menu_hide',
            'selection_zoom',
            'shortcode',
            'sources_de_donnees',
            'sources_de_donnees_0_data_source',
            'sources_de_donnees_1_data_source',
            'sources_de_donnees_2_data_source',
            'sources_de_donnees_3_data_source',
            'sources_de_donnees_4_data_source',
            'tourism_style_class',
            'tourism_style_merge'
        )
    JOIN wp_term_relationships AS tr ON
        tr.object_id = wp_posts.ID
    JOIN wp_term_taxonomy AS tt ON
        tt.term_taxonomy_id = tr.term_taxonomy_id AND
        tt.term_id = (
            SELECT
                tt.term_id
            FROM
                wp_terms AS t
                LEFT JOIN wp_term_taxonomy AS tt ON
                    tt.term_id = t.term_id
            WHERE
                tt.taxonomy = 'nav_menu' AND NAME = 'tourism'
        )
WHERE
    post_type = 'nav_menu_item' AND
    post_status = 'publish' AND
    post_title NOT IN ('', 'shortcode', 'Filtre')
GROUP BY
    wp_posts.id
) AS t
;


-- Property labels
DROP VIEW IF EXISTS tmp_export_property_labels;
CREATE VIEW tmp_export_property_labels AS
SELECT
    tag as property,
    nullif(json_object('fr', NULLIF(label, '')), '{"fr": null}') AS property_label,
    nullif(json_object('fr', NULLIF(NULLIF(label_fiche, label), '')), '{"fr": null}') AS property_label_details,
    nullif(json_object('fr', NULLIF(NULLIF(label_infobulle, label), '')), '{"fr": null}') AS property_label_popup,
    nullif(json_object('fr', NULLIF(NULLIF(label_filtre, label), '')), '{"fr": null}') AS property_label_filter,
    nullif(concat('{', replace(replace(json_quote(trim(TRAILING ';' from values_labels)), ';', '"},"'), '=', '": {"fr":"'), '}}'), '{""}}') AS value_labels,
    nullif(concat('{', replace(replace(json_quote(trim(TRAILING ';' from nullif(values_labels_liste, values_labels))), ';', '"},"'), '=', '": {"fr":"'), '}}'), '{""}}') AS value_labels_list,
    nullif(concat('{', replace(replace(json_quote(trim(TRAILING ';' from nullif(values_labels_popup, values_labels))), ';', '"},"'), '=', '": {"fr":"'), '}}'), '{""}}') AS value_labels_popup
FROM
    sp_tags
WHERE
    nullif(tag, '') IS NOT NULL
HAVING
	property IS NOT NULL

UNION ALL

SELECT
    concat('tis_', field) as property,
    nullif(json_object('fr', NULLIF(label, '')), '{"fr": null}') AS property_label,
    nullif(json_object('fr', NULLIF(NULLIF(label_fiche, label), '')), '{"fr": null}') AS property_label_details,
    nullif(json_object('fr', NULLIF(NULLIF(label_infobulle, label), '')), '{"fr": null}') AS property_label_popup,
    NULL AS property_label_filter,
    nullif(concat('{', replace(replace(json_quote(trim(TRAILING ';' from values_labels)), ';', '"},"'), '=', '": {"fr":"'), '}}'), '{""}}') AS value_labels,
    NULL AS value_labels_list,
    NULL AS value_labels_popup
FROM
    sp_tis_fields
WHERE
    nullif(field, '') IS NOT NULL AND
    nullif(label, '') IS NOT NULL
HAVING
	property IS NOT NULL
;


-- Category
DROP VIEW IF EXISTS tmp_export_categories;
CREATE VIEW tmp_export_categories AS
SELECT
    -- Category
    tmp_wp_posts_wp_postmeta.id AS id,
    slug,
    json_object('fr', label) AS name, -- Category name
    -- post_title AS name
    search_indexed,

    -- UI
    ifnull(sp_menuniveau3.icon, ''), -- CSS icon.
    ifnull(sp_menuniveau3.color, '#FF0000'), -- CSS color.
    CASE WHEN tmp_wp_posts_wp_postmeta.tourism_style_class IS NOT NULL AND tmp_wp_posts_wp_postmeta.tourism_style_class != 'null' THEN
        concat('["', replace(tmp_wp_posts_wp_postmeta.tourism_style_class, ';', '","'), '"]')
    END AS tourism_style_class, -- One up to three lenght array of class from data ontology.
    CASE WHEN tmp_wp_posts_wp_postmeta.tourism_style_merge THEN 'true' ELSE 'false' END AS tourism_style_merge, -- Is this category used in the vector tiles background map.
    -- tourism_style_class, Duplicate menu.
    -- tourism_style_merge, Duplicate menu.
    display_mode,
    zoom
FROM
    tmp_wp_posts_wp_postmeta
    JOIN sp_menuniveau3 ON
        sp_menuniveau3.id IN (
            tmp_wp_posts_wp_postmeta.data_source_0,
            tmp_wp_posts_wp_postmeta.data_source_1,
            tmp_wp_posts_wp_postmeta.data_source_2,
            tmp_wp_posts_wp_postmeta.data_source_3,
            tmp_wp_posts_wp_postmeta.data_source_4
        )
;


-- Besoin de Maria DB 10.6
-- DROP VIEW IF EXISTS tmp_export_category_filters;
-- CREATE VIEW tmp_export_category_filters AS
-- SELECT
--     -- id
--     tmp_wp_posts_wp_postmeta.id AS id,
--     'multiselection' AS type, -- filter type
--     property -- property to filter on
-- FROM
--     tmp_wp_posts_wp_postmeta
--     JOIN sp_menuniveau3 ON
--         sp_menuniveau3.id IN (
--             tmp_wp_posts_wp_postmeta.data_source_0,
--             tmp_wp_posts_wp_postmeta.data_source_1,
--             tmp_wp_posts_wp_postmeta.data_source_2,
--             tmp_wp_posts_wp_postmeta.data_source_3,
--             tmp_wp_posts_wp_postmeta.data_source_4
--         )
--     JOIN json_table(
--         concat('["', replace(SelectionFiltreTag, ';', '","'), '"]'),
--         '$[*]' columns (property varchar path '$')
--     ) AS p ON 1
-- WHERE
--     SelectionFiltreTag IS NOT NULL AND
--     SelectionFiltreTag != ''
-- ;


-- FIXME
-- Falsback sans MariaDB 10.6
-- Ne splite pas les valeurs sur ';'
DROP VIEW IF EXISTS tmp_export_category_filters;
CREATE VIEW tmp_export_category_filters AS
    -- List of tags using a set of values, can be filtred by html select
    SELECT
        tmp_wp_posts_wp_postmeta.id * 3 + 0 AS id,
        tmp_wp_posts_wp_postmeta.id AS category_id,
        'multiselection' AS type, -- filter type
        -- FIXME
        substring_index(SelectionFiltreTag, ';', 1) AS property, -- property to filter on
        NULL AS `values`
    FROM
        tmp_wp_posts_wp_postmeta
        JOIN sp_menuniveau3 ON
            sp_menuniveau3.id IN (
                tmp_wp_posts_wp_postmeta.data_source_0,
                tmp_wp_posts_wp_postmeta.data_source_1,
                tmp_wp_posts_wp_postmeta.data_source_2,
                tmp_wp_posts_wp_postmeta.data_source_3,
                tmp_wp_posts_wp_postmeta.data_source_4
            )
    WHERE
        SelectionFiltreTag IS NOT NULL AND
        SelectionFiltreTag != ''
UNION ALL
    -- List of tags using a set of values, can be filtred by a list of check box
    SELECT
        tmp_wp_posts_wp_postmeta.id * 3 + 1 AS id,
        tmp_wp_posts_wp_postmeta.id AS category_id,
        'checkboxes_list' AS type, -- filter type
        -- FIXME
        substring_index(CheckboxFiltreTag, ';', 1) AS property, -- property to filter on
        NULL AS `values`
    FROM
        tmp_wp_posts_wp_postmeta
        JOIN sp_menuniveau3 ON
            sp_menuniveau3.id IN (
                tmp_wp_posts_wp_postmeta.data_source_0,
                tmp_wp_posts_wp_postmeta.data_source_1,
                tmp_wp_posts_wp_postmeta.data_source_2,
                tmp_wp_posts_wp_postmeta.data_source_3,
                tmp_wp_posts_wp_postmeta.data_source_4
            )
    WHERE
        CheckboxFiltreTag IS NOT NULL AND
        CheckboxFiltreTag != ''
UNION ALL
    -- Some list-like of tags, can be enable by checkbox
    SELECT
        tmp_wp_posts_wp_postmeta.id * 3 + 2 AS id,
        tmp_wp_posts_wp_postmeta.id AS category_id,
        'boolean' AS type, -- filter type
        -- FIXME
        substring_index(substring_index(BooleanFiltreTags, ';', 1), '=', 1) AS property, -- property to filter on
        NULL AS `values`
    FROM
        tmp_wp_posts_wp_postmeta
        JOIN sp_menuniveau3 ON
            sp_menuniveau3.id IN (
                tmp_wp_posts_wp_postmeta.data_source_0,
                tmp_wp_posts_wp_postmeta.data_source_1,
                tmp_wp_posts_wp_postmeta.data_source_2,
                tmp_wp_posts_wp_postmeta.data_source_3,
                tmp_wp_posts_wp_postmeta.data_source_4
            )
    WHERE
        BooleanFiltreTags IS NOT NULL AND
        BooleanFiltreTags != ''
;



-- -- c'est le mêmes filtres ?
-- ButtonFiltreTags      | text         | NO  |     | NULL | -- Utiliser pour afficher un bouton dans un templete - pour afficher quoi au final ?
-- DateFiltreTags        | text         | NO  |     | NULL | -- Afficher des champs de filtre temporel - liée au module projet ?




-- -- Fiche ??????? (Category)
-- hasfiche              | varchar(3)   | NO  |     | NULL |
-- label_fiche           | text         | NO  |     | NULL |
-- ficheBlocs            | text         | NO  |     | NULL |
-- fiche_specific_fields | text         | NO  |     | NULL |
-- SelectionFicheTag     | text         | NO  |     | NULL |
-- BooleanFicheTags      | text         | NO  |     | NULL |





DROP VIEW IF EXISTS tmp_export_categorie_sources_osm;
CREATE VIEW tmp_export_categorie_sources_osm AS
SELECT
    tmp_wp_posts_wp_postmeta.id AS id,
    tmp_wp_posts_wp_postmeta.id AS category_id,
    tmp_wp_posts_wp_postmeta.data_source_id AS source_osm_id
FROM
    sp_menuniveau3
    JOIN (
        (SELECT id, data_source_0 AS data_source_id FROM tmp_wp_posts_wp_postmeta) UNION ALL
        (SELECT id, data_source_1 AS data_source_id FROM tmp_wp_posts_wp_postmeta) UNION ALL
        (SELECT id, data_source_2 AS data_source_id FROM tmp_wp_posts_wp_postmeta) UNION ALL
        (SELECT id, data_source_3 AS data_source_id FROM tmp_wp_posts_wp_postmeta) UNION ALL
        (SELECT id, data_source_4 AS data_source_id FROM tmp_wp_posts_wp_postmeta)
    ) AS tmp_wp_posts_wp_postmeta ON
        tmp_wp_posts_wp_postmeta.data_source_id = sp_menuniveau3.id
WHERE
    poi_type = 'osm'
;

DROP VIEW IF EXISTS tmp_export_categorie_sources_tourinsoft;
CREATE VIEW tmp_export_categorie_sources_tourinsoft AS
SELECT
    tmp_wp_posts_wp_postmeta.id AS id,
    tmp_wp_posts_wp_postmeta.id AS category_id,
    tmp_wp_posts_wp_postmeta.data_source_id AS source_tourinsoft_id
FROM
    sp_menuniveau3
    JOIN (
        (SELECT id, data_source_0 AS data_source_id FROM tmp_wp_posts_wp_postmeta) UNION ALL
        (SELECT id, data_source_1 AS data_source_id FROM tmp_wp_posts_wp_postmeta) UNION ALL
        (SELECT id, data_source_2 AS data_source_id FROM tmp_wp_posts_wp_postmeta) UNION ALL
        (SELECT id, data_source_3 AS data_source_id FROM tmp_wp_posts_wp_postmeta) UNION ALL
        (SELECT id, data_source_4 AS data_source_id FROM tmp_wp_posts_wp_postmeta)
    ) AS tmp_wp_posts_wp_postmeta ON
        tmp_wp_posts_wp_postmeta.data_source_id = sp_menuniveau3.id
WHERE
    poi_type = 'tis'
;

DROP VIEW IF EXISTS tmp_export_categorie_sources_cms;
CREATE VIEW tmp_export_categorie_sources_cms AS
SELECT
    tmp_wp_posts_wp_postmeta.id AS id,
    tmp_wp_posts_wp_postmeta.id AS category_id,
    tmp_wp_posts_wp_postmeta.data_source_id AS source_cms_id
FROM
    sp_menuniveau3
    JOIN (
        (SELECT id, data_source_0 AS data_source_id FROM tmp_wp_posts_wp_postmeta) UNION ALL
        (SELECT id, data_source_1 AS data_source_id FROM tmp_wp_posts_wp_postmeta) UNION ALL
        (SELECT id, data_source_2 AS data_source_id FROM tmp_wp_posts_wp_postmeta) UNION ALL
        (SELECT id, data_source_3 AS data_source_id FROM tmp_wp_posts_wp_postmeta) UNION ALL
        (SELECT id, data_source_4 AS data_source_id FROM tmp_wp_posts_wp_postmeta)
    ) AS tmp_wp_posts_wp_postmeta ON
        tmp_wp_posts_wp_postmeta.data_source_id = sp_menuniveau3.id
WHERE
    poi_type = 'wp'
;



-- Menu group
DROP VIEW IF EXISTS tmp_export_menu_groups;
CREATE VIEW tmp_export_menu_groups AS
SELECT
    tmp_wp_posts_wp_postmeta.id AS id,
    slugify(post_title) AS slug,
    json_object('fr', post_title) AS name,

    -- UI
    ifnull(tmp_wp_posts_wp_postmeta.icon, '') AS icon, -- CSS icon.
    ifnull(tmp_wp_posts_wp_postmeta.color, '#FF0000') AS color, -- CSS color.
    CASE WHEN tmp_wp_posts_wp_postmeta.tourism_style_class IS NOT NULL AND tmp_wp_posts_wp_postmeta.tourism_style_class != 'null' THEN
        concat('["', replace(tmp_wp_posts_wp_postmeta.tourism_style_class, ';', '","'), '"]')
    END AS tourism_style_class, -- One up to three lenght array of class from data ontology.
    -- tourism_style_class, Duplicate menu.
    display_mode
FROM
    tmp_wp_posts_wp_postmeta
    LEFT JOIN sp_menuniveau3 ON
        sp_menuniveau3.id IN (
            tmp_wp_posts_wp_postmeta.data_source_0,
            tmp_wp_posts_wp_postmeta.data_source_1,
            tmp_wp_posts_wp_postmeta.data_source_2,
            tmp_wp_posts_wp_postmeta.data_source_3,
            tmp_wp_posts_wp_postmeta.data_source_4
        )
WHERE
    sp_menuniveau3.id IS NULL
;




-- Menu items
DROP VIEW IF EXISTS tmp_export_menu_items;
CREATE VIEW tmp_export_menu_items AS
SELECT
    tmp_wp_posts_wp_postmeta.id,
    1 AS theme_id,
    -- Menu
    CASE WHEN parent_id != 0 THEN parent_id END AS parent_id,
    tmp_wp_posts_wp_postmeta.menu_order AS index_order,
    -- object_type,
    -- object_id,
    hidden,
    selected_by_default,
    -- Category
    CASE WHEN sp_menuniveau3.id IS NOT NULL THEN tmp_wp_posts_wp_postmeta.id END AS category_id,
    CASE WHEN sp_menuniveau3.id IS NULL THEN tmp_wp_posts_wp_postmeta.id END AS menu_group_id
FROM
    tmp_wp_posts_wp_postmeta
    LEFT JOIN sp_menuniveau3 ON
        sp_menuniveau3.id IN (
            tmp_wp_posts_wp_postmeta.data_source_0,
            tmp_wp_posts_wp_postmeta.data_source_1,
            tmp_wp_posts_wp_postmeta.data_source_2,
            tmp_wp_posts_wp_postmeta.data_source_3,
            tmp_wp_posts_wp_postmeta.data_source_4
        )
;
