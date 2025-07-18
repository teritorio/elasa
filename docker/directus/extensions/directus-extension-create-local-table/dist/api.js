export default {
  id: 'create-locale-table',

  handler: async ({ withImages, withName, withThumbnail, withDescription, withAddr, withContact, withColors, withDeps, withWaypoints }, { services, database, get, env, logger, data, accountability }) => {
    try {
      [withImages, withName, withThumbnail, withDescription, withAddr, withContact, withColors, withDeps, withWaypoints] = [withImages, withName, withThumbnail, withDescription, withAddr, withContact, withColors, withDeps, withWaypoints].map((value) => value.toString().trim() === 'true');

      const sourcesIds = data['$trigger']['body']['keys'].map((key) => Number(key));
      let sources = (await database.raw(`
        SELECT
          slug,
          sources.id,
          project_id,
          jsonb_agg(jsonb_build_object('language', languages_code, 'translation', name)) AS translations
        FROM
          sources
          LEFT JOIN sources_translations ON
            sources.id = sources_translations.sources_id
        WHERE
          sources.id::text = ANY (?)
        GROUP BY
          sources.id
      `, [sourcesIds])).rows
      sources = [...sources];
      const projects = await database.select("slug", "id").from("projects").where("id", sources[0].project_id).first();
      const policy = (await database.raw(`
        SELECT
          directus_access.policy
        FROM
          directus_users
          JOIN directus_access ON
            directus_access.role = directus_users.role
        WHERE
          directus_users.project_id = ?
      `, [projects.id])).rows[0].policy;

      sources.forEach(async (source) => {
        let fields = {};
        if (withAddr) {
          fields = Object.assign(fields, {
            "addr___housenumber": "character varying(255)",
            "addr___street": "character varying(255)",
            "addr___place": "character varying(255)",
            "addr___postcode": "character varying(255)",
            "addr___city": "character varying(255)",
          });
        }
        if (withContact) {
          fields = Object.assign(fields, {
            "website": "jsonb",
            "phone": "jsonb",
            "email": "jsonb",
            "facebook": "character varying(255)",
            "instagram": "character varying(255)",
          });
        }
        if (withColors) {
          fields = Object.assign(fields, {
            "color_fill": "character varying(255)",
            "color_line": "character varying(255)",
          });
        }
        let fields_t = {};
        if (withName) { fields_t["name"] = "character varying(255)"; }
        if (withDescription) { fields_t["description"] = "text"; }

        const tableName = `local-${projects.slug}-${source.slug}`.slice(-63);
        const tableNameT = tableName.slice(-63 + 2) + '_t';
        create_main(projects, policy, tableName, tableNameT, source.translations, fields, fields_t, withThumbnail, { services, database, get, env, logger, data, accountability });
        create_others(projects, policy, tableName, { withImages, withDeps, withWaypoints }, { services, database, get, env, logger, data, accountability });

        await database.raw('SELECT api01.create_pois_local_view(?, ?, ?)', [projects.id, source.id, tableName]);
        await database.raw(`SELECT api01.force_update_pois_local(?)`, [tableName]);

        // Force database schema re-read
        const itemsService = new services.UtilsService({
          accountability: accountability,
        });
        await itemsService.clearCache({ system: true });
      });
    } catch (error) {
      console.error(error);
      throw error;
    }
  },
};

async function create_main(projects, policy, tableName, tableNameT, translations, fields, fields_t, withThumbnail, { services, database, get, env, logger, data, accountability }) {
  await database.raw(`CREATE TABLE IF NOT EXISTS "${tableName}" (id integer DEFAULT nextval('"pois_id_seq"'::regclass) PRIMARY KEY, geom geometry(Geometry,4326) NOT NULL)`);
  await database.raw(`CREATE INDEX IF NOT EXISTS "${tableName.slice(-63 + 9)}_idx_geom" ON "${tableName}" USING gist(geom)`);
  Object.entries(fields).forEach(async ([field, type]) => {
    await database.raw(`ALTER TABLE "${tableName}" ADD COLUMN IF NOT EXISTS ${field} ${type}`);
  });
  if (withThumbnail) { await database.raw(`ALTER TABLE "${tableName}" ADD COLUMN IF NOT EXISTS thumbnail uuid REFERENCES directus_files(id) ON DELETE CASCADE`); }
  console.info(`Table ${tableName} done`);

  await database.raw(`
    INSERT INTO directus_collections(collection, icon, "group", translations)
    VALUES (:collection, :icon, :group, :translations::json)
    ON CONFLICT (collection)
    DO UPDATE SET
      icon = :icon,
      "group" = :group,
      translations = :translations::json
`, { collection: tableName, icon: 'pin_drop', group: 'local_sources', translations: JSON.stringify(translations) });
  console.info(`Collection ${tableName} configured`);

  ['id', 'geom', 'thumbnail'].concat(Object.keys(fields)).forEach(async (field) => {
    await database.raw(`
      MERGE INTO directus_fields
      USING (SELECT ?, ?, ?::boolean, ?) AS source(collection, field, readonly, interface)
      ON (directus_fields.collection = source.collection AND directus_fields.field = source.field)
      WHEN NOT MATCHED THEN
        INSERT (collection, field, readonly, interface)
        VALUES (source.collection, source.field, source.readonly, source.interface)
      WHEN MATCHED THEN
        UPDATE SET collection = source.collection, field = source.field, readonly = source.readonly, interface = source.interface
    `, [tableName, field, field == 'id', field == 'thumbnail' ? 'file-image' : field.includes('color') ? 'select-color' : null]);
    console.info(`Field ${tableName}.${field} configured`);
  });

  ['create', 'read', 'update', 'delete'].forEach(async (action) => {
    await database.raw(`
      MERGE INTO directus_permissions
      USING (SELECT ?::uuid, ?, ?, ?::json, ?) AS source(policy, collection, action, permissions, fields)
      ON (directus_permissions.policy = source.policy AND directus_permissions.collection = source.collection AND directus_permissions.action = source.action)
      WHEN NOT MATCHED THEN
        INSERT (policy, collection, action, permissions, fields)
        VALUES (source.policy, source.collection, source.action, source.permissions, source.fields)
      WHEN MATCHED THEN
        UPDATE SET policy = source.policy, collection = source.collection, action = source.action, permissions = source.permissions, fields = source.fields
    `, [
      policy,
      tableName,
      action,
      {},
      '*'
    ]);
    console.info(`Permission ${tableName} ${action} configured`);
  });

  if (fields_t && Object.keys(fields_t).length > 0) {
    await database.raw(`CREATE TABLE IF NOT EXISTS "${tableNameT}" (id SERIAL PRIMARY KEY, pois_id INTEGER NOT NULL REFERENCES "${tableName}"(id) ON DELETE CASCADE, languages_code character varying(255) NOT NULL REFERENCES languages(code) ON DELETE CASCADE)`);
    Object.entries(fields_t).forEach(async ([field, type]) => {
      await database.raw(`ALTER TABLE "${tableNameT}" ADD COLUMN IF NOT EXISTS ${field} ${type}`);
    });
    console.info(`Table ${tableNameT} created`);

    await database.raw(`
      INSERT INTO directus_collections(collection, icon, "group", hidden)
      VALUES (:collection, :icon, :group, :hidden)
      ON CONFLICT (collection)
      DO UPDATE SET
        collection = :collection,
        icon = :icon,
        "group" = :group,
        hidden = :hidden
    `, { collection: tableNameT, icon: 'translate', group: tableName, hidden: true });
    console.info(`Collection ${tableNameT} configured`);

    await database.raw(`
      MERGE INTO directus_fields
      USING (SELECT ?, ?, ?, ?, ?::json, ?) AS source(collection, field, special, interface, options, display)
      ON (directus_fields.collection = source.collection AND directus_fields.field = source.field)
      WHEN NOT MATCHED THEN
        INSERT (collection, field, special, interface, options, display)
        VALUES (source.collection, source.field, source.special, source.interface, source.options, source.display)
      WHEN MATCHED THEN
        UPDATE SET collection = source.collection, field = source.field, special = source.special, interface = source.interface, options = source.options
    `, [tableName, 'translations', 'translations', 'translations', { "languageField": "name", "defaultLanguage": "en-US", "defaultOpenSplitView": true, "userLanguage": true }, 'translations']);
    console.info(`Field ${tableName}.translations configured`);

    ['id', 'pois_id', 'languages_code'].concat(Object.keys(fields_t)).forEach(async (field) => {
      await database.raw(`
        MERGE INTO directus_fields
        USING (SELECT ?, ?, ?::boolean, ?) AS source(collection, field, hidden, interface)
        ON (directus_fields.collection = source.collection AND directus_fields.field = source.field)
        WHEN NOT MATCHED THEN
          INSERT (collection, field, hidden, interface)
          VALUES (source.collection, source.field, source.hidden, source.interface)
        WHEN MATCHED THEN
          UPDATE SET collection = source.collection, field = source.field, hidden = source.hidden, interface = source.interface
    `, [tableNameT, field, ['id', 'pois_id', 'languages_code'].includes(field), field == 'description' ? 'input-rich-text-html' : null]);
      console.info(`Field ${tableName}.${field} configured`);
    });

    await database.raw(`
      MERGE INTO directus_relations
      USING (SELECT ?, ?, ?, ?, ?) AS source(many_collection, many_field, one_collection, one_field, junction_field)
      ON (directus_relations.many_collection = source.many_collection AND directus_relations.many_field = source.many_field AND directus_relations.one_collection = source.one_collection AND directus_relations.one_field = source.one_field)
      WHEN NOT MATCHED THEN
        INSERT (many_collection, many_field, one_collection, one_field, junction_field)
        VALUES (source.many_collection, source.many_field, source.one_collection, source.one_field, source.junction_field)
      WHEN MATCHED THEN
        UPDATE SET junction_field = source.junction_field
    `, [tableNameT, 'languages_code', 'languages', null, 'pois_id']);
    console.info(`Relation ${tableNameT} languages_code languages configured`);
    await database.raw(`
      MERGE INTO directus_relations
      USING (SELECT ?, ?, ?, ?, ?) AS source(many_collection, many_field, one_collection, one_field, junction_field)
      ON (directus_relations.many_collection = source.many_collection AND directus_relations.many_field = source.many_field AND directus_relations.one_collection = source.one_collection AND directus_relations.one_field = source.one_field)
      WHEN NOT MATCHED THEN
        INSERT (many_collection, many_field, one_collection, one_field, junction_field)
        VALUES (source.many_collection, source.many_field, source.one_collection, source.one_field, source.junction_field)
      WHEN MATCHED THEN
        UPDATE SET junction_field = source.junction_field
    `, [tableNameT, 'pois_id', tableName, 'translations', 'languages_code']);
    console.info(`Relation ${tableNameT} pois_id ${tableName} translations languages_code configured`);

    ['create', 'read', 'update', 'delete'].forEach(async (action) => {
      await database.raw(`
        MERGE INTO directus_permissions
        USING (SELECT ?::uuid, ?, ?, ?::json, ?) AS source(policy, collection, action, permissions, fields)
        ON (directus_permissions.policy = source.policy AND directus_permissions.collection = source.collection AND directus_permissions.action = source.action)
        WHEN NOT MATCHED THEN
          INSERT (policy, collection, action, permissions, fields)
          VALUES (source.policy, source.collection, source.action, source.permissions, source.fields)
        WHEN MATCHED THEN
          UPDATE SET policy = source.policy, collection = source.collection, action = source.action, permissions = source.permissions, fields = source.fields
      `, [
        policy,
        tableNameT,
        action,
        {},
        '*'
      ]);
      console.info(`Permission ${tableNameT} ${action} configured`);
    });
  }
};

async function create_others(projects, policy, tableName, { withImages, withDeps, withWaypoints }, { services, database, get, env, logger, data, accountability }) {
  if (withImages) {
    const tableNameI = tableName.slice(-63 + 2) + '_i';

    await database.raw(`CREATE TABLE IF NOT EXISTS "${tableNameI}" (id SERIAL PRIMARY KEY, pois_id bigint NOT NULL REFERENCES "${tableName}"(id) ON DELETE CASCADE, directus_files_id uuid NOT NULL REFERENCES directus_files(id) ON DELETE CASCADE, index INTEGER NOT NULL)`);
    console.info(`Table ${tableNameI} created`);

    await database.raw(`
      INSERT INTO directus_collections(collection, icon, "group", hidden)
      VALUES (?, ?, ?, ?)
      ON CONFLICT (collection)
      DO UPDATE SET
        collection = directus_collections.collection,
        icon = directus_collections.icon,
        "group" = directus_collections."group",
        hidden = directus_collections.hidden
    `, [tableNameI, 'image', tableName, true]);
    console.info(`Collection ${tableNameI} configured`);

    await database.raw(`
      MERGE INTO directus_fields
      USING (SELECT ?, ?, ?, ?, ?::json) AS source(collection, field, special, interface, options)
      ON (directus_fields.collection = source.collection AND directus_fields.field = source.field)
      WHEN NOT MATCHED THEN
        INSERT (collection, field, special, interface, options)
        VALUES (source.collection, source.field, source.special, source.interface, source.options)
      WHEN MATCHED THEN
        UPDATE SET collection = source.collection, field = source.field, special = source.special, interface = source.interface, options = source.options
    `, [tableName, 'image', 'files', 'files', { "template": "{{directus_files_id.$thumbnail}} {{directus_files_id.title}}" }]);
    console.info(`Field ${tableName}.image configured`);

    await database.raw(`
      MERGE INTO directus_relations
      USING (SELECT ?, ?, ?, ?, ?) AS source(many_collection, many_field, one_collection, one_field, junction_field)
      ON (directus_relations.many_collection = source.many_collection AND directus_relations.many_field = source.many_field AND directus_relations.one_collection = source.one_collection AND directus_relations.one_field = source.one_field)
      WHEN NOT MATCHED THEN
        INSERT (many_collection, many_field, one_collection, one_field, junction_field, one_deselect_action)
        VALUES (source.many_collection, source.many_field, source.one_collection, source.one_field, source.junction_field, 'delete')
      WHEN MATCHED THEN
        UPDATE SET junction_field = source.junction_field, one_deselect_action = 'delete'
    `, [tableNameI, 'directus_files_id', 'directus_files', null, 'pois_id']);
    console.info(`Relation ${tableNameI} directus_files_id directus_files configured`);
    await database.raw(`
      MERGE INTO directus_relations
      USING (SELECT ?, ?, ?, ?, ?, ?) AS source(many_collection, many_field, one_collection, one_field, junction_field, sort_field)
      ON (directus_relations.many_collection = source.many_collection AND directus_relations.many_field = source.many_field AND directus_relations.one_collection = source.one_collection AND directus_relations.one_field = source.one_field)
      WHEN NOT MATCHED THEN
        INSERT (many_collection, many_field, one_collection, one_field, junction_field, sort_field, one_deselect_action)
        VALUES (source.many_collection, source.many_field, source.one_collection, source.one_field, source.junction_field, source.sort_field, 'delete')
      WHEN MATCHED THEN
        UPDATE SET junction_field = source.junction_field, sort_field = source.sort_field, one_deselect_action = 'delete'
    `, [tableNameI, 'pois_id', tableName, 'image', 'directus_files_id', 'index']);
    console.info(`Relation ${tableNameI} pois_id ${tableName} image directus_files_id configured`);

    ['create', 'read', 'update', 'delete'].forEach(async (action) => {
      await database.raw(`
        MERGE INTO directus_permissions
        USING (SELECT ?::uuid, ?, ?, ?::json, ?) AS source(policy, collection, action, permissions, fields)
        ON (directus_permissions.policy = source.policy AND directus_permissions.collection = source.collection AND directus_permissions.action = source.action)
        WHEN NOT MATCHED THEN
          INSERT (policy, collection, action, permissions, fields)
          VALUES (source.policy, source.collection, source.action, source.permissions, source.fields)
        WHEN MATCHED THEN
          UPDATE SET policy = source.policy, collection = source.collection, action = source.action, permissions = source.permissions, fields = source.fields
      `, [
        policy,
        tableNameI,
        action,
        {},
        '*'
      ]);
      console.info(`Permission ${tableNameI} ${action} configured`);
    });
  }

  if (withDeps) {
    const tableNameP = tableName.slice(-63 + 2) + '_p';

    await database.raw(`CREATE TABLE IF NOT EXISTS "${tableNameP}" (id SERIAL PRIMARY KEY, parent_pois_id bigint NOT NULL REFERENCES "${tableName}"(id) ON DELETE CASCADE, children_pois_id integer NOT NULL REFERENCES pois(id) ON DELETE CASCADE, index INTEGER NOT NULL DEFAULT 1)`);
    console.info(`Table ${tableNameP} created`);

    await database.raw(`
      INSERT INTO directus_collections(collection, icon, "group", hidden)
      VALUES (?, ?, ?, ?)
      ON CONFLICT (collection)
      DO UPDATE SET
        collection = directus_collections.collection,
        icon = directus_collections.icon,
        "group" = directus_collections."group",
        hidden = directus_collections.hidden
    `, [tableNameP, 'import_export', tableName, true]);
    console.info(`Collection ${tableNameP} configured`);

    await database.raw(`
      MERGE INTO directus_fields
      USING (SELECT ?, ?, ?, ?, ?::json) AS source(collection, field, special, interface, options)
      ON (directus_fields.collection = source.collection AND directus_fields.field = source.field)
      WHEN NOT MATCHED THEN
        INSERT (collection, field, special, interface, options)
        VALUES (source.collection, source.field, source.special, source.interface, source.options)
      WHEN MATCHED THEN
        UPDATE SET collection = source.collection, field = source.field, special = source.special, interface = source.interface, options = source.options
    `, [tableName, 'associated_pois', 'm2m', 'list-m2m', { "enableCreate": false, "enableLink": true }]);
    console.info(`Field ${tableName}.deps configured`);

    await database.raw(`
      MERGE INTO directus_relations
      USING (SELECT ?, ?, ?, ?, ?) AS source(many_collection, many_field, one_collection, one_field, junction_field)
      ON (directus_relations.many_collection = source.many_collection AND directus_relations.many_field = source.many_field AND directus_relations.one_collection = source.one_collection AND directus_relations.one_field = source.one_field)
      WHEN NOT MATCHED THEN
        INSERT (many_collection, many_field, one_collection, one_field, junction_field, one_deselect_action)
        VALUES (source.many_collection, source.many_field, source.one_collection, source.one_field, source.junction_field, 'delete')
      WHEN MATCHED THEN
        UPDATE SET junction_field = source.junction_field, one_deselect_action = 'delete'
    `, [tableNameP, 'children_pois_id', 'pois', null, 'parent_pois_id']);
    console.info(`Relation ${tableNameP} deps configured`);
    await database.raw(`
      MERGE INTO directus_relations
      USING (SELECT ?, ?, ?, ?, ?, ?) AS source(many_collection, many_field, one_collection, one_field, junction_field, sort_field)
      ON (directus_relations.many_collection = source.many_collection AND directus_relations.many_field = source.many_field AND directus_relations.one_collection = source.one_collection AND directus_relations.one_field = source.one_field)
      WHEN NOT MATCHED THEN
        INSERT (many_collection, many_field, one_collection, one_field, junction_field, sort_field, one_deselect_action)
        VALUES (source.many_collection, source.many_field, source.one_collection, source.one_field, source.junction_field, source.sort_field, 'delete')
      WHEN MATCHED THEN
        UPDATE SET junction_field = source.junction_field, sort_field = source.sort_field, one_deselect_action = 'delete'
    `, [tableNameP, 'parent_pois_id', tableName, 'associated_pois', 'children_pois_id', 'index']);
    console.info(`Relation ${tableNameP} pois_id ${tableName} deps  configured`);

    ['create', 'read', 'update', 'delete'].forEach(async (action) => {
      await database.raw(`
        MERGE INTO directus_permissions
        USING (SELECT ?::uuid, ?, ?, ?::json, ?) AS source(policy, collection, action, permissions, fields)
        ON (directus_permissions.policy = source.policy AND directus_permissions.collection = source.collection AND directus_permissions.action = source.action)
        WHEN NOT MATCHED THEN
          INSERT (policy, collection, action, permissions, fields)
          VALUES (source.policy, source.collection, source.action, source.permissions, source.fields)
        WHEN MATCHED THEN
          UPDATE SET policy = source.policy, collection = source.collection, action = source.action, permissions = source.permissions, fields = source.fields
      `, [
        policy,
        tableNameP,
        action,
        {},
        '*'
      ]);
      console.info(`Permission ${tableNameP} ${action} configured`);
    });
  }

  if (withWaypoints) {
    const tableNameW = tableName.slice(-63 + 2) + '_w';
    const table_pdp = `local-${projects.slug}-waypoints`;

    await database.raw(`CREATE TABLE IF NOT EXISTS "${tableNameW}" (id SERIAL PRIMARY KEY, parent_pois_id bigint NOT NULL REFERENCES "${tableName}"(id) ON DELETE CASCADE, children_pois_id integer NOT NULL REFERENCES "${table_pdp}"(id) ON DELETE CASCADE, index INTEGER NOT NULL DEFAULT 1)`);
    console.info(`Table ${tableNameW} created`);

    await database.raw(`
      INSERT INTO directus_collections(collection, icon, "group", hidden)
      VALUES (?, ?, ?, ?)
      ON CONFLICT (collection)
      DO UPDATE SET
        collection = directus_collections.collection,
        icon = directus_collections.icon,
        "group" = directus_collections."group",
        hidden = directus_collections.hidden
    `, [tableNameW, 'import_export', tableName, true]);
    console.info(`Collection ${tableNameW} configured`);

    await database.raw(`
      MERGE INTO directus_fields
      USING (SELECT ?, ?, ?, ?, ?::json) AS source(collection, field, special, interface, options)
      ON (directus_fields.collection = source.collection AND directus_fields.field = source.field)
      WHEN NOT MATCHED THEN
        INSERT (collection, field, special, interface, options)
        VALUES (source.collection, source.field, source.special, source.interface, source.options)
      WHEN MATCHED THEN
        UPDATE SET collection = source.collection, field = source.field, special = source.special, interface = source.interface, options = source.options
    `, [tableName, 'waypoints', 'm2m', 'list-m2m', { "enableLink": true, "limit": 200, "layout": "table", "tableSpacing": "compact", "fields": ["index", "children_pois_id.route___waypoint___type", "children_pois_id.waypoints_translations.name"], "enableSelect": false }]);
    console.info(`Field ${tableName}.waypoints configured`);

    await database.raw(`
      MERGE INTO directus_relations
      USING (SELECT ?, ?, ?, ?, ?) AS source(many_collection, many_field, one_collection, one_field, junction_field)
      ON (directus_relations.many_collection = source.many_collection AND directus_relations.many_field = source.many_field AND directus_relations.one_collection = source.one_collection AND directus_relations.one_field = source.one_field)
      WHEN NOT MATCHED THEN
        INSERT (many_collection, many_field, one_collection, one_field, junction_field, one_deselect_action)
        VALUES (source.many_collection, source.many_field, source.one_collection, source.one_field, source.junction_field, 'delete')
      WHEN MATCHED THEN
        UPDATE SET junction_field = source.junction_field, one_deselect_action = 'delete'
    `, [tableNameW, 'children_pois_id', table_pdp, null, 'parent_pois_id']);
    console.info(`Relation ${tableNameW} waypoints configured`);
    await database.raw(`
      MERGE INTO directus_relations
      USING (SELECT ?, ?, ?, ?, ?, ?) AS source(many_collection, many_field, one_collection, one_field, junction_field, sort_field)
      ON (directus_relations.many_collection = source.many_collection AND directus_relations.many_field = source.many_field AND directus_relations.one_collection = source.one_collection AND directus_relations.one_field = source.one_field)
      WHEN NOT MATCHED THEN
        INSERT (many_collection, many_field, one_collection, one_field, junction_field, sort_field, one_deselect_action)
        VALUES (source.many_collection, source.many_field, source.one_collection, source.one_field, source.junction_field, source.sort_field, 'delete')
      WHEN MATCHED THEN
        UPDATE SET junction_field = source.junction_field, sort_field = source.sort_field, one_deselect_action = 'delete'
    `, [tableNameW, 'parent_pois_id', tableName, 'waypoints', 'children_pois_id', 'index']);
    console.info(`Relation ${tableNameW} pois_id ${tableName} waypoints configured`);

    ['create', 'read', 'update', 'delete'].forEach(async (action) => {
      await database.raw(`
        MERGE INTO directus_permissions
        USING (SELECT ?::uuid, ?, ?, ?::json, ?) AS source(policy, collection, action, permissions, fields)
        ON (directus_permissions.policy = source.policy AND directus_permissions.collection = source.collection AND directus_permissions.action = source.action)
        WHEN NOT MATCHED THEN
          INSERT (policy, collection, action, permissions, fields)
          VALUES (source.policy, source.collection, source.action, source.permissions, source.fields)
        WHEN MATCHED THEN
          UPDATE SET policy = source.policy, collection = source.collection, action = source.action, permissions = source.permissions, fields = source.fields
      `, [
        policy,
        tableNameW,
        action,
        {},
        '*'
      ]);
      console.info(`Permission ${tableNameW} ${action} configured`);
    });
  }
};
