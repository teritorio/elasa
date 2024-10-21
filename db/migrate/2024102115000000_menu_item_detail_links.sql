ALTER TABLE menu_items RENAME COLUMN use_details_link TO use_internal_details_link;
ALTER TABLE menu_items ADD COLUMN use_external_details_link boolean DEFAULT true;
