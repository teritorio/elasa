ALTER TABLE pois_files ADD CONSTRAINT pois_files_uniq UNIQUE (pois_id, directus_files_id);
ALTER TABLE pois_pois ADD CONSTRAINT pois_pois_uniq UNIQUE (parent_pois_id, children_pois_id);

UPDATE
    directus_relations
SET
    one_deselect_action = 'delete'
WHERE
    id = 58
;

ALTER TABLE ONLY public.pois_files
DROP CONSTRAINT pois_files_directus_files_id_foreign,
ADD CONSTRAINT pois_files_directus_files_id_foreign FOREIGN KEY (directus_files_id) REFERENCES public.directus_files(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.pois_files
DROP CONSTRAINT pois_files_pois_id_foreign,
ADD CONSTRAINT pois_files_pois_id_foreign FOREIGN KEY (pois_id) REFERENCES public.pois(id) ON DELETE CASCADE;
