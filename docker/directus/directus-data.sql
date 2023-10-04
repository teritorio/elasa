--
-- PostgreSQL database dump
--

-- Dumped from database version 15.4 (Debian 15.4-1.pgdg110+1)
-- Dumped by pg_dump version 15.4 (Debian 15.4-1.pgdg110+1)

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

COPY public.directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url) FROM stdin;
fields	rectangle	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	3	projects	open	\N
fields_fields	import_export	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	\N	\N	open	\N
filters	filter_alt	\N	{{type}}{{name}}	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	2	projects	open	\N
junction_directus_roles_undefined	import_export	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	1	\N	open	\N
menu_items	menu	\N	{{type}}{{slug}}{{name}}	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	1	themes	open	\N
menu_items_childrens	import_export	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	3	\N	open	\N
menu_items_filters	import_export	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	5	\N	open	\N
menu_items_sources	import_export	\N	\N	t	f	\N	\N	t	\N	\N	\N	all	\N	\N	4	\N	open	\N
pois	pin_drop	\N	{{properties}}	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	1	sources	open	\N
projects	house	\N	{{slug}}	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	2	\N	open	{{slug}}
sources	database	\N	{{slug}}	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	4	projects	open	\N
themes	map	\N	{{slug}}	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	1	projects	open	\N
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

COPY public.directus_users (id, first_name, last_name, email, password, location, title, description, tags, avatar, language, theme, tfa_secret, status, role, token, last_access, last_page, provider, external_identifier, auth_data, email_notifications, project_id) FROM stdin;
3c0b4886-bfde-4fe5-9b68-a65381880aae	Frédéric	Rodrigo	frederic@teritorio.fr	$argon2id$v=19$m=65536,t=3,p=4$iTzKJuByNiJAe475ITlJ3Q$Nw84KHKpVfD7/zifqZdXguhYmXrDCdJjtq4xY0kTiMA	\N	\N	\N	\N	\N	\N	auto	\N	active	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	\N	2023-09-27 13:48:30.643+00	/content/themes/90	default	\N	\N	t	101
7ee01efc-e308-47e8-bf57-3dacd8ba56c5	Admin	User	admin@example.com	$argon2id$v=19$m=65536,t=3,p=4$qS/yUxvrtrTXACg+65QTTQ$5xe8tFtiM/tsoP+k0SjMLTQMc/lKuC1QUOyCM7Mm+kc	\N	\N	\N	\N	\N	\N	auto	\N	active	f400ab71-d9c5-4ea8-96aa-0958f373ccca	\N	2023-10-04 17:26:45.716+00	/settings/roles/	default	\N	\N	t	\N
\.


--
-- Data for Name: directus_dashboards; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_dashboards (id, name, icon, note, date_created, user_created, color) FROM stdin;
\.


--
-- Data for Name: directus_fields; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message) FROM stdin;
2	junction_directus_roles_undefined	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
3	junction_directus_roles_undefined	directus_roles_id	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
4	junction_directus_roles_undefined	item	\N	\N	\N	\N	\N	f	t	3	full	\N	\N	\N	f	\N	\N	\N
5	junction_directus_roles_undefined	collection	\N	\N	\N	\N	\N	f	t	4	full	\N	\N	\N	f	\N	\N	\N
6	projects	polygon	\N	\N	\N	formatted-json-value	\N	f	f	6	full	\N	\N	\N	f	\N	\N	\N
7	themes	project_id	\N	select-dropdown-m2o	\N	related-values	{"template":"{{slug}}"}	t	f	2	full	\N	\N	\N	f	\N	\N	\N
8	themes	slug	\N	\N	\N	\N	\N	f	f	3	full	\N	\N	\N	f	\N	\N	\N
9	themes	name	cast-json	\N	\N	\N	\N	f	f	4	full	\N	\N	\N	f	\N	\N	\N
10	themes	description	cast-json	\N	\N	\N	\N	f	f	5	full	\N	\N	\N	f	\N	\N	\N
13	themes	logo_url	\N	\N	\N	\N	\N	f	f	8	full	\N	\N	\N	f	\N	\N	\N
14	themes	favicon_url	\N	\N	\N	\N	\N	f	f	9	full	\N	\N	\N	f	\N	\N	\N
15	themes	id	\N	\N	\N	\N	\N	t	t	1	full	\N	\N	\N	f	\N	\N	\N
16	projects	themes	o2m	list-o2m	\N	\N	\N	f	f	4	full	\N	\N	\N	f	\N	\N	\N
17	projects	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
20	projects	attributions	\N	\N	\N	\N	\N	f	f	5	full	\N	\N	\N	f	\N	\N	\N
21	projects	icon_font_css_url	\N	\N	\N	\N	\N	f	f	5	full	\N	\N	\N	f	\N	\N	\N
22	projects	bbox_line	\N	\N	\N	\N	\N	f	t	7	full	\N	\N	\N	f	\N	\N	\N
23	sources	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
24	sources	project_id	\N	select-dropdown-m2o	{"template":"{{slug}}"}	related-values	{"template":"{{slug}}"}	f	t	2	full	\N	\N	\N	f	\N	\N	\N
25	sources	slug	\N	\N	\N	\N	\N	f	f	3	full	\N	\N	\N	f	\N	\N	\N
26	sources	name	cast-json	\N	\N	\N	\N	f	f	4	full	\N	\N	\N	f	\N	\N	\N
27	sources	attribution	\N	\N	\N	\N	\N	f	f	5	full	\N	\N	\N	f	\N	\N	\N
29	directus_users	project_id	m2o	select-dropdown-m2o	{"template":"{{slug}}"}	\N	\N	f	f	1	full	\N	\N	\N	f	\N	\N	\N
35	menu_items_childrens	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
36	menu_items_childrens	menu_items_id	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
37	menu_items_childrens	item	\N	\N	\N	\N	\N	f	t	3	full	\N	\N	\N	f	\N	\N	\N
38	menu_items_childrens	collection	\N	\N	\N	\N	\N	f	t	4	full	\N	\N	\N	f	\N	\N	\N
40	menu_items	menu_item_parent_id	\N	select-dropdown-m2o	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
41	menu_items	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
46	menu_items	items	o2m	list-o2m-tree-view	{"displayTemplate":"{{type}}{{slug}}{{name}}"}	\N	{"template":"{{id}}"}	f	f	1	full	\N	\N	\N	f	menu_group	\N	\N
47	menu_items	parent_id	\N	select-dropdown-m2o	\N	\N	\N	f	t	7	full	\N	\N	\N	f	\N	\N	\N
49	themes	root_menu_item_id	m2o	select-dropdown-m2o	{"template":"{{type}}{{slug}}{{name}}"}	related-values	{"template":"{{type}}{{slug}}{{name}}"}	f	f	10	full	\N	\N	\N	f	\N	\N	\N
53	menu_items	theme_id	m2o	select-dropdown-m2o	\N	\N	\N	f	f	6	full	\N	\N	\N	t	\N	\N	\N
54	menu_items	index_order	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
55	menu_items	hidden	\N	\N	\N	\N	\N	f	f	1	half	\N	\N	\N	f	behavior	\N	\N
56	menu_items	selected_by_default	\N	\N	\N	\N	\N	f	f	2	half	\N	\N	\N	f	behavior	\N	\N
61	menu_items	name	cast-json	input-code	\N	\N	\N	f	f	5	full	\N	\N	\N	t	\N	\N	\N
62	menu_items	icon	\N	input	\N	\N	\N	f	f	4	half	\N	\N	\N	t	UI	\N	\N
65	menu_items	UI	alias,no-data,group	group-detail	\N	\N	\N	f	f	9	full	\N	\N	\N	f	\N	\N	\N
66	menu_items	behavior	alias,no-data,group	group-detail	\N	\N	\N	f	f	8	full	\N	\N	\N	f	\N	\N	\N
67	menu_items	display_mode	\N	\N	\N	\N	\N	f	f	1	full	\N	\N	\N	f	UI	\N	\N
68	menu_items	category	alias,no-data,group	group-detail	\N	\N	\N	f	f	2	full	\N	\N	\N	f	accordion-xkp6bl	\N	\N
69	menu_items	search_indexed	cast-boolean	boolean	\N	\N	\N	f	f	2	half	\N	\N	\N	f	category	\N	\N
71	menu_items	style_merge	cast-boolean	boolean	\N	\N	\N	f	f	3	half	\N	\N	\N	f	category	\N	\N
73	menu_items	zoom	\N	slider	{"minValue":12,"maxValue":18}	\N	\N	f	f	5	half	\N	\N	\N	f	category	\N	\N
74	menu_items	sources	m2m	list-m2m	{"template":"{{sources_id.slug}}"}	\N	\N	f	f	1	full	\N	\N	\N	f	category	\N	\N
75	menu_items_sources	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
76	menu_items_sources	menu_items_id	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
77	menu_items_sources	sources_id	\N	\N	\N	\N	\N	f	t	3	full	\N	\N	\N	f	\N	\N	\N
78	menu_items	color_fill	\N	select-color	\N	\N	\N	f	f	2	half	\N	\N	\N	f	UI	\N	\N
79	menu_items	color_line	\N	select-color	\N	\N	\N	f	f	3	half	\N	\N	\N	f	UI	\N	\N
80	menu_items	link	alias,no-data,group	group-detail	\N	\N	\N	f	f	3	full	\N	\N	\N	f	accordion-xkp6bl	\N	\N
81	menu_items	href	\N	input	\N	\N	\N	f	f	1	full	\N	\N	\N	f	link	\N	\N
82	filters	id	\N	input	\N	\N	\N	t	t	1	full	\N	\N	\N	f	\N	\N	\N
83	filters	type	\N	select-dropdown	{"choices":[{"text":"multiselection","value":"multiselection"},{"text":"checkboxes_list","value":"checkboxes_list"},{"text":"boolean","value":"boolean"},{"text":"date_range","value":"date_range"},{"text":"number_range","value":"number_range"}]}	\N	\N	f	f	4	full	\N	\N	\N	t	\N	\N	\N
85	filters	name	cast-json	input-code	\N	\N	\N	f	f	2	full	\N	\N	\N	t	\N	\N	\N
86	filters	property_end	\N	input	\N	\N	\N	f	f	2	full	\N	\N	\N	f	date_range	\N	\N
87	filters	property_begin	\N	input	\N	\N	\N	f	f	1	full	\N	\N	\N	f	date_range	\N	\N
88	filters	date_range	alias,no-data,group	group-detail	\N	\N	\N	f	f	4	full	\N	\N	\N	f	accordion-ysehx-	\N	\N
89	filters	number_range	alias,no-data,group	group-detail	\N	\N	\N	f	f	5	full	\N	\N	\N	f	accordion-ysehx-	\N	\N
90	filters	min	\N	input	\N	\N	\N	f	f	2	full	\N	\N	\N	f	number_range	\N	\N
91	filters	max	\N	input	\N	\N	\N	f	f	3	full	\N	\N	\N	f	number_range	\N	\N
98	filters	project_id	m2o	select-dropdown-m2o	\N	\N	\N	f	f	3	full	\N	\N	\N	t	\N	\N	\N
107	menu_items	filters	m2m	list-m2m	\N	\N	\N	f	f	7	full	\N	\N	\N	f	category	\N	\N
108	menu_items_filters	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
109	menu_items_filters	menu_items_id	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
110	menu_items_filters	filters_id	\N	\N	\N	\N	\N	f	t	3	full	\N	\N	\N	f	\N	\N	\N
111	menu_items	accordion-xkp6bl	alias,no-data,group	group-accordion	{"start":"first"}	\N	\N	f	f	11	full	\N	\N	\N	f	\N	\N	\N
112	menu_items	menu_group	alias,no-data,group	group-detail	\N	\N	\N	f	f	1	full	\N	\N	\N	f	accordion-xkp6bl	\N	\N
113	filters	accordion-ysehx-	alias,no-data,group	group-accordion	{"start":"first"}	\N	\N	f	f	5	full	\N	\N	\N	f	\N	\N	\N
114	filters	multiselection	alias,no-data,group	group-detail	\N	\N	\N	f	f	1	full	\N	\N	\N	f	accordion-ysehx-	\N	\N
115	filters	checkboxes_list	alias,no-data,group	group-detail	\N	\N	\N	f	f	2	full	\N	\N	\N	f	accordion-ysehx-	\N	\N
116	filters	boolean	alias,no-data,group	group-detail	\N	\N	\N	f	f	3	full	\N	\N	\N	f	accordion-ysehx-	\N	\N
117	filters	multiselection_property	\N	input	\N	\N	\N	f	f	1	full	\N	\N	\N	f	multiselection	\N	\N
118	filters	checkboxes_list_property	\N	input	\N	\N	\N	f	f	1	full	\N	\N	\N	f	checkboxes_list	\N	\N
119	filters	boolean_property	\N	input	\N	\N	\N	f	f	1	full	\N	\N	\N	f	boolean	\N	\N
120	filters	number_range_property	\N	input	\N	\N	\N	f	f	1	full	\N	\N	\N	f	number_range	\N	\N
121	pois	id	\N	\N	\N	\N	\N	f	f	1	full	\N	\N	\N	f	\N	\N	\N
123	pois	geom	geometry	\N	\N	\N	\N	f	f	4	full	\N	\N	\N	f	\N	\N	\N
124	pois	properties	cast-json	\N	\N	\N	\N	f	f	5	full	\N	\N	\N	f	\N	\N	\N
125	pois	source_id	m2o	select-dropdown-m2o	{"template":"{{slug}}"}	related-values	{"template":"{{slug}}"}	f	f	2	full	\N	\N	\N	f	\N	\N	\N
126	sources	pois	o2m	list-o2m	{"enableLink":true}	\N	\N	f	f	6	full	\N	\N	\N	f	\N	\N	\N
127	menu_items	style_class_string	\N	input	\N	\N	\N	f	f	4	half	\N	\N	\N	f	category	\N	\N
128	menu_items	style_class	\N	\N	\N	\N	\N	f	t	6	full	\N	\N	\N	f	category	\N	\N
129	projects	name	cast-json	input-code	\N	\N	\N	f	f	3	full	\N	\N	\N	t	\N	\N	\N
131	projects	slug	\N	input	\N	\N	\N	f	f	2	full	\N	\N	\N	t	\N	\N	\N
132	menu_items	type	\N	select-dropdown	{"choices":[{"text":"menu_group","value":"menu_group"},{"text":"category","value":"category"},{"text":"link","value":"link"},{"text":"search","value":"search"}]}	\N	\N	f	f	10	full	\N	\N	\N	t	\N	\N	\N
133	fields	id	\N	input	\N	\N	\N	t	t	1	full	\N	\N	\N	f	\N	\N	\N
134	fields	type	\N	select-dropdown	{"choices":[{"text":"field","value":"field"},{"text":"group","value":"group"}]}	\N	\N	f	f	2	full	\N	\N	\N	f	\N	\N	\N
135	fields	accordion-9juoos	alias,no-data,group	group-accordion	\N	\N	\N	f	f	3	full	\N	\N	\N	f	\N	\N	\N
136	fields	field	\N	input	\N	\N	\N	f	f	1	full	\N	\N	\N	f	accordion-9juoos	\N	\N
138	fields	group	\N	input	\N	\N	\N	f	f	1	full	\N	\N	\N	f	group_block	\N	\N
139	fields	display_mode	\N	select-dropdown	{"choices":[{"text":"standard","value":"standard"},{"text":"card","value":"card"}]}	\N	\N	f	f	2	full	\N	\N	\N	f	group_block	\N	\N
140	fields	icon	\N	input	\N	\N	\N	f	f	3	full	\N	\N	\N	f	group_block	\N	\N
141	fields	group_block	alias,no-data,group	group-detail	\N	\N	\N	f	f	2	full	\N	\N	\N	f	accordion-9juoos	\N	\N
144	fields	fields	m2m	list-m2m	{"template":"{{related_fields_id.type}}{{related_fields_id.field}}{{related_fields_id.group}}","enableLink":true}	related-values	{"template":"{{related_fields_id.type}}{{related_fields_id.field}}{{related_fields_id.group}}"}	f	f	4	full	\N	\N	\N	f	group_block	\N	\N
145	fields_fields	id	\N	\N	\N	\N	\N	f	t	1	full	\N	\N	\N	f	\N	\N	\N
146	fields_fields	fields_id	\N	\N	\N	\N	\N	f	t	2	full	\N	\N	\N	f	\N	\N	\N
147	fields_fields	related_fields_id	\N	\N	\N	\N	\N	f	t	3	full	\N	\N	\N	f	\N	\N	\N
148	fields	project_id	m2o	select-dropdown-m2o	\N	\N	\N	f	f	5	full	\N	\N	\N	f	\N	\N	\N
149	menu_items	popup_fields_id	m2o	select-dropdown-m2o	{"template":"{{type}}{{field}}{{group}}"}	\N	\N	f	f	8	half	\N	\N	\N	f	category	\N	\N
150	menu_items	details_fields_id	m2o	select-dropdown-m2o	{"template":"{{type}}{{field}}{{group}}"}	\N	\N	f	f	9	half	\N	\N	\N	f	category	\N	\N
151	menu_items	list_fields_id	m2o	select-dropdown-m2o	{"template":"{{type}}{{field}}{{group}}"}	\N	\N	f	f	10	half	\N	\N	\N	f	category	\N	\N
152	projects	articles	cast-json	list	{"fields":[{"field":"title","name":"title","type":"json","meta":{"field":"title","type":"json","interface":"input-code","required":true,"options":{"language":"JSON","lineNumber":false}}},{"field":"url","name":"url","type":"json","meta":{"field":"url","type":"json","interface":"input-code","required":true,"options":{"language":"JSON","lineNumber":false}}}]}	\N	\N	f	f	8	full	\N	\N	\N	f	\N	\N	\N
153	themes	site_url	cast-json	input-code	{"lineNumber":false}	\N	\N	f	f	11	full	\N	\N	\N	f	\N	\N	\N
155	themes	main_url	cast-json	input-code	{"lineNumber":false}	\N	\N	f	f	12	full	\N	\N	\N	f	\N	\N	\N
159	themes	keywords	cast-json	input-code	{"lineNumber":false}	\N	\N	f	f	16	full	\N	\N	\N	f	\N	\N	\N
160	themes	favorites_mode	cast-boolean	boolean	\N	\N	\N	f	f	17	full	\N	\N	\N	f	\N	\N	\N
161	themes	explorer_mode	cast-boolean	boolean	\N	\N	\N	f	f	18	full	\N	\N	\N	f	\N	\N	\N
162	projects	default_country	\N	select-dropdown	{"choices":[{"text":"fr","value":"fr"},{"text":"es","value":"es"}]}	\N	\N	f	f	9	full	\N	\N	\N	f	\N	\N	\N
163	projects	default_country_state_opening_hours	\N	select-dropdown	{"choices":[{"text":"Nouvelle-Aquitaine","value":"Nouvelle-Aquitaine"}]}	\N	\N	f	f	10	full	\N	\N	\N	f	\N	\N	\N
166	pois	slugs	cast-json	input-code	{"lineNumber":false}	\N	\N	f	f	6	full	\N	\N	\N	f	\N	\N	\N
167	menu_items	slugs	cast-json	input-code	{"lineNumber":false}	\N	\N	f	f	4	full	\N	\N	\N	f	\N	\N	\N
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
-- Data for Name: directus_flows; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_flows (id, name, icon, color, description, status, trigger, accountability, options, operation, date_created, user_created) FROM stdin;
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
34	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	projects	update	{"_and":[{"id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	polygon,slug,attributions,bbox_line,name,icon_font_css_url,id,themes,articles,default_country_state_opening_hours,default_country
35	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	themes	update	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	id,name,main_url,project_id,description,logo_url,slug,site_url,favicon_url,root_menu_item_id,keywords,explorer_mode,favorites_mode
41	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	themes	delete	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	\N
42	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items	create	{}	{}	\N	*
43	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	menu_items	read	{"_and":[{"theme_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	project_id,theme_id,index_order,selected_by_default,id,parent_id,hidden,category_id,items,menu_group_id,slug,name,UI,color,icon,behavior,display_mode,category,style_merge,zoom,style_class,search_indexed,sources,link,href,filters,color_line,color_fill,accordion-xkp6bl,menu_group,style_class_string,type,popup_fields_id,list_fields_id,details_fields_id,slugs
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
86	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	fields	read	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	id,accordion-9juoos,group_block,fields,project_id,icon,group,field,type,display_mode
87	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	fields	update	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	id,accordion-9juoos,group_block,display_mode,icon,group,field,type,project_id,fields
88	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	fields	delete	{"_and":[{"project_id":{"_eq":"$CURRENT_USER.project_id"}}]}	\N	\N	\N
89	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	fields_fields	read	{"_and":[{"fields_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	id,related_fields_id,index,fields_id
90	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	fields_fields	update	{"_and":[{"fields_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	id,related_fields_id,index,fields_id
91	5979e2ac-a34f-4c70-bf9d-de48b3900a8f	fields_fields	delete	{"_and":[{"fields_id":{"project_id":{"_eq":"$CURRENT_USER.project_id"}}}]}	\N	\N	\N
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
\.


--
-- Data for Name: directus_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_settings (id, project_name, project_url, project_color, project_logo, public_foreground, public_background, public_note, auth_login_attempts, auth_password_policy, storage_asset_transform, storage_asset_presets, custom_css, storage_default_folder, basemaps, mapbox_key, module_bar, project_descriptor, default_language, custom_aspect_ratios) FROM stdin;
1	Elasa	\N	\N	\N	\N	\N	\N	25	\N	all	\N	\N	\N	\N	\N	[{"type":"module","id":"content","enabled":true},{"type":"module","id":"users","enabled":true},{"type":"module","id":"files","enabled":false},{"type":"module","id":"insights","enabled":false},{"type":"module","id":"settings","enabled":true,"locked":true}]	\N	en-US	\N
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

SELECT pg_catalog.setval('public.directus_fields_id_seq', 167, true);


--
-- Name: directus_notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_notifications_id_seq', 1, false);


--
-- Name: directus_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_permissions_id_seq', 91, true);


--
-- Name: directus_presets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_presets_id_seq', 1, true);


--
-- Name: directus_relations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_relations_id_seq', 33, true);


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

