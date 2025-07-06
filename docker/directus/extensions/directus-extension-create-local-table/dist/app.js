export default {
  id: 'create-locale-table',
  name: 'Create Local Table',
  icon: 'box',
  description: 'Create a new table in the local database',

  overview: ({ }) => [],

  options: [
    {
      field: "withTranslations",
      name: "Add join table for translations",
      type: "boolean",
      meta: {
        interface: "toggle",
      },
      schema: {
        default_value: false,
      },
    },
    {
      field: "withImages",
      name: "Add join table for images",
      type: "boolean",
      meta: {
        interface: "toggle",
      },
      schema: {
        default_value: false,
      },
    },
    {
      field: "withThumbnail",
      name: "Add thumbnail field",
      type: "boolean",
      meta: {
        interface: "toggle",
      },
      schema: {
        default_value: false,
      },
    },
    {
      field: "withName",
      name: "Add a name field",
      type: "boolean",
      meta: {
        interface: "toggle",
      },
      schema: {
        default_value: false,
      },
    },
    {
      field: "withDescription",
      name: "Add a name description",
      type: "boolean",
      meta: {
        interface: "toggle",
      },
      schema: {
        default_value: false,
      },
    },
    {
      field: "withAddr",
      name: "Add addr:* fields",
      type: "boolean",
      meta: {
        interface: "toggle",
      },
      schema: {
        default_value: false,
      },
    },
    {
      field: "withContact",
      name: "Add contact:* fields",
      type: "boolean",
      meta: {
        interface: "toggle",
      },
      schema: {
        default_value: false,
      },
    },
    {
      field: "withDeps",
      name: "Add link to other objects",
      type: "boolean",
      meta: {
        interface: "toggle",
      },
      schema: {
        default_value: false,
      },
    },
    {
      field: "withWaypoints",
      name: "Add waypoints",
      type: "boolean",
      meta: {
        interface: "toggle",
      },
      schema: {
        default_value: false,
      },
    },
  ],
}
