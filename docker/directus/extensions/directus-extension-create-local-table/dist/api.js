export default {
  id: 'create-locale-table',

  handler: async ({ withTranslations, withImages, withName, withDescription, withAddr, withContact }, { services, database, get, env, logger, data, accountability }) => {
    try {
      [withTranslations, withImages, withName, withDescription, withAddr, withContact] = [withTranslations, withImages, withName, withDescription, withAddr, withContact].map((value) => value.toString().trim() === 'true');
      withTranslations = withTranslations || withName || withDescription;
      const sourcesIds = data['$trigger']['body']['keys'].map((key) => Number(key));

      let sources = (await database.raw(`
        SELECT
          slug,
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
        const tableName = `local-${projects.slug}-${source.slug}`.slice(-63);
        const tableNameT = tableName.slice(-63+2) + '_t';
        const tableNameI = tableName.slice(-63+2) +'_i';
        let tableExtraFields = {};
        if (withAddr) { tableExtraFields = Object.assign(tableExtraFields, { "addr___housenumber": "String", "addr___street": "String", "addr___place": "String", "addr___postcode": "String", "addr___city": "String" }); }
        if (withContact) { tableExtraFields = Object.assign(tableExtraFields, { "website": "Array", "phone": "Array", "email": "Array", "facebook": "String", "instagram": "String" }); }
        let fields = Object.entries(tableExtraFields).map(([field, type]) => `"${field}" ${type === 'String' ? 'character varying(255)' : 'jsonb'}`).join(', ')
        if (fields) {
          fields = `, ${fields}`;
        }
        await database.raw(`CREATE TABLE IF NOT EXISTS "${tableName}" (id integer DEFAULT nextval('"pois_id_seq"'::regclass) PRIMARY KEY, project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE, geom geometry(Geometry,4326) NOT NULL ${fields})`);
        await database.raw(`CREATE INDEX "${tableName.slice(-63+9)}_idx_geom" ON "${tableName}" USING gist(geom)`);
        console.info(`Table ${tableName} created`);
        if (withTranslations) {
          let fields = "";
          if (withName) { fields += ', name character varying(255)'; }
          if (withDescription) { fields += ', description text'; }
          await database.raw(`CREATE TABLE IF NOT EXISTS "${tableNameT}" (id SERIAL PRIMARY KEY, pois_id INTEGER NOT NULL REFERENCES "${tableName}"(id) ON DELETE CASCADE, languages_code character varying(255) NOT NULL REFERENCES languages(code) ON DELETE CASCADE ${fields})`);
          console.info(`Table ${tableNameT} created`);
        }
        if (withImages) {
          await database.raw(`CREATE TABLE IF NOT EXISTS "${tableNameI}" (id SERIAL PRIMARY KEY, pois_id bigint NOT NULL REFERENCES "${tableName}"(id) ON DELETE CASCADE, directus_files_id uuid NOT NULL REFERENCES directus_files(id) ON DELETE CASCADE, index INTEGER NOT NULL)`);
          console.info(`Table ${tableNameI} created`);
        }

        await database.raw(`
          INSERT INTO directus_collections(collection, icon, "group", translations)
          VALUES (:collection, :icon, :group, :translations::json)
          ON CONFLICT (collection)
          DO UPDATE SET
            icon = :icon,
            "group" = :group,
            translations = :translations::json
       `, { collection: tableName, icon: 'pin_drop', group: 'local_sources', translations: JSON.stringify(source.translations) });
        console.info(`Collection ${tableName} configured`);
        if (withTranslations) {
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
        }
        if (withImages) {
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
        }

        ['id', 'project_id', 'geom'].concat(Object.keys(tableExtraFields)).forEach(async (field) => {
          await database.raw(`
            MERGE INTO directus_fields
            USING (SELECT ?, ?, ?::boolean, ?::boolean) AS source(collection, field, hidden, readonly)
            ON (directus_fields.collection = source.collection AND directus_fields.field = source.field)
            WHEN NOT MATCHED THEN
              INSERT (collection, field, hidden, readonly)
              VALUES (source.collection, source.field, source.hidden, source.readonly)
            WHEN MATCHED THEN
              UPDATE SET collection = source.collection, field = source.field, hidden = source.hidden, readonly = source.readonly
          `, [tableName, field, field == 'project_id', field == 'id']);
          console.info(`Field ${tableName}.${field} configured`);
        });

        if (withTranslations) {
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
        }
        if (withImages) {
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
        }

        if (withTranslations) {
          let fields = ['id', 'pois_id', 'languages_code'];
          if (withName) { fields.push('name'); }
          if (withDescription) { fields.push('description'); }
          fields.forEach(async (field) => {
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
        }

        if (withTranslations) {
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
        }
        if (withImages) {
          await database.raw(`
            MERGE INTO directus_relations
            USING (SELECT ?, ?, ?, ?, ?) AS source(many_collection, many_field, one_collection, one_field, junction_field)
            ON (directus_relations.many_collection = source.many_collection AND directus_relations.many_field = source.many_field AND directus_relations.one_collection = source.one_collection AND directus_relations.one_field = source.one_field)
            WHEN NOT MATCHED THEN
              INSERT (many_collection, many_field, one_collection, one_field, junction_field)
              VALUES (source.many_collection, source.many_field, source.one_collection, source.one_field, source.junction_field)
            WHEN MATCHED THEN
              UPDATE SET junction_field = source.junction_field
          `, [tableNameI, 'directus_files_id', 'directus_files', null, 'pois_id']);
          console.info(`Relation ${tableNameI} directus_files_id directus_files configured`);
          await database.raw(`
            MERGE INTO directus_relations
            USING (SELECT ?, ?, ?, ?, ?, ?) AS source(many_collection, many_field, one_collection, one_field, junction_field, sort_field)
            ON (directus_relations.many_collection = source.many_collection AND directus_relations.many_field = source.many_field AND directus_relations.one_collection = source.one_collection AND directus_relations.one_field = source.one_field)
            WHEN NOT MATCHED THEN
              INSERT (many_collection, many_field, one_collection, one_field, junction_field, sort_field)
              VALUES (source.many_collection, source.many_field, source.one_collection, source.one_field, source.junction_field, source.sort_field)
            WHEN MATCHED THEN
              UPDATE SET junction_field = source.junction_field, sort_field = source.sort_field
          `, [tableNameI, 'pois_id', tableName, 'image', 'directus_files_id', 'index']);
          console.info(`Relation ${tableNameI} pois_id ${tableName} image directus_files_id configured`);
        }

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
            action == 'create' ? {} : { "_and": [{ project_id: { _eq: '$CURRENT_USER.project_id' } }] },
            '*'
          ]);
          console.info(`Permission ${tableName} ${action} configured`);
        });

        if (withTranslations) {
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
              action == 'create' ? {} : { pois_id: { project_id: { _eq: '$CURRENT_USER.project_id' } } },
              '*'
            ]);
            console.info(`Permission ${tableNameT} ${action} configured`);
          });
        }
        if (withImages) {
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
              action == 'create' ? {} : { pois_id: { project_id: { _eq: '$CURRENT_USER.project_id' } } },
              '*'
            ]);
            console.info(`Permission ${tableNameI} ${action} configured`);
          });
        }
      });
    } catch (error) {
      console.error(error);
      throw error;
    }
  },
};
