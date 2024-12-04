UPDATE directus_flows
SET options = '{"collections":["sources"],"requireConfirmation":true,"fields":[{"field":"withImages","type":"boolean","name":"With Images","meta":{"interface":"boolean"}},{"field":"withTranslations","type":"boolean","name":"With Translations","meta":{"interface":"boolean"}},{"field":"withName","type":"boolean","name":"With Name","meta":{"interface":"boolean"}},{"field":"withDescription","type":"boolean","name":"With Description","meta":{"interface":"boolean"}},{"field":"withAddr","type":"boolean","name":"Add addr:* fields","meta":{"interface":"boolean"}},{"field":"withContact","name":"Add contact:* fields","type":"boolean","meta":{"interface":"boolean"}}]}'::jsonb
WHERE id = '96ccf7a5-8702-4760-8c9e-b53267f234b2'::uuid;

UPDATE directus_operations
SET options = '{"withImages":"{{$trigger.body.withImages}}","withTranslations":"{{$trigger.body.withTranslations}}","withName":"{{$trigger.body.withName}}","withDescription":"{{$trigger.body.withDescription}}","withAddr":"{{$trigger.body.withAddr}}","withContact":"{{$trigger.body.withContact}}"}'::jsonb
WHERE id = 'bbcfb368-cce2-4dc0-b5b1-9ba49a893da8'::uuid;
