UPDATE fields SET label = coalesce(label, false);
ALTER TABLE fields RENAME COLUMN label TO label_large;
ALTER TABLE fields ALTER COLUMN label_large SET NOT NULL;
ALTER TABLE fields ALTER COLUMN label_large SET DEFAULT false;

ALTER TABLE fields ADD COLUMN label_small boolean NOT NULL DEFAULT false;

ALTER TABLE fields_translations ADD COLUMN name_small varchar(255);
ALTER TABLE fields_translations ADD COLUMN name_large varchar(255);
ALTER TABLE fields_translations ADD COLUMN name_title varchar(255);

UPDATE
    directus_fields
SET
    sort = 5,
    width = 'full'
WHERE
    id = 140
;

UPDATE
    directus_fields
SET
    sort = 6
WHERE
    id = 144
;

INSERT INTO
    directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message)
VALUES
    (1001, 'fields', 'label_small', NULL, 'boolean', NULL, NULL, NULL, false, false, 3, 'half', NULL, NULL, NULL, false, 'group_block', NULL, NULL),
    (1002, 'fields', 'label_large', NULL, 'boolean', NULL, NULL, NULL, false, false, 4, 'half', NULL, NULL, NULL, false, 'group_block', NULL, NULL),
    (1003, 'fields_translations', 'name_small', NULL, 'input', NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
    (1004, 'fields_translations', 'name_large', NULL, 'input', NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
    (1005, 'fields_translations', 'name_title', NULL, 'input', NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL)
;

UPDATE
    directus_permissions
SET
    fields = '*'
WHERE
    id IN (86, 87, 239, 240)
;
