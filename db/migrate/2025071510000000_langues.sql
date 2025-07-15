INSERT INTO languages(code, name, direction) VALUES ('pt-PT', 'Portuguese', 'ltr') ON CONFLICT DO NOTHING;
INSERT INTO languages(code, name, direction) VALUES ('it-IT', 'Italian', 'ltr') ON CONFLICT DO NOTHING;
INSERT INTO languages(code, name, direction) VALUES ('nl-NL', 'Dutch', 'ltr') ON CONFLICT DO NOTHING;
INSERT INTO languages(code, name, direction) VALUES ('de-DE', 'German', 'ltr') ON CONFLICT DO NOTHING;
