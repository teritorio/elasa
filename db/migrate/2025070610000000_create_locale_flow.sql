UPDATE
    directus_flows
SET
    options = '{"collections":["sources"],"requireConfirmation":true,"fields":[{"field":"withImages","type":"boolean","name":"With Images","meta":{"interface":"boolean","width":"half"}},{"field":"withThumbnail","type":"boolean","name":"With Thumbnail","meta":{"interface":"boolean","options":{"iconOn":"image_search"},"width":"half"}},{"field":"withName","type":"boolean","name":"With Name","meta":{"interface":"boolean","width":"half"}},{"field":"withDescription","type":"boolean","name":"With Description","meta":{"interface":"boolean","width":"half"}},{"field":"withAddr","type":"boolean","name":"Add addr:* fields","meta":{"interface":"boolean","width":"half"}},{"field":"withContact","type":"boolean","name":"Add contact:* fields","meta":{"interface":"boolean","width":"half"}},{"field":"withDeps","type":"boolean","name":"Add link to other objects","meta":{"interface":"boolean","width":"half"}},{"field":"withWaypoints","type":"boolean","name":"Add waypoints","meta":{"interface":"boolean","width":"half"}}]}'::json
WHERE
    id = '96ccf7a5-8702-4760-8c9e-b53267f234b2'
;

UPDATE
    directus_operations
SET
    options = '{"withImages":"{{$trigger.body.withImages}}","withThumbnail":"{{$trigger.body.withThumbnail}}","withName":"{{$trigger.body.withName}}","withDescription":"{{$trigger.body.withDescription}}","withAddr":"{{$trigger.body.withAddr}}","withContact":"{{$trigger.body.withContact}}","withDeps":"{{$trigger.body.withDeps}}","withWaypoints":"{{$trigger.body.withWaypoints}}","withTranslations":"{{$trigger.body.withTranslations}}"}'::json
WHERE
    id = 'bbcfb368-cce2-4dc0-b5b1-9ba49a893da8'
;
