--
-- PostgreSQL database dump
--

-- Dumped from database version 13.5 (Debian 13.5-1.pgdg110+1)
-- Dumped by pg_dump version 13.5 (Debian 13.5-1.pgdg110+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: directus_collections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse) FROM stdin;
categorie_sources_cms	\N	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	\N	\N	open
categorie_sources_osm	\N	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	\N	\N	open
categorie_sources_tourinsoft	\N	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	\N	\N	open
categories	\N	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	\N	\N	open
category_filters	\N	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	\N	\N	open
menu_groups	\N	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	\N	\N	open
menu_items	\N	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	\N	\N	open
projects	\N	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	\N	\N	open
property_labels	\N	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	\N	\N	open
sources_cms	\N	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	\N	\N	open
sources_osm	\N	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	\N	\N	open
sources_tourinsoft	\N	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	\N	\N	open
themes	\N	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	\N	\N	open
\.


--
-- Data for Name: directus_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_roles (id, name, icon, description, ip_access, enforce_tfa, admin_access, app_access) FROM stdin;
3645dc7d-5f54-477c-a646-e282f5711615	Administrator	verified	$t:admin_description	\N	f	t	t
\.


--
-- Data for Name: directus_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_users (id, first_name, last_name, email, password, location, title, description, tags, avatar, language, theme, tfa_secret, status, role, token, last_access, last_page, provider, external_identifier, auth_data, email_notifications) FROM stdin;
a7f2a5a2-22e0-46df-9153-606d29ec15b7	Admin	User	admin@example.com	$argon2i$v=19$m=4096,t=3,p=1$BBIJqbLlnz/eTtupPLBCwQ$rc+OFiNvqNt7rjRg4HxNuM4FdRpfu/VZU6E+s/BF+zk	\N	\N	\N	\N	\N	en-US	auto	\N	active	3645dc7d-5f54-477c-a646-e282f5711615	\N	2022-01-04 16:51:42.886+00	/settings/data-model	default	\N	\N	t
\.


--
-- Data for Name: directus_dashboards; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_dashboards (id, name, icon, note, date_created, user_created) FROM stdin;
\.


--
-- Data for Name: directus_fields; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group") FROM stdin;
1	projects	id	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
2	projects	slug	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
3	projects	name	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
4	projects	attributions	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
5	projects	icon_font_css_url	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
6	projects	polygon	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
7	projects	bbox_line	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
8	themes	id	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
9	themes	project_id	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
10	themes	slug	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
11	themes	name	\N	input-code	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
12	themes	description	\N	input-code	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
13	themes	site_url	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
14	themes	main_url	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
15	themes	logo_url	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
16	themes	favicon_url	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
17	projects	themes	o2m	list-o2m	{"template":"{{slug}}"}	related-values	{"template":"{{slug}}"}	f	f	\N	full	\N	\N	\N	f	\N
18	menu_items	id	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
19	menu_items	theme_id	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
20	menu_items	parent_id	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
21	menu_items	index_order	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
22	menu_items	hidden	\N	boolean	\N	boolean	\N	f	f	\N	full	\N	\N	\N	f	\N
23	menu_items	selected_by_default	\N	boolean	\N	boolean	\N	f	f	\N	full	\N	\N	\N	f	\N
24	menu_items	sub_items	o2m	list-o2m-tree-view	{"displayTemplate":"{{category_id}}{{menu_group_id}}"}	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
25	menu_items	category_id	\N	select-dropdown-m2o	{"template":"{{name}}"}	related-values	{"template":"{{name}}"}	f	f	\N	full	\N	\N	\N	f	\N
26	menu_items	menu_group_id	\N	select-dropdown-m2o	{"template":"{{name}}"}	related-values	{"template":"{{name}}"}	f	f	\N	full	\N	\N	\N	f	\N
29	menu_groups	id	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
30	menu_groups	slug	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
31	menu_groups	name	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
32	menu_groups	icon	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
33	menu_groups	color	\N	select-color	\N	color	\N	f	f	\N	full	\N	\N	\N	f	\N
34	menu_groups	tourism_style_class	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
35	menu_groups	display_mode	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
36	categories	id	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
37	categories	slug	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
38	categories	name	\N	input-code	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
39	categories	search_indexed	\N	boolean	\N	boolean	\N	f	f	\N	full	\N	\N	\N	f	\N
40	categories	icon	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
41	categories	color	\N	select-color	\N	color	\N	f	f	\N	full	\N	\N	\N	f	\N
42	categories	tourism_style_class	\N	input-code	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
43	categories	tourism_style_merge	\N	boolean	\N	boolean	\N	f	f	\N	full	\N	\N	\N	f	\N
44	categories	display_mode	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
45	categories	zoom	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
46	category_filters	id	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
47	category_filters	category_id	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
48	category_filters	type	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
49	category_filters	property	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
50	category_filters	values	\N	input-code	\N	\N	\N	t	f	\N	full	\N	\N	\N	f	\N
51	categories	filters	o2m	list-o2m	{"template":"{{property}} ({{type}}) {{values}}"}	related-values	{"template":"{{property}} ({{type}})"}	f	f	\N	full	\N	\N	\N	f	\N
52	sources_tourinsoft	id	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
53	sources_tourinsoft	slug	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
54	sources_tourinsoft	label	\N	input-code	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
55	sources_tourinsoft	label_popup	\N	input-code	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
56	sources_tourinsoft	label_details	\N	input-code	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
57	sources_tourinsoft	popup_properties	\N	input-code	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
58	sources_tourinsoft	details_enable	\N	boolean	\N	boolean	\N	f	f	\N	full	\N	\N	\N	f	\N
59	sources_tourinsoft	url	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
60	sources_tourinsoft	photos_base_url	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
61	sources_osm	id	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
62	sources_osm	slug	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
63	sources_osm	label	\N	input-code	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
64	sources_osm	label_popup	\N	input-code	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
65	sources_osm	label_details	\N	input-code	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
66	sources_osm	popup_properties	\N	input-code	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
67	sources_osm	details_enable	\N	boolean	\N	boolean	\N	f	f	\N	full	\N	\N	\N	f	\N
68	sources_osm	overpass_query	\N	input-code	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
69	sources_osm	map_contrib_theme_url	\N	\N	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
70	sources_osm	extra_tags	\N	input-code	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N
\.


--
-- Data for Name: directus_folders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_folders (id, name, parent) FROM stdin;
\.


--
-- Data for Name: directus_files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_files (id, storage, filename_disk, filename_download, title, type, folder, uploaded_by, uploaded_on, modified_by, modified_on, charset, filesize, width, height, duration, embed, description, location, tags, metadata) FROM stdin;
\.


--
-- Data for Name: directus_notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_notifications (id, "timestamp", status, recipient, sender, subject, message, collection, item) FROM stdin;
\.


--
-- Data for Name: directus_panels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_panels (id, dashboard, name, icon, color, show_header, note, type, position_x, position_y, width, height, options, date_created, user_created) FROM stdin;
\.


--
-- Data for Name: directus_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_permissions (id, role, collection, action, permissions, validation, presets, fields) FROM stdin;
\.


--
-- Data for Name: directus_presets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_presets (id, bookmark, "user", role, collection, search, layout, layout_query, layout_options, refresh_interval, filter) FROM stdin;
1	\N	a7f2a5a2-22e0-46df-9153-606d29ec15b7	\N	categories	toi	\N	{"tabular":{"page":1}}	\N	\N	\N
\.


--
-- Data for Name: directus_relations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_relations (id, many_collection, many_field, one_collection, one_field, one_collection_field, one_allowed_collections, junction_field, sort_field, one_deselect_action) FROM stdin;
1	themes	project_id	projects	themes	\N	\N	\N	\N	nullify
2	menu_items	parent_id	menu_items	sub_items	\N	\N	\N	\N	nullify
3	category_filters	category_id	categories	filters	\N	\N	\N	\N	nullify
\.


--
-- Data for Name: directus_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_settings (id, project_name, project_url, project_color, project_logo, public_foreground, public_background, public_note, auth_login_attempts, auth_password_policy, storage_asset_transform, storage_asset_presets, custom_css, storage_default_folder, basemaps, mapbox_key, module_bar) FROM stdin;
\.


--
-- Data for Name: directus_shares; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_shares (id, name, collection, item, role, password, user_created, date_created, date_start, date_end, times_used, max_uses) FROM stdin;
\.


--
-- Data for Name: directus_webhooks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_webhooks (id, name, method, url, status, data, actions, collections, headers) FROM stdin;
\.


--
-- Name: directus_activity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_activity_id_seq', 1, true);


--
-- Name: directus_fields_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_fields_id_seq', 70, true);


--
-- Name: directus_notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_notifications_id_seq', 1, false);


--
-- Name: directus_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_permissions_id_seq', 1, false);


--
-- Name: directus_presets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_presets_id_seq', 1, true);


--
-- Name: directus_relations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_relations_id_seq', 3, true);


--
-- Name: directus_revisions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_revisions_id_seq', 1, true);


--
-- Name: directus_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_settings_id_seq', 1, false);


--
-- Name: directus_webhooks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_webhooks_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

