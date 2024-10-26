var index = ({ filter, action }, { env, services }) => {
  filter("items.create", async (payload, { event, collection }, { database, schema, accountability }) => {
    if (["menu_items", "fields", "filters", "sources", "themes", "translations"].includes(collection)) {
      if (accountability && accountability.user) {
        const user = await database.select("project_id").from("directus_users").where("id", accountability.user).first();
        if (user && user.project_id) {
          payload.project_id = user.project_id;
        }
      }
    }
    return payload;
  });
};

export { index as default };
