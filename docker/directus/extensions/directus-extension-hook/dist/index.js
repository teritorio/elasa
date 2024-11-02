var index = ({ filter, action }, { env, services }) => {
  const { ItemsService } = services;

  filter("items.create", async (payload, { event, collection }, { database, schema, accountability }) => {
    if (["menu_items", "fields", "filters", "sources", "themes", "translations", "directus_folders"].includes(collection)) {
      if (accountability && accountability.user) {
        const user = await database.select("project_id").from("directus_users").where("id", accountability.user).first();
        if (user && user.project_id) {
          payload.project_id = user.project_id;
        }
      }
    }
    return payload;
  });

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
