export default {
  id: 'create-local-codes',
  name: 'Create Local Codes',
  icon: 'list',
  description: 'Create a local code table for one project',

  overview: ({ tableName }) => [{ label: 'Codes Table Name', text: tableName || '-' }],

  options: [
    {
      field: 'tableName',
      name: 'Codes Table Name',
      type: 'string',
      meta: {
        interface: 'input',
        width: 'full',
      },
      schema: {
        default_value: null,
      },
    },
  ],
};
