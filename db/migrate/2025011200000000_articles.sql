ALTER TABLE projects DROP COLUMN articles;
DELETE FROM directus_fields WHERE id=152;

UPDATE directus_collections SET sort = 3 WHERE collection = 'map';
UPDATE directus_collections SET sort = 4 WHERE collection = 'filters';
UPDATE directus_collections SET sort = 5 WHERE collection = 'sell';
UPDATE directus_collections SET sort = 7 WHERE collection = 'sources';

INSERT INTO directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url, versioning) VALUES
('articles', 'article', NULL, '{{article_translations.title}}', FALSE, FALSE, NULL, NULL, TRUE, NULL, NULL, NULL, 'all', NULL, NULL, 6, 'projects', 'open', NULL, FALSE),
('articles_translations', 'import_export', NULL, NULL, TRUE, FALSE, NULL, NULL, TRUE, NULL, NULL, NULL, 'all', NULL, NULL, 1, 'articles', 'open', NULL, FALSE),
('projects_articles', 'import_export', NULL, NULL, TRUE, FALSE, NULL, NULL, TRUE, NULL, NULL, NULL, 'all', NULL, NULL, 2, 'projects', 'open', NULL, FALSE);


UPDATE directus_fields
SET id = id + 10000
WHERE id >= 562;
SELECT pg_catalog.setval('directus_fields_id_seq', (SELECT MAX(id) FROM directus_fields), true);

INSERT INTO directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message) VALUES
(562, 'articles', 'id', NULL, 'input', NULL, NULL, NULL, true, true, 1, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
(565, 'articles', 'article_translations', 'translations', 'translations', '{"defaultOpenSplitView":true,"defaultLanguage":"en-US","userLanguage":true}', NULL, NULL, false, false, 3, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
(566, 'articles_translations', 'id', NULL, NULL, NULL, NULL, NULL, false, true, 1, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
(567, 'articles_translations', 'articles_id', NULL, NULL, NULL, NULL, NULL, false, true, 2, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
(568, 'articles_translations', 'languages_code', NULL, NULL, NULL, NULL, NULL, false, true, 3, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
(569, 'articles_translations', 'title', NULL, 'input', NULL, NULL, NULL, false, false, 4, 'full', NULL, NULL, NULL, true, NULL, NULL, NULL),
(570, 'articles_translations', 'slug', NULL, 'input', NULL, NULL, NULL, false, false, 5, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
(571, 'articles_translations', 'body', NULL, 'input-rich-text-html', '{"toolbar":["undo","redo","bold","italic","underline","h1","h2","h3","numlist","bullist","removeformat","cut","copy","paste","blockquote","customLink","customImage","customMedia","hr","code","fullscreen"],"tinymceOverrides":{"entity_encoding":"raw"}}', NULL, NULL, false, false, 6, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
(572, 'articles', 'project_id', 'm2o', 'select-dropdown-m2o', NULL, NULL, NULL, false, true, 2, 'full', NULL, NULL, NULL, true, NULL, NULL, NULL),
(573, 'projects', 'articles', 'm2m', 'list-m2m', '{"filter":{"_and":[{"project_id":{"id":{"_eq":"{{id}}"}}}]}}', NULL, NULL, false, false, 9, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
(574, 'projects_articles', 'id', NULL, NULL, NULL, NULL, NULL, false, true, 1, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
(575, 'projects_articles', 'projects_id', NULL, NULL, NULL, NULL, NULL, false, true, 2, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
(576, 'projects_articles', 'articles_id', NULL, NULL, NULL, NULL, NULL, false, true, 3, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL),
(577, 'projects_articles', 'index', NULL, 'input', NULL, NULL, NULL, false, true, 4, 'full', NULL, NULL, NULL, false, NULL, NULL, NULL);

UPDATE directus_relations
SET id = id + 10000
WHERE id >= 71;
SELECT pg_catalog.setval('directus_relations_id_seq', (SELECT MAX(id) FROM directus_relations), true);

INSERT INTO directus_relations (id, many_collection, many_field, one_collection, one_field, one_collection_field, one_allowed_collections, junction_field, sort_field, one_deselect_action) VALUES
(71, 'articles_translations', 'languages_code', 'languages', NULL, NULL, NULL, 'articles_id', NULL, 'nullify'),
(72, 'articles_translations', 'articles_id', 'articles', 'article_translations', NULL, NULL, 'languages_code', NULL, 'delete'),
(73, 'articles', 'project_id', 'projects', NULL, NULL, NULL, NULL, NULL, 'nullify'),
(74, 'projects_articles', 'articles_id', 'articles', NULL, NULL, NULL, 'projects_id', NULL, 'nullify'),
(75, 'projects_articles', 'projects_id', 'projects', 'articles', NULL, NULL, 'articles_id', 'index', 'delete');

UPDATE directus_permissions
SET id = id + 10000
WHERE id >= 242;
SELECT pg_catalog.setval('directus_permissions_id_seq', (SELECT MAX(id) FROM directus_permissions), true);

COPY public.directus_permissions (id, collection, action, permissions, validation, presets, fields, policy) FROM stdin;
242	articles	create	\N	\N	\N	*	5979e2ac-a34f-4c70-bf9d-de48b3900a8f
243	articles_translations	create	\N	\N	\N	*	5979e2ac-a34f-4c70-bf9d-de48b3900a8f
244	projects_articles	create	\N	\N	\N	*	5979e2ac-a34f-4c70-bf9d-de48b3900a8f
245	articles	read	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	*	5979e2ac-a34f-4c70-bf9d-de48b3900a8f
246	articles	update	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	*	5979e2ac-a34f-4c70-bf9d-de48b3900a8f
247	articles	delete	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	\N	5979e2ac-a34f-4c70-bf9d-de48b3900a8f
248	articles_translations	read	{"_and":[{"articles_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	*	5979e2ac-a34f-4c70-bf9d-de48b3900a8f
249	articles_translations	update	{"_and":[{"articles_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	*	5979e2ac-a34f-4c70-bf9d-de48b3900a8f
250	articles_translations	delete	{"_and":[{"articles_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	\N	5979e2ac-a34f-4c70-bf9d-de48b3900a8f
251	projects_articles	read	{"_and":[{"projects_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	*	5979e2ac-a34f-4c70-bf9d-de48b3900a8f
252	projects_articles	update	{"_and":[{"projects_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	*	5979e2ac-a34f-4c70-bf9d-de48b3900a8f
253	projects_articles	delete	{"_and":[{"projects_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	\N	5979e2ac-a34f-4c70-bf9d-de48b3900a8f
\.


--
-- Name: articles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.articles (
    id integer NOT NULL,
    project_id integer
);


ALTER TABLE public.articles OWNER TO postgres;

--
-- Name: articles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.articles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.articles_id_seq OWNER TO postgres;

--
-- Name: articles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.articles_id_seq OWNED BY public.articles.id;


--
-- Name: articles_translations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.articles_translations (
    id integer NOT NULL,
    articles_id integer NOT NULL,
    languages_code character varying(255),
    title character varying(255),
    slug character varying(255),
    body text
);


ALTER TABLE public.articles_translations OWNER TO postgres;

--
-- Name: articles_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.articles_translations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.articles_translations_id_seq OWNER TO postgres;

--
-- Name: articles_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.articles_translations_id_seq OWNED BY public.articles_translations.id;


--
-- Name: projects_articles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_articles (
    id integer NOT NULL,
    projects_id integer,
    articles_id integer,
    index integer
);


ALTER TABLE public.projects_articles OWNER TO postgres;

--
-- Name: projects_articles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_articles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_articles_id_seq OWNER TO postgres;

--
-- Name: projects_articles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_articles_id_seq OWNED BY public.projects_articles.id;


--
-- Name: articles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles ALTER COLUMN id SET DEFAULT nextval('public.articles_id_seq'::regclass);


--
-- Name: articles_translations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles_translations ALTER COLUMN id SET DEFAULT nextval('public.articles_translations_id_seq'::regclass);


--
-- Name: projects_articles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_articles ALTER COLUMN id SET DEFAULT nextval('public.projects_articles_id_seq'::regclass);


--
-- Name: articles articles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_pkey PRIMARY KEY (id);


--
-- Name: articles_translations articles_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles_translations
    ADD CONSTRAINT articles_translations_pkey PRIMARY KEY (id);


--
-- Name: articles_translations articles_translations_uniq_articles_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles_translations
    ADD CONSTRAINT articles_translations_uniq_articles_id UNIQUE (articles_id, languages_code);


--
-- Name: projects_articles projects_articles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_articles
    ADD CONSTRAINT projects_articles_pkey PRIMARY KEY (id);


--
-- Name: articles articles_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_project_id_foreign FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;


--
-- Name: articles_translations articles_translations_articles_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles_translations
    ADD CONSTRAINT articles_translations_articles_id_foreign FOREIGN KEY (articles_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: articles_translations articles_translations_languages_code_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles_translations
    ADD CONSTRAINT articles_translations_languages_code_foreign FOREIGN KEY (languages_code) REFERENCES public.languages(code) ON DELETE CASCADE;


--
-- Name: projects_articles projects_articles_articles_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_articles
    ADD CONSTRAINT projects_articles_articles_id_foreign FOREIGN KEY (articles_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: projects_articles projects_articles_projects_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_articles
    ADD CONSTRAINT projects_articles_projects_id_foreign FOREIGN KEY (projects_id) REFERENCES public.projects(id) ON DELETE CASCADE;
