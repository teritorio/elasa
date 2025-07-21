var index = ({ filter, action }, { env, services }) => {
  const { ItemsService } = services;

  async function setProjectId(payload, { event, collection }, { database, schema, accountability }) {
    if (
      ["menu_items", "fields", "filters", "sources", "themes", "articles", "translations", "directus_folders"].includes(collection) ||
      collection.startsWith("local-")
    ) {
      if (accountability && accountability.user) {
        const user = await database.select("project_id").from("directus_users").where("id", accountability.user).first();
        if (user && user.project_id) {
          payload.project_id = user.project_id;
        }
      }
    }
    return payload;
  };

  filter("items.create", setProjectId);
  filter("folders.create", setProjectId);

  action("files.upload", async ({ event, payload, key, collection }, { schema, accountability }) => {
    if (accountability && accountability.user) {
      const usersItemsService = new ItemsService('directus_users', {
        schema: schema,
        accountability: accountability
      });
      const filesItemsService = new ItemsService('directus_files', {
        schema: schema,
        accountability: accountability
      });

      usersItemsService.readOne(accountability.user).then((user) => {
        filesItemsService.updateOne(key, {
          project_id: user.project_id
        })
      });
    }
  });
};

export { index as default };
