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
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.projects (id, icon_font_css_url, polygon, name, slug) VALUES (1, 'https://example.com/font-teritorio/dist/teritorio.css?ver=2.7.0', '0103000020E610000001000000160000000000000008A3F8BFBFB7A8454DC2454000000000802BF8BF836BC9D99EC2454000000000D897F7BF8FDA4D02A5C045400000000098D8F6BFEC2AA6A7FCBE454000000000408BF6BF2E1A103D32BE45400000000040AAF5BF12F142F0F0BD454000000000D093F4BF05BE41E352BE45400000000040E8F3BFDA537B70CFC0454000000000F0CEF3BF1436B6D8E4C145400000000060D7F3BF14D4C9644AC64540000000008020F4BFB7EA98DD43C84540000000003042F5BFCE29BAE4E6C8454000000000E082F5BFF47278677ECA45400000000090C3F5BF1B5BC6DE72CB4540000000002402F6BFC59375F564CE4540000000000E54F6BFE781887253CF454000000000B89AF6BF2E0926AB38CE4540000000007EB6F6BF914CC5EA90CB454000000000D0DCF6BFE608827E73C945400000000080D1F7BFA4CC088905CC45400000000040F3F7BF33A371CE5DCA45400000000008A3F8BFBFB7A8454DC24540', '{"fr":"test"}', 'test');


--
-- Data for Name: filters; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: junction_directus_roles_undefined; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: themes; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.themes (id, project_id, slug, name, description, site_url, main_url, logo_url, favicon_url, root_menu_item_id) VALUES (1, 1, 'theme', '{"fr": "Carte et points d''intérêts du Seignanx. Sud-Ouest des Landes"}', '{"fr": "Carte et annuaire : hébergement, restauration, loisirs, sports, balades et commerces"}', '{"fr":"https://carte.seignanx.com/"}', '{"fr":"https://www.seignanx.com/"}', '"https://carte.seignanx.com/content/wp-content/uploads/2022/02/seignanx-com.png"', 'https://carte.seignanx.com/content/wp-content/uploads/2022/03/Favicon.jpg', NULL);


--
-- Data for Name: menu_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.menu_items (id, index_order, hidden, selected_by_default, parent_id, theme_id, slug, name, icon, display_mode, search_indexed, style_merge, zoom, color_fill, color_line, href, style_class_string, type) VALUES (1, 0, false, false, NULL, 1, NULL, '{"en":"Root","fr":"Racine"}', '', 'compact', NULL, true, NULL, '', '', NULL, NULL, 'menu_group');
INSERT INTO public.menu_items (id, index_order, hidden, selected_by_default, parent_id, theme_id, slug, name, icon, display_mode, search_indexed, style_merge, zoom, color_fill, color_line, href, style_class_string, type) VALUES (2, 1, false, false, 1, 1, NULL, '{"fr":"Bloc Recherche"}', '', 'compact', NULL, true, NULL, '', '', NULL, NULL, 'menu_group');
INSERT INTO public.menu_items (id, index_order, hidden, selected_by_default, parent_id, theme_id, slug, name, icon, display_mode, search_indexed, style_merge, zoom, color_fill, color_line, href, style_class_string, type) VALUES (3, 2, true, false, 2, 1, NULL, '{"fr":"Recherche"}', '', 'compact', NULL, true, NULL, '', '', NULL, NULL, 'search');
INSERT INTO public.menu_items (id, index_order, hidden, selected_by_default, parent_id, theme_id, slug, name, icon, display_mode, search_indexed, style_merge, zoom, color_fill, color_line, href, style_class_string, type) VALUES (4, 3, false, false, 1, 1, NULL, '{"fr":"bloc poi"}', '', 'compact', NULL, true, NULL, '', '', NULL, NULL, 'menu_group');
INSERT INTO public.menu_items (id, index_order, hidden, selected_by_default, parent_id, theme_id, slug, name, icon, display_mode, search_indexed, style_merge, zoom, color_fill, color_line, href, style_class_string, type) VALUES (5, 4, false, false, 4, 1, NULL, '{"fr":"Hébergement"}', 'teritorio teritorio-hosting', 'compact', NULL, true, NULL, '#99163a', '#99163a', NULL, NULL, 'category');


--
-- Data for Name: menu_items_childrens; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: menu_items_filters; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: sources; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.sources (id, project_id, slug, name, attribution) VALUES (1, 1, 'agences_immobilieres', '{"fr": "agences_immobilieres"}', 'Sirtaqui');


--
-- Data for Name: menu_items_sources; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.menu_items_sources (id, menu_items_id, sources_id) VALUES (1, 5, 1);


--
-- Data for Name: pois; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.pois (id, geom, properties, source_id) VALUES (1, '0101000020E6100000C0B167CF652AF7BF01E951A7F2C74540', '{"id": "ORGAQU040FS0002W", "tags": {"ref": {"FR:CRTA": "ORGAQU040FS0002W"}, "addr": {"city": "ONDRES", "street": "2066 avenue du 11 novembre 1918", "postcode": "40440"}, "name": {"fr": "Agence Tout L''Immobilier"}, "description": {"fr": "Tout l’Immobilier – <b>Ondres</b>\nL’agence Tout l’Immobilier est implantée à Ondres depuis 2007.\nLes valeurs fondamentales de cette entreprise sont la qualité de service et la satisfaction client. L’objectif de toute l’équipe est de vous accompagner dans une relation de confiance pour vos futurs projets d’achat, de vente, de gestion et de location de la Côte Sud Landes jusqu’à la Côte Basque."}}, "source": "Sirtaqui", "updated_at": "2023-06-06T11:06:49", "refs": ["ORGAQU040FS0002W-ref1"]}', 1);
INSERT INTO public.pois (id, geom, properties, source_id) VALUES (2, '0101000020E6100000C0B167CF652AF7BF01E951A7F2C74540', '{"id": "ORGAQU040FS0002W-ref1", "tags": {"name": {"fr": "ref"}}, "source": "Sirtaqui", "updated_at": "2023-06-06T11:06:49"}', 1);


--
-- Data for Name: property_labels; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: filters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.filters_id_seq', 1, true);


--
-- Name: junction_directus_roles_undefined_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.junction_directus_roles_undefined_id_seq', 1, false);


--
-- Name: menu_items_childrens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.menu_items_childrens_id_seq', 1, false);


--
-- Name: menu_items_filters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.menu_items_filters_id_seq', 1, true);


--
-- Name: menu_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.menu_items_id_seq', 6, true);


--
-- Name: menu_items_sources_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.menu_items_sources_id_seq', 2, true);


--
-- Name: projects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_id_seq', 2, true);


--
-- Name: sources_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sources_id_seq', 2, true);


--
-- Name: themes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.themes_id_seq', 2, true);


--
-- PostgreSQL database dump complete
--

UPDATE public.themes SET root_menu_item_id = 1 WHERE id = 1;
