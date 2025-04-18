ALTER TABLE fields DROP CONSTRAINT fields_uniq_field;
ALTER TABLE fields ADD CONSTRAINT fields_uniq_field_group UNIQUE NULLS NOT DISTINCT (project_id, "group", field);
