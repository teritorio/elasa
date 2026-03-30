export default {
  id: 'create-local-codes',

  handler: async ({ tableName }, { services, database, accountability, data }) => {
    await database.transaction(async (trx) => {
      const rawKeys = data?.$trigger?.body?.keys || [];
      const projectIds = rawKeys.map((key) => Number(key)).filter((key) => Number.isInteger(key));

      if (projectIds.length !== 1) {
        throw new Error('Create Local Codes expects exactly one selected project.');
      }

      const project = await trx.select('id', 'slug').from('projects').where('id', projectIds[0]).first();
      if (!project) {
        throw new Error('Selected project not found.');
      }

      const normalizedName = normalizeName(tableName);
      if (!normalizedName) {
        throw new Error('Table name is required.');
      }

      const fullTableName = buildTableName(project.slug, normalizedName);
      const exists = await trx.schema.withSchema('public').hasTable(fullTableName);
      if (exists) {
        throw new Error(`Table ${fullTableName} already exists.`);
      }

      await trx.raw(`CREATE TABLE IF NOT EXISTS "${fullTableName}" (
        id SERIAL PRIMARY KEY,
        code character varying(255) NOT NULL UNIQUE
      )`);

      await trx.raw(`
        INSERT INTO directus_collections(collection, icon, "group")
        VALUES (:collection, :icon, :group)
        ON CONFLICT (collection)
        DO UPDATE SET
          icon = :icon,
          "group" = :group
      `, {
        collection: fullTableName,
        icon: 'list',
        group: 'local_codes',
      });

      const fields = [
        { field: 'id', readonly: true, interface: null, sort: 1 },
        { field: 'code', readonly: false, interface: 'input', sort: 2 },
      ];

      for (const field of fields) {
        await trx.raw(`
          MERGE INTO directus_fields
          USING (SELECT ?, ?, ?::boolean, ?::text, ?::integer) AS source(collection, field, readonly, interface, sort)
          ON (directus_fields.collection = source.collection AND directus_fields.field = source.field)
          WHEN NOT MATCHED THEN
            INSERT (collection, field, readonly, interface, sort)
            VALUES (source.collection, source.field, source.readonly, source.interface, source.sort)
          WHEN MATCHED THEN
            UPDATE SET
              readonly = source.readonly,
              interface = source.interface,
              sort = source.sort
        `, [fullTableName, field.field, field.readonly, field.interface, field.sort]);
      }

      const policy = (await trx.raw(`
        SELECT directus_access.policy
        FROM directus_users
        JOIN directus_access ON directus_access.role = directus_users.role
        WHERE directus_users.project_id = ?
        LIMIT 1
      `, [project.id])).rows[0]?.policy;

      if (policy) {
        for (const action of ['create', 'read', 'update', 'delete']) {
          await trx.raw(`
            MERGE INTO directus_permissions
            USING (SELECT ?::uuid, ?, ?, ?::json, ?) AS source(policy, collection, action, permissions, fields)
            ON (directus_permissions.policy = source.policy AND directus_permissions.collection = source.collection AND directus_permissions.action = source.action)
            WHEN NOT MATCHED THEN
              INSERT (policy, collection, action, permissions, fields)
              VALUES (source.policy, source.collection, source.action, source.permissions, source.fields)
            WHEN MATCHED THEN
              UPDATE SET
                permissions = source.permissions,
                fields = source.fields
          `, [policy, fullTableName, action, {}, '*']);
        }
      }

      const utilsService = new services.UtilsService({ accountability });
      await utilsService.clearCache({ system: true });
    });
  },
};

function normalizeName(value) {
  return value.trim().toLowerCase().replace(/[^-a-z0-9]+/g, '_');
}

function buildTableName(projectSlug, tableName) {
  const normalizedProject = normalizeName(projectSlug);
  const baseName = `local-${normalizedProject}-codes-${tableName}`;
  return baseName.slice(0, 63);
}
