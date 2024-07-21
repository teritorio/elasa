--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1 (Debian 16.1-1.pgdg110+1)
-- Dumped by pg_dump version 16.1 (Debian 16.1-1.pgdg110+1)

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

COPY public.directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url, versioning) FROM stdin;
fields	rectangle	\N	{{field}}{{group}}	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	4	projects	open	\N	f
fields_fields	import_export	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	6	\N	open	\N	f
filters	filter_alt	\N	{{type}}{{name}}	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	3	projects	open	\N	f
filters_translations	import_export	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	1	filters	open	\N	f
junction_directus_roles_undefined	import_export	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	1	\N	open	\N	f
languages	\N	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	7	\N	open	\N	f
menu_items	menu	\N	{{type}}{{slug}}{{name}}	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	2	themes	open	\N	f
menu_items_childrens	import_export	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	3	\N	open	\N	f
menu_items_filters	import_export	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	5	\N	open	\N	f
menu_items_sources	import_export	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	4	\N	open	\N	f
menu_items_translations	import_export	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	1	menu_items	open	\N	f
pois	pin_drop	\N	{{properties}}	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	2	sources	open	\N	f
projects	house	\N	{{slug}}	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	2	\N	open	{{slug}}	f
projects_translations	import_export	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	1	projects	open	\N	f
sources	database	\N	{{slug}}	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	5	projects	open	\N	f
sources_translations	import_export	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	1	sources	open	\N	f
themes	map	\N	{{slug}}	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	2	projects	open	\N	f
themes_translations	import_export	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	1	themes	open	\N	f
translations	\N	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	6	projects	open	\N	f
\.


--
-- Data for Name: directus_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_roles (id, name, icon, description, ip_access, enforce_tfa, admin_access, app_access) FROM stdin;
f400ab71-d9c5-4ea8-96aa-0958f373ccca	Administrator	verified	$t:admin_description	\N	f	t	t
5979e2ac-a34f-4c70-bf9d-de48b3900a8f	Local Admin	supervised_user_circle	\N	\N	f	f	t
\.


--
-- Data for Name: directus_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_users (id, first_name, last_name, email, password, location, title, description, tags, avatar, language, tfa_secret, status, role, token, last_access, last_page, provider, external_identifier, auth_data, email_notifications, project_id, appearance, theme_dark, theme_light, theme_light_overrides, theme_dark_overrides) FROM stdin;
7ee01efc-e308-47e8-bf57-3dacd8ba56c5	Admin	User	admin@example.com	$argon2id$v=19$m=65536,t=3,p=4$qS/yUxvrtrTXACg+65QTTQ$5xe8tFtiM/tsoP+k0SjMLTQMc/lKuC1QUOyCM7Mm+kc	\N	\N	\N	\N	\N	\N	\N	active	f400ab71-d9c5-4ea8-96aa-0958f373ccca	\N	2023-10-04 17:26:45.716+00	/settings/roles/	default	\N	\N	t	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: directus_dashboards; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_dashboards (id, name, icon, note, date_created, user_created, color) FROM stdin;
\.


--
-- Data for Name: directus_extensions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_extensions (enabled, id, folder, source, bundle) FROM stdin;
\.


--
-- Data for Name: directus_fields; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message) FROM stdin;
2	junction_directus_roles_undefined	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
3	junction_directus_roles_undefined	directus_roles_id	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
4	junction_directus_roles_undefined	item	\N	\N	\N	\N	\N	f	t	3	full	\N	\N	\N	f	\N	\N	\N
5	junction_directus_roles_undefined	collection	\N	\N	\N	\N	\N	f	t	4	full	\N	\N	\N	f	\N	\N	\N
6	projects	polygon	\N	\N	\N	formatted-json-value	\N	f	f	7	full	\N	\N	\N	f	\N	\N	\N
7	themes	project_id	\N	select-dropdown-m2o	\N	related-values	{"template":"{{slug}}"}	t	f	2	full	\N	\N	\N	f	\N	\N	\N
8	themes	slug	\N	\N	\N	\N	\N	f	f	4	full	\N	\N	\N	f	\N	\N	\N
13	themes	logo_url	\N	\N	\N	\N	\N	f	f	7	full	\N	\N	\N	f	\N	\N	\N
14	themes	favicon_url	\N	\N	\N	\N	\N	f	f	8	full	\N	\N	\N	f	\N	\N	\N
15	themes	id	\N	\N	\N	\N	\N	t	t	1	full	\N	\N	\N	f	\N	\N	\N
16	projects	themes	o2m	list-o2m	\N	\N	\N	f	f	5	full	\N	\N	\N	f	\N	\N	\N
17	projects	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
20	projects	attributions	\N	\N	\N	\N	\N	f	f	5	full	\N	\N	\N	f	\N	\N	\N
21	projects	icon_font_css_url	\N	\N	\N	\N	\N	f	f	6	full	\N	\N	\N	f	\N	\N	\N
22	projects	bbox_line	\N	\N	\N	\N	\N	f	t	8	full	\N	\N	\N	f	\N	\N	\N
23	sources	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
24	sources	project_id	\N	select-dropdown-m2o	{"template":"{{slug}}"}	related-values	{"template":"{{slug}}"}	f	t	2	full	\N	\N	\N	f	\N	\N	\N
25	sources	slug	\N	\N	\N	\N	\N	f	f	4	full	\N	\N	\N	f	\N	\N	\N
27	sources	attribution	\N	\N	\N	\N	\N	f	f	6	full	\N	\N	\N	f	\N	\N	\N
29	directus_users	project_id	m2o	select-dropdown-m2o	{"template":"{{slug}}"}	\N	\N	f	f	1	full	\N	\N	\N	f	\N	\N	\N
35	menu_items_childrens	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
36	menu_items_childrens	menu_items_id	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
37	menu_items_childrens	item	\N	\N	\N	\N	\N	f	t	3	full	\N	\N	\N	f	\N	\N	\N
38	menu_items_childrens	collection	\N	\N	\N	\N	\N	f	t	4	full	\N	\N	\N	f	\N	\N	\N
40	menu_items	menu_item_parent_id	\N	select-dropdown-m2o	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
41	menu_items	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
46	menu_items	items	o2m	list-o2m-tree-view	{"displayTemplate":"{{type}} {{menu_items_translations.name}} "}	\N	{"template":"{{id}}"}	f	f	1	full	\N	\N	\N	f	menu_group	\N	\N
47	menu_items	parent_id	\N	select-dropdown-m2o	\N	\N	\N	f	t	7	full	\N	\N	\N	f	\N	\N	\N
49	themes	root_menu_item_id	m2o	select-dropdown-m2o	{"template":"{{type}}{{slug}}{{name}}"}	related-values	{"template":"{{type}}{{slug}}{{name}}"}	f	f	9	full	\N	\N	\N	f	\N	\N	\N
53	menu_items	theme_id	m2o	select-dropdown-m2o	\N	\N	\N	f	f	6	full	\N	\N	\N	t	\N	\N	\N
54	menu_items	index_order	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
55	menu_items	hidden	\N	\N	\N	\N	\N	f	f	1	half	\N	\N	\N	f	behavior	\N	\N
56	menu_items	selected_by_default	\N	\N	\N	\N	\N	f	f	2	half	\N	\N	\N	f	behavior	\N	\N
62	menu_items	icon	\N	input	\N	\N	\N	f	f	4	half	\N	\N	\N	t	UI	\N	\N
65	menu_items	UI	alias,no-data,group	group-detail	\N	\N	\N	f	f	9	full	\N	\N	\N	f	\N	\N	\N
66	menu_items	behavior	alias,no-data,group	group-detail	\N	\N	\N	f	f	8	full	\N	\N	\N	f	\N	\N	\N
67	menu_items	display_mode	\N	\N	\N	\N	\N	f	f	1	full	\N	\N	\N	f	UI	\N	\N
68	menu_items	category	alias,no-data,group	group-detail	\N	\N	\N	f	f	2	full	\N	\N	[{"rule":{"_and":[{"type":{"_neq":"category"}}]},"hidden":true,"options":{"start":"open"}}]	f	accordion-xkp6bl	\N	\N
69	menu_items	search_indexed	cast-boolean	boolean	\N	\N	\N	f	f	3	half	\N	\N	\N	f	category	\N	\N
71	menu_items	style_merge	cast-boolean	boolean	\N	\N	\N	f	f	4	half	\N	\N	\N	f	category	\N	\N
73	menu_items	zoom	\N	slider	{"minValue":12,"maxValue":18}	\N	\N	f	f	6	half	\N	\N	\N	f	category	\N	\N
74	menu_items	sources	m2m	list-m2m	{"template":"{{sources_id.slug}}"}	\N	\N	f	f	1	full	\N	\N	\N	f	category	\N	\N
75	menu_items_sources	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
76	menu_items_sources	menu_items_id	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
77	menu_items_sources	sources_id	\N	\N	\N	\N	\N	f	t	3	full	\N	\N	\N	f	\N	\N	\N
78	menu_items	color_fill	\N	select-color	\N	\N	\N	f	f	2	half	\N	\N	\N	f	UI	\N	\N
79	menu_items	color_line	\N	select-color	\N	\N	\N	f	f	3	half	\N	\N	\N	f	UI	\N	\N
80	menu_items	link	alias,no-data,group	group-detail	\N	\N	\N	f	f	3	full	\N	\N	[{"rule":{"_and":[{"type":{"_neq":"link"}}]},"hidden":true,"options":{"start":"open"}}]	f	accordion-xkp6bl	\N	\N
81	menu_items	href	\N	input	\N	\N	\N	f	f	1	full	\N	\N	\N	f	link	\N	\N
82	filters	id	\N	input	\N	\N	\N	t	t	1	full	\N	\N	\N	f	\N	\N	\N
83	filters	type	\N	select-dropdown	{"choices":[{"text":"multiselection","value":"multiselection"},{"text":"checkboxes_list","value":"checkboxes_list"},{"text":"boolean","value":"boolean"},{"text":"date_range","value":"date_range"},{"text":"number_range","value":"number_range"}]}	\N	\N	f	f	5	full	\N	\N	\N	t	\N	\N	\N
86	filters	property_end	\N	input	\N	\N	\N	f	f	2	full	\N	\N	\N	f	date_range	\N	\N
87	filters	property_begin	\N	input	\N	\N	\N	f	f	1	full	\N	\N	\N	f	date_range	\N	\N
88	filters	date_range	alias,no-data,group	group-detail	\N	\N	\N	f	f	4	full	\N	\N	[{"rule":{"_and":[{"type":{"_neq":"date_range"}}]},"hidden":true,"options":{"start":"open"}}]	f	accordion-ysehx-	\N	\N
89	filters	number_range	alias,no-data,group	group-detail	\N	\N	\N	f	f	5	full	\N	\N	[{"rule":{"_and":[{"type":{"_neq":"number_range"}}]},"hidden":true,"options":{"start":"open"}}]	f	accordion-ysehx-	\N	\N
90	filters	min	\N	input	\N	\N	\N	f	f	2	full	\N	\N	\N	f	number_range	\N	\N
91	filters	max	\N	input	\N	\N	\N	f	f	3	full	\N	\N	\N	f	number_range	\N	\N
98	filters	project_id	m2o	select-dropdown-m2o	\N	\N	\N	f	f	4	full	\N	\N	\N	t	\N	\N	\N
107	menu_items	filters	m2m	list-m2m	\N	\N	\N	f	f	8	full	\N	\N	\N	f	category	\N	\N
108	menu_items_filters	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
109	menu_items_filters	menu_items_id	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
110	menu_items_filters	filters_id	\N	\N	\N	\N	\N	f	t	3	full	\N	\N	\N	f	\N	\N	\N
111	menu_items	accordion-xkp6bl	alias,no-data,group	group-accordion	{"start":"first"}	\N	\N	f	f	11	full	\N	\N	\N	f	\N	\N	\N
112	menu_items	menu_group	alias,no-data,group	group-detail	\N	\N	\N	f	f	1	full	\N	\N	[{"rule":{"_and":[{"type":{"_neq":"menu_group"}}]},"hidden":true,"options":{"start":"open"}}]	f	accordion-xkp6bl	\N	\N
113	filters	accordion-ysehx-	alias,no-data,group	group-accordion	{"start":"first"}	\N	\N	f	f	6	full	\N	\N	\N	f	\N	\N	\N
114	filters	multiselection	alias,no-data,group	group-detail	\N	\N	\N	f	f	1	full	\N	\N	[{"rule":{"_and":[{"type":{"_neq":"multiselection"}}]},"hidden":true,"options":{"start":"open"}}]	f	accordion-ysehx-	\N	\N
115	filters	checkboxes_list	alias,no-data,group	group-detail	\N	\N	\N	f	f	2	full	\N	\N	[{"rule":{"_and":[{"type":{"_neq":"checkboxes_list"}}]},"hidden":true,"options":{"start":"open"}}]	f	accordion-ysehx-	\N	\N
116	filters	boolean	alias,no-data,group	group-detail	\N	\N	\N	f	f	3	full	\N	\N	[{"rule":{"_and":[{"type":{"_neq":"boolean"}}]},"hidden":true,"options":{"start":"open"}}]	f	accordion-ysehx-	\N	\N
117	filters	multiselection_property	\N	input	\N	\N	\N	f	f	1	full	\N	\N	\N	f	multiselection	\N	\N
118	filters	checkboxes_list_property	\N	input	\N	\N	\N	f	f	1	full	\N	\N	\N	f	checkboxes_list	\N	\N
119	filters	boolean_property	\N	input	\N	\N	\N	f	f	1	full	\N	\N	\N	f	boolean	\N	\N
120	filters	number_range_property	\N	input	\N	\N	\N	f	f	1	full	\N	\N	\N	f	number_range	\N	\N
121	pois	id	\N	\N	\N	\N	\N	f	f	1	full	\N	\N	\N	f	\N	\N	\N
123	pois	geom	geometry	\N	\N	\N	\N	f	f	4	full	\N	\N	\N	f	\N	\N	\N
124	pois	properties	cast-json	\N	\N	\N	\N	f	f	5	full	\N	\N	\N	f	\N	\N	\N
125	pois	source_id	m2o	select-dropdown-m2o	{"template":"{{slug}}"}	related-values	{"template":"{{slug}}"}	f	f	2	full	\N	\N	\N	f	\N	\N	\N
126	sources	pois	o2m	list-o2m	{"enableLink":true}	\N	\N	f	f	7	full	\N	\N	\N	f	\N	\N	\N
127	menu_items	style_class_string	\N	input	\N	\N	\N	f	f	5	half	\N	\N	\N	f	category	\N	\N
128	menu_items	style_class	\N	\N	\N	\N	\N	f	t	7	full	\N	\N	\N	f	category	\N	\N
131	projects	slug	\N	input	\N	\N	\N	f	f	3	full	\N	\N	\N	t	\N	\N	\N
132	menu_items	type	\N	select-dropdown	{"choices":[{"text":"menu_group","value":"menu_group"},{"text":"category","value":"category"},{"text":"link","value":"link"},{"text":"search","value":"search"}]}	\N	\N	f	f	10	full	\N	\N	\N	t	\N	\N	\N
133	fields	id	\N	input	\N	\N	\N	t	t	1	full	\N	\N	\N	f	\N	\N	\N
134	fields	type	\N	select-dropdown	{"choices":[{"text":"field","value":"field"},{"text":"group","value":"group"}]}	\N	\N	f	f	2	full	\N	\N	\N	f	\N	\N	\N
135	fields	accordion-9juoos	alias,no-data,group	group-accordion	\N	\N	\N	f	f	3	full	\N	\N	\N	f	\N	\N	\N
136	fields	field	\N	input	\N	\N	\N	f	f	1	full	\N	\N	[{"rule":{"_and":[{"type":{"_neq":"field"}}]},"hidden":true,"options":{"font":"sans-serif","trim":false,"masked":false,"clear":false,"slug":false}}]	f	accordion-9juoos	\N	\N
138	fields	group	\N	input	\N	\N	\N	f	f	1	full	\N	\N	\N	f	group_block	\N	\N
139	fields	display_mode	\N	select-dropdown	{"choices":[{"text":"standard","value":"standard"},{"text":"card","value":"card"}]}	\N	\N	f	f	2	full	\N	\N	\N	f	group_block	\N	\N
140	fields	icon	\N	input	\N	\N	\N	f	f	3	half	\N	\N	\N	f	group_block	\N	\N
141	fields	group_block	alias,no-data,group	group-detail	\N	\N	\N	f	f	2	full	\N	\N	[{"rule":{"_and":[{"type":{"_neq":"group"}}]},"hidden":true,"options":{"start":"open"}}]	f	accordion-9juoos	\N	\N
144	fields	fields	m2m	list-m2m	{"template":"{{related_fields_id.type}} {{related_fields_id.field}}{{related_fields_id.group}}","enableLink":true}	related-values	{"template":"{{related_fields_id.type}}{{related_fields_id.field}}{{related_fields_id.group}}"}	f	f	5	full	\N	\N	\N	f	group_block	\N	\N
145	fields_fields	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
146	fields_fields	fields_id	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
147	fields_fields	related_fields_id	\N	\N	\N	\N	\N	f	t	3	full	\N	\N	\N	f	\N	\N	\N
148	fields	project_id	m2o	select-dropdown-m2o	\N	\N	\N	f	t	4	full	\N	\N	\N	f	\N	\N	\N
149	menu_items	popup_fields_id	m2o	select-dropdown-m2o	{"template":"{{type}}{{field}}{{group}}"}	\N	{"template":"{{type}} {{field}} {{group}}"}	f	f	9	half	\N	\N	\N	f	category	\N	\N
150	menu_items	details_fields_id	m2o	select-dropdown-m2o	{"template":"{{type}}{{field}}{{group}}"}	\N	{"template":"{{type}} {{field}} {{group}}"}	f	f	10	half	\N	\N	\N	f	category	\N	\N
151	menu_items	list_fields_id	m2o	select-dropdown-m2o	{"template":"{{type}}{{field}}{{group}}"}	\N	{"template":"{{type}} {{field}} {{group}}"}	f	f	11	half	\N	\N	\N	f	category	\N	\N
152	projects	articles	cast-json	list	{"fields":[{"field":"title","name":"title","type":"json","meta":{"field":"title","type":"json","interface":"input-code","required":true,"options":{"language":"JSON","lineNumber":false}}},{"field":"url","name":"url","type":"json","meta":{"field":"url","type":"json","interface":"input-code","required":true,"options":{"language":"JSON","lineNumber":false}}}]}	\N	\N	f	f	9	full	\N	\N	\N	f	\N	\N	\N
160	themes	favorites_mode	cast-boolean	boolean	\N	\N	\N	f	f	13	full	\N	\N	\N	f	\N	\N	\N
161	themes	explorer_mode	cast-boolean	boolean	\N	\N	\N	f	f	14	full	\N	\N	\N	f	\N	\N	\N
162	projects	default_country	\N	select-dropdown	{"choices":[{"text":"fr","value":"fr"},{"text":"es","value":"es"}]}	\N	\N	f	f	10	full	\N	\N	\N	f	\N	\N	\N
163	projects	default_country_state_opening_hours	\N	select-dropdown	{"choices":[{"text":"Nouvelle-Aquitaine","value":"Nouvelle-Aquitaine"}]}	\N	\N	f	f	11	full	\N	\N	\N	f	\N	\N	\N
166	pois	slugs	cast-json	input-code	{"lineNumber":false}	\N	\N	f	f	6	full	\N	\N	\N	f	\N	\N	\N
168	projects	polygons_extra	cast-json	input-code	{"lineNumber":false}	\N	\N	f	f	12	full	\N	\N	\N	f	\N	\N	\N
169	translations	id	\N	input	\N	\N	\N	t	t	1	full	\N	\N	\N	f	\N	\N	\N
171	translations	project_id	m2o	select-dropdown-m2o	{"template":"{{slug}}"}	related-values	{"template":"{{slug}}"}	f	t	2	full	\N	\N	\N	f	\N	\N	\N
172	translations	key	\N	input	\N	\N	\N	f	f	3	full	\N	\N	\N	f	\N	\N	\N
173	translations	key_translations	cast-json	input-code	{"lineNumber":false}	\N	\N	f	f	4	full	\N	\N	\N	f	\N	\N	\N
174	translations	values_translations	cast-json	input-code	{"lineNumber":false}	\N	\N	f	f	5	full	\N	\N	\N	f	\N	\N	\N
175	projects	sources	o2m	list-o2m	{"template":"{{slug}}"}	related-values	{"template":"{{slug}}"}	f	t	13	full	\N	\N	\N	f	\N	\N	\N
176	projects	translations	o2m	list-o2m	{"template":"{{key}}"}	related-values	{"template":"{{key}}"}	f	t	14	full	\N	\N	\N	f	\N	\N	\N
178	fields	label	cast-boolean	boolean	\N	\N	\N	f	f	4	half	\N	\N	\N	f	group_block	\N	\N
179	menu_items	use_details_link	cast-boolean	boolean	\N	\N	\N	f	f	12	full	\N	\N	\N	f	category	\N	\N
228	projects	project_translations	translations	translations	{"languageField":"name","defaultLanguage":"en-US","defaultOpenSplitView":true,"userLanguage":true}	translations	{"template":"{{name}}","languageField":"name","defaultLanguage":null,"userLanguage":true}	f	f	2	full	\N	\N	\N	f	\N	\N	\N
229	projects_translations	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
230	languages	code	\N	\N	\N	\N	\N	f	f	1	full	\N	\N	\N	f	\N	\N	\N
231	languages	name	\N	\N	\N	\N	\N	f	f	2	full	\N	\N	\N	f	\N	\N	\N
232	languages	direction	\N	select-dropdown	{"choices":[{"text":"$t:left_to_right","value":"ltr"},{"text":"$t:right_to_left","value":"rtl"}]}	labels	{"choices":[{"text":"$t:left_to_right","value":"ltr"},{"text":"$t:right_to_left","value":"rtl"}],"format":false}	f	f	3	full	\N	\N	\N	f	\N	\N	\N
233	projects_translations	projects_id	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
234	projects_translations	languages_code	\N	\N	\N	\N	\N	f	t	3	full	\N	\N	\N	f	\N	\N	\N
235	projects_translations	name	\N	input	\N	\N	\N	f	f	4	full	\N	\N	\N	f	\N	\N	\N
236	themes	theme_translations	translations	translations	{"defaultLanguage":"en-US","userLanguage":true,"defaultOpenSplitView":true,"languageField":"name"}	translations	{"template":"{{name}}","languageField":"name"}	f	f	3	full	\N	\N	\N	f	\N	\N	\N
237	themes_translations	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
238	themes_translations	themes_id	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
239	themes_translations	languages_code	\N	\N	\N	\N	\N	f	t	3	full	\N	\N	\N	f	\N	\N	\N
240	themes_translations	name	\N	input	\N	\N	\N	f	f	4	full	\N	\N	\N	f	\N	\N	\N
241	themes_translations	description	\N	input	\N	\N	\N	f	f	5	full	\N	\N	\N	f	\N	\N	\N
242	themes_translations	site_url	\N	input	\N	\N	\N	f	f	6	full	\N	\N	\N	f	\N	\N	\N
243	themes_translations	main_url	\N	input	\N	\N	\N	f	f	7	full	\N	\N	\N	f	\N	\N	\N
244	themes_translations	keywords	\N	input	\N	\N	\N	f	f	8	full	\N	\N	\N	f	\N	\N	\N
245	menu_items	menu_items_translations	translations	translations	{"userLanguage":true,"defaultLanguage":"en-US","defaultOpenSplitView":true,"languageField":"name"}	translations	{"template":"{{name}}","languageField":"name"}	f	f	3	full	\N	\N	\N	f	\N	\N	\N
246	menu_items_translations	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
247	menu_items_translations	menu_items_id	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
248	menu_items_translations	languages_code	\N	\N	\N	\N	\N	f	t	3	full	\N	\N	\N	f	\N	\N	\N
249	menu_items_translations	name	\N	input	\N	\N	\N	f	f	4	full	\N	\N	\N	f	\N	\N	\N
250	menu_items_translations	slug	\N	input	\N	\N	\N	f	f	6	full	\N	\N	\N	f	\N	\N	\N
251	menu_items_translations	name_singular	\N	input	\N	\N	\N	f	f	5	full	\N	\N	\N	f	\N	\N	\N
252	sources	sources_translations	translations	translations	{"defaultLanguage":"en-US","userLanguage":true,"defaultOpenSplitView":true}	translations	{"template":"{{name}}","languageField":"name"}	f	f	3	full	\N	\N	\N	f	\N	\N	\N
253	sources_translations	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
254	sources_translations	sources_id	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
255	sources_translations	languages_code	\N	\N	\N	\N	\N	f	t	3	full	\N	\N	\N	f	\N	\N	\N
256	sources_translations	name	\N	input	\N	\N	\N	f	f	4	full	\N	\N	\N	f	\N	\N	\N
257	filters	filters_translations	translations	translations	{"defaultLanguage":"en-US","userLanguage":true,"defaultOpenSplitView":true,"languageField":"name"}	translations	{"template":"{{name}}","languageField":"name"}	f	f	2	full	\N	\N	\N	f	\N	\N	\N
258	filters_translations	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
259	filters_translations	filters_id	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
260	filters_translations	languages_code	\N	\N	\N	\N	\N	f	t	3	full	\N	\N	\N	f	\N	\N	\N
261	filters_translations	name	\N	input	\N	\N	\N	f	f	4	full	\N	\N	\N	f	\N	\N	\N
\.


--
-- Data for Name: directus_folders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_folders (id, name, parent) FROM stdin;
\.


--
-- Data for Name: directus_files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_files (id, storage, filename_disk, filename_download, title, type, folder, uploaded_by, uploaded_on, modified_by, modified_on, charset, filesize, width, height, duration, embed, description, location, tags, metadata, focal_point_x, focal_point_y, tus_id, tus_data) FROM stdin;
\.


--
-- Data for Name: directus_flows; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_flows (id, name, icon, color, description, status, trigger, accountability, options, operation, date_created, user_created) FROM stdin;
\.


--
-- Data for Name: directus_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_migrations (version, name, "timestamp") FROM stdin;
20201028A	Remove Collection Foreign Keys	2023-09-12 16:28:23.719649+00
20201029A	Remove System Relations	2023-09-12 16:28:23.732513+00
20201029B	Remove System Collections	2023-09-12 16:28:23.7442+00
20201029C	Remove System Fields	2023-09-12 16:28:23.765668+00
20201105A	Add Cascade System Relations	2023-09-12 16:28:23.801125+00
20201105B	Change Webhook URL Type	2023-09-12 16:28:23.806682+00
20210225A	Add Relations Sort Field	2023-09-12 16:28:23.811358+00
20210304A	Remove Locked Fields	2023-09-12 16:28:23.814317+00
20210312A	Webhooks Collections Text	2023-09-12 16:28:23.82012+00
20210331A	Add Refresh Interval	2023-09-12 16:28:23.822659+00
20210415A	Make Filesize Nullable	2023-09-12 16:28:23.829007+00
20210416A	Add Collections Accountability	2023-09-12 16:28:23.833062+00
20210422A	Remove Files Interface	2023-09-12 16:28:23.835324+00
20210506A	Rename Interfaces	2023-09-12 16:28:23.854436+00
20210510A	Restructure Relations	2023-09-12 16:28:23.869453+00
20210518A	Add Foreign Key Constraints	2023-09-12 16:28:23.876093+00
20210519A	Add System Fk Triggers	2023-09-12 16:28:23.895511+00
20210521A	Add Collections Icon Color	2023-09-12 16:28:23.89815+00
20210525A	Add Insights	2023-09-12 16:28:23.912573+00
20210608A	Add Deep Clone Config	2023-09-12 16:28:23.915188+00
20210626A	Change Filesize Bigint	2023-09-12 16:28:23.92532+00
20210716A	Add Conditions to Fields	2023-09-12 16:28:23.927754+00
20210721A	Add Default Folder	2023-09-12 16:28:23.93284+00
20210802A	Replace Groups	2023-09-12 16:28:23.937105+00
20210803A	Add Required to Fields	2023-09-12 16:28:23.939677+00
20210805A	Update Groups	2023-09-12 16:28:23.943151+00
20210805B	Change Image Metadata Structure	2023-09-12 16:28:23.946616+00
20210811A	Add Geometry Config	2023-09-12 16:28:23.949574+00
20210831A	Remove Limit Column	2023-09-12 16:28:23.952294+00
20210903A	Add Auth Provider	2023-09-12 16:28:23.963731+00
20210907A	Webhooks Collections Not Null	2023-09-12 16:28:23.969422+00
20210910A	Move Module Setup	2023-09-12 16:28:23.972914+00
20210920A	Webhooks URL Not Null	2023-09-12 16:28:23.978699+00
20210924A	Add Collection Organization	2023-09-12 16:28:23.98269+00
20210927A	Replace Fields Group	2023-09-12 16:28:23.989448+00
20210927B	Replace M2M Interface	2023-09-12 16:28:23.991791+00
20210929A	Rename Login Action	2023-09-12 16:28:23.993926+00
20211007A	Update Presets	2023-09-12 16:28:23.999225+00
20211009A	Add Auth Data	2023-09-12 16:28:24.002096+00
20211016A	Add Webhook Headers	2023-09-12 16:28:24.004962+00
20211103A	Set Unique to User Token	2023-09-12 16:28:24.009231+00
20211103B	Update Special Geometry	2023-09-12 16:28:24.012198+00
20211104A	Remove Collections Listing	2023-09-12 16:28:24.015503+00
20211118A	Add Notifications	2023-09-12 16:28:24.027947+00
20211211A	Add Shares	2023-09-12 16:28:24.04049+00
20211230A	Add Project Descriptor	2023-09-12 16:28:24.043074+00
20220303A	Remove Default Project Color	2023-09-12 16:28:24.048742+00
20220308A	Add Bookmark Icon and Color	2023-09-12 16:28:24.051482+00
20220314A	Add Translation Strings	2023-09-12 16:28:24.053885+00
20220322A	Rename Field Typecast Flags	2023-09-12 16:28:24.057988+00
20220323A	Add Field Validation	2023-09-12 16:28:24.060331+00
20220325A	Fix Typecast Flags	2023-09-12 16:28:24.064264+00
20220325B	Add Default Language	2023-09-12 16:28:24.071419+00
20220402A	Remove Default Value Panel Icon	2023-09-12 16:28:24.077365+00
20220429A	Add Flows	2023-09-12 16:28:24.104206+00
20220429B	Add Color to Insights Icon	2023-09-12 16:28:24.10743+00
20220429C	Drop Non Null From IP of Activity	2023-09-12 16:28:24.110441+00
20220429D	Drop Non Null From Sender of Notifications	2023-09-12 16:28:24.113391+00
20220614A	Rename Hook Trigger to Event	2023-09-12 16:28:24.116298+00
20220801A	Update Notifications Timestamp Column	2023-09-12 16:28:24.123437+00
20220802A	Add Custom Aspect Ratios	2023-09-12 16:28:24.126871+00
20220826A	Add Origin to Accountability	2023-09-12 16:28:24.131282+00
20230401A	Update Material Icons	2023-09-12 16:28:24.139153+00
20230525A	Add Preview Settings	2023-09-12 16:28:24.142323+00
20230526A	Migrate Translation Strings	2023-09-12 16:28:24.152613+00
20230721A	Require Shares Fields	2023-09-12 16:28:24.15664+00
20230823A	Add Content Versioning	2024-02-02 09:09:59.965395+00
20230927A	Themes	2024-02-02 09:09:59.980332+00
20231009A	Update CSV Fields to Text	2024-02-02 09:09:59.986484+00
20231009B	Update Panel Options	2024-02-02 09:09:59.989722+00
20231010A	Add Extensions	2024-02-02 09:09:59.994272+00
20231215A	Add Focalpoints	2024-07-15 12:22:59.27761+00
20240122A	Add Report URL Fields	2024-07-15 12:22:59.280282+00
20240204A	Marketplace	2024-07-15 12:22:59.300739+00
20240305A	Change Useragent Type	2024-07-15 12:22:59.307229+00
20240311A	Deprecate Webhooks	2024-07-15 12:22:59.317068+00
20240422A	Public Registration	2024-07-15 12:22:59.320243+00
20240515A	Add Session Window	2024-07-15 12:22:59.321949+00
20240701A	Add Tus Data	2024-07-15 12:22:59.323603+00
\.


--
-- Data for Name: directus_notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_notifications (id, "timestamp", status, recipient, sender, subject, message, collection, item) FROM stdin;
\.


--
-- Data for Name: directus_operations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_operations (id, name, key, type, position_x, position_y, options, resolve, reject, flow, date_created, user_created) FROM stdin;
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
1	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_files	create	{}	\N	\N	*
2	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_files	read	{}	\N	\N	*
3	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_files	update	{}	\N	\N	*
4	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_files	delete	{}	\N	\N	*
5	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_dashboards	create	{}	\N	\N	*
6	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_dashboards	read	{}	\N	\N	*
7	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_dashboards	update	{}	\N	\N	*
8	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_dashboards	delete	{}	\N	\N	*
9	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_panels	create	{}	\N	\N	*
10	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_panels	read	{}	\N	\N	*
11	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_panels	update	{}	\N	\N	*
12	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_panels	delete	{}	\N	\N	*
13	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_folders	create	{}	\N	\N	*
14	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_folders	read	{}	\N	\N	*
15	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_folders	update	{}	\N	\N	*
16	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_folders	delete	{}	\N	\N	\N
17	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_users	read	{}	\N	\N	*
18	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_users	update	{"id":{"_eq":"$CURRENT_USER"}}	\N	\N	first_name,last_name,email,password,location,title,description,avatar,language,theme,tfa_secret
19	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_roles	read	{}	\N	\N	*
20	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_shares	read	{"_or":[{"role":{"_eq":"$CURRENT_ROLE"}},{"role":{"_null":true}}]}	\N	\N	*
21	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_shares	create	{}	\N	\N	*
22	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_shares	update	{"user_created":{"_eq":"$CURRENT_USER"}}	\N	\N	*
23	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_shares	delete	{"user_created":{"_eq":"$CURRENT_USER"}}	\N	\N	*
24	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	directus_flows	read	{"trigger":{"_eq":"manual"}}	\N	\N	id,status,name,icon,color,options,trigger
25	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	projects	read	{"_and":[{"id":{"_eq":"$CURRENT_USER.project_id"}}]}	{}	\N	*
31	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	themes	create	{}	{}	\N	*
33	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	themes	read	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	{}	\N	*
34	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	projects	update	{"_and":[{"id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	polygon,slug,attributions,bbox_line,name,icon_font_css_url,id,themes,articles,default_country_state_opening_hours,default_country,polygons_extra
35	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	themes	update	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	id,name,main_url,project_id,description,logo_url,slug,site_url,favicon_url,root_menu_item_id,keywords,explorer_mode,favorites_mode
41	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	themes	delete	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	\N
42	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items	create	{}	{}	\N	*
43	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items	read	{"_and":[{"theme_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	project_id,theme_id,index_order,selected_by_default,id,parent_id,hidden,category_id,items,menu_group_id,slug,name,UI,color,icon,behavior,display_mode,category,style_merge,zoom,style_class,search_indexed,sources,link,href,filters,color_line,color_fill,accordion-xkp6bl,menu_group,style_class_string,type,popup_fields_id,list_fields_id,details_fields_id,slugs,name_singular,use_details_link
44	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items	update	{}	{}	\N	*
45	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items	delete	{"_and":[{"theme_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	\N
52	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	sources	read	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	id,name,project_id,attribution,slug,pois
58	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items_sources	create	{}	{}	\N	*
59	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items_sources	read	{"_and":[{"sources_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	id,menu_items_id,sources_id
60	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items_sources	update	{"_and":[{"sources_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	id,menu_items_id,sources_id
61	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items_sources	delete	{"_and":[{"sources_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	\N
62	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items_childrens	create	{}	{}	\N	*
63	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items_childrens	read	{"_and":[{"menu_items_id":{"theme_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}}]}	\N	\N	id,collection,menu_items_id,item
64	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items_childrens	update	{"_and":[{"menu_items_id":{"theme_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}}]}	\N	\N	\N
65	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items_childrens	delete	{"_and":[{"menu_items_id":{"theme_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}}]}	\N	\N	\N
66	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	filters	create	{}	{}	\N	*
67	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	filters	read	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	id,type,name,property_begin,date_range,property,property_end,number_range,min,project_id,max,accordion-ysehx-,multiselection,checkboxes_list,multiselection_property,checkboxes_list_property,boolean,boolean_property,number_range_property
68	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	filters	update	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	id,type,name,property_begin,date_range,property,property_end,number_range,min,project_id,max,multiselection,accordion-ysehx-,multiselection_property,checkboxes_list,checkboxes_list_property,boolean_property,boolean,number_range_property
69	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	filters	delete	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	\N
73	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items_filters	create	{}	{}	\N	*
74	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items_filters	read	{"_and":[{"filters_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	id,menu_items_id,filters_id
75	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items_filters	update	{"_and":[{"filters_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	id,menu_items_id,filters_id
76	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items_filters	delete	{"_and":[{"filters_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	\N
83	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	pois	read	{"_and":[{"source_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	id,source_id,geom,properties,slugs
84	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	fields	create	{}	{}	\N	*
85	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	fields_fields	create	{}	{}	\N	*
86	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	fields	read	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	id,accordion-9juoos,group_block,fields,project_id,icon,group,field,type,display_mode,label
87	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	fields	update	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	id,accordion-9juoos,group_block,display_mode,icon,group,field,type,project_id,fields,label
88	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	fields	delete	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	\N
89	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	fields_fields	read	{"_and":[{"fields_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	id,related_fields_id,index,fields_id
90	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	fields_fields	update	{"_and":[{"fields_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	id,related_fields_id,index,fields_id
91	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	fields_fields	delete	{"_and":[{"fields_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	\N
92	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	translations	read	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	id,key,values_translations,project_id,key_translations
93	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	languages	read	{}	{}	\N	*
\.


--
-- Data for Name: directus_relations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_relations (id, many_collection, many_field, one_collection, one_field, one_collection_field, one_allowed_collections, junction_field, sort_field, one_deselect_action) FROM stdin;
2	themes	project_id	projects	themes	\N	\N	\N	\N	nullify
3	directus_users	project_id	projects	\N	\N	\N	\N	\N	nullify
5	menu_items_childrens	item	\N	\N	collection	menu_items	menu_items_id	\N	nullify
6	menu_items_childrens	menu_items_id	menu_items	\N	\N	\N	item	\N	nullify
7	menu_items	menu_item_parent_id	menu_items	\N	\N	\N	\N	\N	nullify
10	menu_items	parent_id	menu_items	items	\N	\N	\N	index_order	nullify
11	themes	root_menu_item_id	menu_items	\N	\N	\N	\N	\N	nullify
14	menu_items	theme_id	themes	\N	\N	\N	\N	\N	nullify
16	menu_items_sources	sources_id	sources	\N	\N	\N	menu_items_id	\N	nullify
17	menu_items_sources	menu_items_id	menu_items	sources	\N	\N	sources_id	\N	nullify
19	filters	project_id	projects	\N	\N	\N	\N	\N	nullify
24	menu_items_filters	filters_id	filters	\N	\N	\N	menu_items_id	\N	nullify
25	menu_items_filters	menu_items_id	menu_items	filters	\N	\N	filters_id	\N	nullify
26	pois	source_id	sources	pois	\N	\N	\N	\N	nullify
28	fields_fields	related_fields_id	fields	\N	\N	\N	fields_id	\N	nullify
29	fields_fields	fields_id	fields	fields	\N	\N	related_fields_id	index	nullify
30	fields	project_id	projects	\N	\N	\N	\N	\N	nullify
31	menu_items	popup_fields_id	fields	\N	\N	\N	\N	\N	nullify
32	menu_items	details_fields_id	fields	\N	\N	\N	\N	\N	nullify
33	menu_items	list_fields_id	fields	\N	\N	\N	\N	\N	nullify
34	translations	project_id	projects	translations	\N	\N	\N	\N	nullify
35	sources	project_id	projects	sources	\N	\N	\N	\N	nullify
36	projects_translations	languages_code	languages	\N	\N	\N	projects_id	\N	nullify
37	projects_translations	projects_id	projects	project_translations	\N	\N	languages_code	\N	nullify
38	themes_translations	languages_code	languages	\N	\N	\N	themes_id	\N	nullify
39	themes_translations	themes_id	themes	theme_translations	\N	\N	languages_code	\N	nullify
40	menu_items_translations	languages_code	languages	\N	\N	\N	menu_items_id	\N	nullify
41	menu_items_translations	menu_items_id	menu_items	menu_items_translations	\N	\N	languages_code	\N	nullify
42	sources_translations	languages_code	languages	\N	\N	\N	sources_id	\N	nullify
43	sources_translations	sources_id	sources	sources_translations	\N	\N	languages_code	\N	nullify
44	filters_translations	languages_code	languages	\N	\N	\N	filters_id	\N	nullify
45	filters_translations	filters_id	filters	filters_translations	\N	\N	languages_code	\N	nullify
\.


--
-- Data for Name: directus_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_settings (id, project_name, project_url, project_color, project_logo, public_foreground, public_background, public_note, auth_login_attempts, auth_password_policy, storage_asset_transform, storage_asset_presets, custom_css, storage_default_folder, basemaps, mapbox_key, module_bar, project_descriptor, default_language, custom_aspect_ratios, public_favicon, default_appearance, default_theme_light, theme_light_overrides, default_theme_dark, theme_dark_overrides, report_error_url, report_bug_url, report_feature_url, public_registration, public_registration_verify_email, public_registration_role, public_registration_email_filter) FROM stdin;
1	Elasa	\N	#6644ff	\N	\N	\N	\N	25	\N	all	\N	\N	\N	\N	\N	[{"type":"module","id":"content","enabled":true},{"type":"module","id":"users","enabled":true},{"type":"module","id":"files","enabled":false},{"type":"module","id":"insights","enabled":false},{"type":"module","id":"settings","enabled":true,"locked":true}]	\N	en-US	\N	\N	auto	\N	\N	\N	\N	\N	\N	\N	f	t	\N	\N
\.


--
-- Data for Name: directus_shares; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_shares (id, name, collection, item, role, password, user_created, date_created, date_start, date_end, times_used, max_uses) FROM stdin;
\.


--
-- Data for Name: directus_translations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_translations (id, language, key, value) FROM stdin;
\.


--
-- Data for Name: directus_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_versions (id, key, name, collection, item, hash, date_created, date_updated, user_created, user_updated) FROM stdin;
\.


--
-- Data for Name: directus_webhooks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_webhooks (id, name, method, url, status, data, actions, collections, headers, was_active_before_deprecation, migrated_flow) FROM stdin;
\.


--
-- Name: directus_activity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_activity_id_seq', 1, true);


--
-- Name: directus_fields_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_fields_id_seq', 359, true);


--
-- Name: directus_notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_notifications_id_seq', 1, false);


--
-- Name: directus_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_permissions_id_seq', 93, true);


--
-- Name: directus_presets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_presets_id_seq', 1, true);


--
-- Name: directus_relations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_relations_id_seq', 47, true);


--
-- Name: directus_revisions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_revisions_id_seq', 1, true);


--
-- Name: directus_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_settings_id_seq', 1, true);


--
-- Name: directus_webhooks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_webhooks_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

