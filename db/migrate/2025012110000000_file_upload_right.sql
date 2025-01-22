UPDATE directus_permissions
SET permissions = '{"_and":[{"_or":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}},{"_and":[{"project_id":{"_null":true}},{"uploaded_by":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}]}]}'
WHERE id IN (2, 3, 4);
