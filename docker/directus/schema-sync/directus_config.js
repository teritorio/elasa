/**
 * This file contains the default configuration for the schema exporter.
 *
 * Some possibly sensitive collections are commented out, remove the comments and add filters if needed
 *
 * Uncomment the collection you want to export.
 *
 * These are just some sensible settings, but you might not want to export everything
 *
 * Add custom collections to the syncCustomCollections object in the config.js file.
 */
export const syncDirectusCollections = {
    directus_folders: {
        watch: ['folders'],
        excludeFields: [],
        linkedFields: ['parent'],
        query: {
            filter: {
                id: { _null: true }, // Helper to export nothing
            },
            sort: ['parent', 'id'],
        },
    },
    directus_files: {
        watch: ['files'],
        excludeFields: [],
        query: {
            filter: {
                id: { _null: true }, // Helper to export nothing
                storage: {
                    _eq: 'local',
                },
            }
        },
    },
    directus_roles: {
        watch: ['roles'],
        linkedFields: ['parent'],
        query: {
            filter: {
                id: {
                    _in: ['f400ab71-d9c5-4ea8-96aa-0958f373ccca', '5979e2ac-a34f-4c70-bf9d-de48b3900a8f'],
                },
            },
            sort: ['name'],
        },
    },
    directus_policies: {
        watch: ['policies'],
        query: {
            filter: {
                id: {
                    _in: ['abf8a154-5b1c-4a46-ac9c-7300570f4f17', 'f400ab71-d9c5-4ea8-96aa-0958f373ccca', '5979e2ac-a34f-4c70-bf9d-de48b3900a8f'],
                },
            },
            sort: ['name'],
        },
    },
    directus_permissions: {
        watch: ['permissions', 'collections', 'fields'],
        excludeFields: ['id'],
        getKey: o => `${o.policy}-${o.collection}-${o.action}`,
        query: {
            filter: {
                collection: {
                    _nstarts_with: 'local-',
                },
            },
            sort: ['policy', 'collection', 'action'],
        },
    },
    directus_access: {
        watch: ['access'],
        excludeFields: ['id'],
        getKey: o => `${o.role ?? o.user ?? 'public'}-${o.policy}`,
        query: {
            filter: {
                policy: {
                    _in: ['abf8a154-5b1c-4a46-ac9c-7300570f4f17', 'f400ab71-d9c5-4ea8-96aa-0958f373ccca', '5979e2ac-a34f-4c70-bf9d-de48b3900a8f'],
                },
            },
            sort: ['policy'],
        },
    },
    directus_users: {
        watch: ['users'],
        excludeFields: ['avatar'],
        query: {
            filter: {
                id: {
                    _in: ['7ee01efc-e308-47e8-bf57-3dacd8ba56c5'],
                },
            },
            sort: ['id'],
        },
        // Uncomment this to export the password
        onExport: async (item, itemsSrv) => {
            if (item.password && item.password === '**********') {
                const user = await itemsSrv.knex.select('password').from('directus_users').where('id', item.id).first();
                if (user) {
                    item.password = user.password;
                }
            }
            return item;
        },
        // And then to import the password
        onImport: async (item, itemsSrv) => {
            if (item.password && item.password.startsWith('$argon')) {
                await itemsSrv.knex('directus_users').update('password', item.password).where('id', item.id);
                item.password = '**********';
            }
            return item;
        },
    },
    directus_settings: {
        watch: ['settings'],
        excludeFields: [
            'project_url',
            // always keep these 3 excluded
            'mv_hash', 'mv_ts', 'mv_locked',
        ],
    },
    directus_dashboards: {
        watch: ['dashboards'],
        excludeFields: ['user_created', 'panels'],
    },
    directus_panels: {
        watch: ['panels'],
        excludeFields: ['user_created'],
    },
    directus_presets: {
        watch: ['presets'],
        excludeFields: ['id'],
        getKey: (o) => `${o.role ?? 'all'}-${o.collection}-${o.bookmark || 'default'}`,
        query: {
            id: { _null: true }, // Helper to export nothing
            filter: {
                user: { _null: true }
            }
        }
    },
    directus_flows: {
        watch: ['flows'],
        excludeFields: ['operations', 'user_created'],
        query: {
            id: { _null: true }, // Helper to export nothing
            filter: {
                trigger: { _neq: 'webhook' },
            },
        },
    },
    directus_operations: {
        watch: ['operations'],
        excludeFields: ['user_created'],
        linkedFields: ['resolve', 'reject'],
        query: {
            id: { _null: true }, // Helper to export nothing
            filter: {
                flow: { trigger: { _neq: 'webhook' } },
            },
        },
    },
    directus_translations: {
        watch: ['translations'],
        excludeFields: ['id'],
        getKey: (o) => `${o.key}-${o.language}`,
        query: {
            sort: ['key', 'language'],
        },
    }
};
