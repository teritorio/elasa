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

ALTER TABLE ONLY public.themes DROP CONSTRAINT themes_root_menu_item_id_foreign;
ALTER TABLE ONLY public.pois DROP CONSTRAINT pois_source_id_foreign;
ALTER TABLE ONLY public.menu_items DROP CONSTRAINT menu_items_theme_id_foreign;
ALTER TABLE ONLY public.menu_items_sources DROP CONSTRAINT menu_items_sources_sources_id_foreign;
ALTER TABLE ONLY public.menu_items_sources DROP CONSTRAINT menu_items_sources_menu_items_id_foreign;
ALTER TABLE ONLY public.menu_items DROP CONSTRAINT menu_items_parent_id_foreign;
ALTER TABLE ONLY public.sources DROP CONSTRAINT menu_items_fk_project_id;
ALTER TABLE ONLY public.themes DROP CONSTRAINT menu_items_fk_project_id;
ALTER TABLE ONLY public.menu_items_filters DROP CONSTRAINT menu_items_filters_menu_items_id_foreign;
ALTER TABLE ONLY public.menu_items_filters DROP CONSTRAINT menu_items_filters_filters_id_foreign;
ALTER TABLE ONLY public.filters DROP CONSTRAINT filters_project_id_foreign;
ALTER TABLE ONLY public.themes DROP CONSTRAINT themes_project_id_slug_key;
ALTER TABLE ONLY public.themes DROP CONSTRAINT themes_pkey;
ALTER TABLE ONLY public.sources DROP CONSTRAINT sources_pkey;
ALTER TABLE ONLY public.property_labels DROP CONSTRAINT property_labels_pkey;
ALTER TABLE ONLY public.projects DROP CONSTRAINT projects_slug_unique;
ALTER TABLE ONLY public.projects DROP CONSTRAINT projects_pkey;
ALTER TABLE ONLY public.pois DROP CONSTRAINT pois_pkey;
ALTER TABLE ONLY public.menu_items_sources DROP CONSTRAINT menu_items_sources_pkey;
ALTER TABLE ONLY public.menu_items DROP CONSTRAINT menu_items_pkey;
ALTER TABLE ONLY public.menu_items_filters DROP CONSTRAINT menu_items_filters_pkey;
ALTER TABLE ONLY public.menu_items_childrens DROP CONSTRAINT menu_items_childrens_pkey;
ALTER TABLE ONLY public.junction_directus_roles_undefined DROP CONSTRAINT junction_directus_roles_undefined_pkey;
ALTER TABLE ONLY public.filters DROP CONSTRAINT filters_pkey;
ALTER TABLE public.menu_items_sources ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.menu_items_filters ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.menu_items_childrens ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.junction_directus_roles_undefined ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.filters ALTER COLUMN id DROP DEFAULT;
DROP TABLE public.themes;
DROP TABLE public.sources;
DROP TABLE public.property_labels;
DROP TABLE public.projects;
DROP TABLE public.pois;
DROP SEQUENCE public.menu_items_sources_id_seq;
DROP TABLE public.menu_items_sources;
DROP SEQUENCE public.menu_items_filters_id_seq;
DROP TABLE public.menu_items_filters;
DROP SEQUENCE public.menu_items_childrens_id_seq;
DROP TABLE public.menu_items_childrens;
DROP TABLE public.menu_items;
DROP SEQUENCE public.junction_directus_roles_undefined_id_seq;
DROP TABLE public.junction_directus_roles_undefined;
DROP SEQUENCE public.filters_id_seq;
DROP TABLE public.filters;
DROP TYPE public.menu_item_display_mode_type;
DROP TYPE public.category_filters_type_type;
DROP SCHEMA public;
--
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: category_filters_type_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.category_filters_type_type AS ENUM (
    'multiselection',
    'checkboxes_list',
    'boolean'
);


ALTER TYPE public.category_filters_type_type OWNER TO postgres;

--
-- Name: menu_item_display_mode_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.menu_item_display_mode_type AS ENUM (
    'compact',
    'large'
);


ALTER TYPE public.menu_item_display_mode_type OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: filters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.filters (
    id integer NOT NULL,
    type character varying(255),
    name json,
    property_end character varying(255),
    property_begin character varying(255),
    min integer,
    max integer,
    project_id integer,
    multiselection_property character varying(255),
    checkboxes_list_property character varying(255),
    boolean_property character varying(255),
    number_range_property character varying(255)
);


ALTER TABLE public.filters OWNER TO postgres;

--
-- Name: filters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.filters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.filters_id_seq OWNER TO postgres;

--
-- Name: filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.filters_id_seq OWNED BY public.filters.id;


--
-- Name: junction_directus_roles_undefined; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.junction_directus_roles_undefined (
    id integer NOT NULL,
    directus_roles_id uuid,
    item character varying(255),
    collection character varying(255)
);


ALTER TABLE public.junction_directus_roles_undefined OWNER TO postgres;

--
-- Name: junction_directus_roles_undefined_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.junction_directus_roles_undefined_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.junction_directus_roles_undefined_id_seq OWNER TO postgres;

--
-- Name: junction_directus_roles_undefined_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.junction_directus_roles_undefined_id_seq OWNED BY public.junction_directus_roles_undefined.id;


--
-- Name: menu_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.menu_items (
    id integer NOT NULL,
    index_order smallint NOT NULL,
    hidden boolean DEFAULT false NOT NULL,
    selected_by_default boolean DEFAULT false NOT NULL,
    parent_id integer,
    theme_id integer NOT NULL,
    slug character varying(255),
    name json,
    icon character varying(255),
    display_mode public.menu_item_display_mode_type DEFAULT 'compact'::public.menu_item_display_mode_type NOT NULL,
    search_indexed boolean DEFAULT true,
    style_merge boolean DEFAULT true,
    zoom integer DEFAULT 16,
    color_fill character varying(255),
    color_line character varying(255),
    href character varying(255),
    style_class_string character varying(255),
    style_class character varying[] GENERATED ALWAYS AS (string_to_array((style_class_string)::text, ','::text)) STORED,
    type character varying(255)
);


ALTER TABLE public.menu_items OWNER TO postgres;

--
-- Name: menu_items_childrens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.menu_items_childrens (
    id integer NOT NULL,
    menu_items_id integer,
    item character varying(255),
    collection character varying(255)
);


ALTER TABLE public.menu_items_childrens OWNER TO postgres;

--
-- Name: menu_items_childrens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.menu_items_childrens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_items_childrens_id_seq OWNER TO postgres;

--
-- Name: menu_items_childrens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.menu_items_childrens_id_seq OWNED BY public.menu_items_childrens.id;


--
-- Name: menu_items_filters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.menu_items_filters (
    id integer NOT NULL,
    menu_items_id integer,
    filters_id integer
);


ALTER TABLE public.menu_items_filters OWNER TO postgres;

--
-- Name: menu_items_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.menu_items_filters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_items_filters_id_seq OWNER TO postgres;

--
-- Name: menu_items_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.menu_items_filters_id_seq OWNED BY public.menu_items_filters.id;


--
-- Name: menu_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.menu_items ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.menu_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: menu_items_sources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.menu_items_sources (
    id integer NOT NULL,
    menu_items_id integer,
    sources_id integer
);


ALTER TABLE public.menu_items_sources OWNER TO postgres;

--
-- Name: menu_items_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.menu_items_sources_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_items_sources_id_seq OWNER TO postgres;

--
-- Name: menu_items_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.menu_items_sources_id_seq OWNED BY public.menu_items_sources.id;


--
-- Name: pois; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pois (
    id integer NOT NULL,
    geom public.geometry(Geometry,4326),
    properties jsonb,
    source_id integer
);


ALTER TABLE public.pois OWNER TO postgres;

--
-- Name: pois_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.pois ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.pois_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    icon_font_css_url character varying NOT NULL,
    polygon public.geometry(Polygon,4326),
    bbox_line public.geometry(LineString,4326) GENERATED ALWAYS AS (public.st_makeline(public.st_makepoint(public.st_xmin((polygon)::public.box3d), public.st_ymin((polygon)::public.box3d)), public.st_makepoint(public.st_xmax((polygon)::public.box3d), public.st_ymax((polygon)::public.box3d)))) STORED NOT NULL,
    name json,
    slug character varying(255) DEFAULT NULL::character varying
);


ALTER TABLE public.projects OWNER TO postgres;

--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.projects ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: property_labels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.property_labels (
    property character varying NOT NULL,
    property_label jsonb,
    property_label_details jsonb,
    property_label_popup jsonb,
    property_label_filter jsonb,
    value_labels jsonb,
    value_labels_list jsonb,
    value_labels_popup jsonb
);


ALTER TABLE public.property_labels OWNER TO postgres;

--
-- Name: sources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sources (
    id integer NOT NULL,
    project_id integer NOT NULL,
    slug character varying NOT NULL,
    name jsonb NOT NULL,
    attribution text
);


ALTER TABLE public.sources OWNER TO postgres;

--
-- Name: sources_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.sources ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: themes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.themes (
    id integer NOT NULL,
    project_id integer DEFAULT 0,
    slug character varying NOT NULL,
    name jsonb NOT NULL,
    description jsonb,
    site_url character varying NOT NULL,
    main_url character varying NOT NULL,
    logo_url character varying NOT NULL,
    favicon_url character varying NOT NULL,
    root_menu_item_id integer
);


ALTER TABLE public.themes OWNER TO postgres;

--
-- Name: themes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.themes ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.themes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: filters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters ALTER COLUMN id SET DEFAULT nextval('public.filters_id_seq'::regclass);


--
-- Name: junction_directus_roles_undefined id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.junction_directus_roles_undefined ALTER COLUMN id SET DEFAULT nextval('public.junction_directus_roles_undefined_id_seq'::regclass);


--
-- Name: menu_items_childrens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_childrens ALTER COLUMN id SET DEFAULT nextval('public.menu_items_childrens_id_seq'::regclass);


--
-- Name: menu_items_filters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_filters ALTER COLUMN id SET DEFAULT nextval('public.menu_items_filters_id_seq'::regclass);


--
-- Name: menu_items_sources id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_sources ALTER COLUMN id SET DEFAULT nextval('public.menu_items_sources_id_seq'::regclass);


--
-- Name: filters filters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters
    ADD CONSTRAINT filters_pkey PRIMARY KEY (id);


--
-- Name: junction_directus_roles_undefined junction_directus_roles_undefined_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.junction_directus_roles_undefined
    ADD CONSTRAINT junction_directus_roles_undefined_pkey PRIMARY KEY (id);


--
-- Name: menu_items_childrens menu_items_childrens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_childrens
    ADD CONSTRAINT menu_items_childrens_pkey PRIMARY KEY (id);


--
-- Name: menu_items_filters menu_items_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_filters
    ADD CONSTRAINT menu_items_filters_pkey PRIMARY KEY (id);


--
-- Name: menu_items menu_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);


--
-- Name: menu_items_sources menu_items_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_sources
    ADD CONSTRAINT menu_items_sources_pkey PRIMARY KEY (id);


--
-- Name: pois pois_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pois
    ADD CONSTRAINT pois_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: projects projects_slug_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_slug_unique UNIQUE (slug);


--
-- Name: property_labels property_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_labels
    ADD CONSTRAINT property_labels_pkey PRIMARY KEY (property);


--
-- Name: sources sources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (id);


--
-- Name: themes themes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT themes_pkey PRIMARY KEY (id);


--
-- Name: themes themes_project_id_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT themes_project_id_slug_key UNIQUE (project_id, slug);


--
-- Name: filters filters_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters
    ADD CONSTRAINT filters_project_id_foreign FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: menu_items_filters menu_items_filters_filters_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_filters
    ADD CONSTRAINT menu_items_filters_filters_id_foreign FOREIGN KEY (filters_id) REFERENCES public.filters(id) ON DELETE CASCADE;


--
-- Name: menu_items_filters menu_items_filters_menu_items_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_filters
    ADD CONSTRAINT menu_items_filters_menu_items_id_foreign FOREIGN KEY (menu_items_id) REFERENCES public.menu_items(id) ON DELETE CASCADE;


--
-- Name: themes menu_items_fk_project_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT menu_items_fk_project_id FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: sources menu_items_fk_project_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT menu_items_fk_project_id FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: menu_items menu_items_parent_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_parent_id_foreign FOREIGN KEY (parent_id) REFERENCES public.menu_items(id);


--
-- Name: menu_items_sources menu_items_sources_menu_items_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_sources
    ADD CONSTRAINT menu_items_sources_menu_items_id_foreign FOREIGN KEY (menu_items_id) REFERENCES public.menu_items(id) ON DELETE CASCADE;


--
-- Name: menu_items_sources menu_items_sources_sources_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_sources
    ADD CONSTRAINT menu_items_sources_sources_id_foreign FOREIGN KEY (sources_id) REFERENCES public.sources(id) ON DELETE CASCADE;


--
-- Name: menu_items menu_items_theme_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_theme_id_foreign FOREIGN KEY (theme_id) REFERENCES public.themes(id) ON DELETE CASCADE;


--
-- Name: pois pois_source_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pois
    ADD CONSTRAINT pois_source_id_foreign FOREIGN KEY (source_id) REFERENCES public.sources(id) ON DELETE CASCADE;


--
-- Name: themes themes_root_menu_item_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT themes_root_menu_item_id_foreign FOREIGN KEY (root_menu_item_id) REFERENCES public.menu_items(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

