INSERT INTO public.directus_translations (id, language, key, value) VALUES
('a0791909-d451-4d11-8a39-3277f99f94a6', 'fr-FR', 'amenity', 'Équipement de proximité'),
('ae0a22aa-e9b6-4ab8-ba82-05c6823cdeb7', 'fr-FR', 'catering', 'Restauration'),
('ac65604b-4f4b-4680-9b90-86ffe6c5c0e7', 'fr-FR', 'craft', 'Artisanat / artisans'),
('a4334f3b-3368-44ab-a9de-97c2aadea155', 'fr-FR', 'education', 'Éducation'),
('0841004e-0746-4d3b-beca-13474fc82b4f', 'fr-FR', 'remarkable', 'Éléments notables'),
('c7fd502d-395e-4605-911f-1f1255237692', 'fr-FR', 'safety', 'Santé'),
('e86a9a44-5f25-492d-814b-bf2644b0f573', 'fr-FR', 'services', 'Services de proximité'),
('00ab2799-acb0-4749-8165-ddb8c725f27f', 'fr-FR', 'services_shopping', 'Commerces de services'),
('d2e1c9fb-c16b-4a2c-8584-0de6f7ee0847', 'fr-FR', 'shopping', 'Commerces'),
('d7f14cbf-66db-4171-833a-60c8a9e20910', 'fr-FR', 'social_services', 'Services sociaux'),
('1ec8f3b6-787e-4408-a592-e4863cdc81d2', 'fr-FR', 'nature', 'Nature'),
('6a4527e0-d74f-4d4f-ae85-5f4d03e97872', 'fr-FR', 'leisure', 'Loisirs'),
('7d1f256c-f74e-4242-b944-bc329d2d657a', 'fr-FR', 'culture_shopping', 'Commerces Culturel'),
('12c61fea-717c-4db2-af0d-34a25b14f390', 'fr-FR', 'mobility', 'Mobilité'),
('84d86a93-729f-4d2e-91ba-c63539cc7f16', 'fr-FR', 'local_shop', 'Commerces de proximité (alim)'),
('518fdee0-efb9-407c-9c19-b60c2036c647', 'fr-FR', 'hosting', 'Hébergement'),
('6579bb86-0540-417f-b2e4-1235f48d3359', 'fr-FR', 'products', 'Produit locaux (alim)'),
('99366eac-bb28-49d1-9e36-51b9ec568936', 'fr-FR', 'culture', 'Culture et patrimoine'),
('260e33f3-b5dd-407a-b686-b33215b81442', 'fr-FR', 'public_landmark', 'Point de repère du territoire');

UPDATE directus_fields
SET options = '{"presets":[{"name":"$t:amenity","color":"#2A62AC"},{"name":"$t:catering","color":"#F5B700"},{"name":"$t:local_shop","color":"#00B3CC"},{"name":"$t:craft","color":"#C58511"},{"name":"$t:culture","color":"#76009E"},{"name":"$t:culture_shopping","color":"#A16CB3"},{"name":"$t:education","color":"#4076F6"},{"name":"$t:hosting","color":"#99163A"},{"name":"$t:leisure","color":"#00A757"},{"name":"$t:mobility","color":"#008ECF"},{"name":"$t:nature","color":"#8CC56F"},{"name":"$t:products","color":"#F25C05"},{"name":"$t:public_landmark","color":"#1D1D1B"},{"name":"$t:remarkable","color":"#E50980"},{"name":"$t:safety","color":"#E42224"},{"name":"$t:services","color":"#2A62AC"},{"name":"$t:services_shopping","color":"#7093C3"},{"name":"$t:shopping","color":"#808080"},{"name":"$t:social_services","color":"#006660"}]}'::jsonb
WHERE id = 78;

UPDATE directus_fields
SET options = '{"presets":[{"name":"$t:amenity","color":"#2A62AC"},{"name":"$t:catering","color":"#F09007"},{"name":"$t:local_shop","color":"#00A0C4"},{"name":"$t:craft","color":"#C58511"},{"name":"$t:culture","color":"#76009E"},{"name":"$t:culture_shopping","color":"#76009E"},{"name":"$t:education","color":"#4076F6"},{"name":"$t:hosting","color":"#99163A"},{"name":"$t:leisure","color":"#00A757"},{"name":"$t:mobility","color":"#3B74B9"},{"name":"$t:nature","color":"#70B06A"},{"name":"$t:products","color":"#F25C05"},{"name":"$t:public_landmark","color":"#1D1D1B"},{"name":"$t:remarkable","color":"#E50980"},{"name":"$t:safety","color":"#E42224"},{"name":"$t:services","color":"#2A62AC"},{"name":"$t:services_shopping","color":"#2A62AC"},{"name":"$t:shopping","color":"#808080"},{"name":"$t:social_services","color":"#006660"}]}'::jsonb
WHERE id = 79;
