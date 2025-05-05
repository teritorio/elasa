ALTER TABLE fields_fields ADD CONSTRAINT fields_fields_uniq_fields_id_related_fields_id UNIQUE (fields_id, related_fields_id);
