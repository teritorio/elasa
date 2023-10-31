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

ALTER TABLE IF EXISTS ONLY public.translations DROP CONSTRAINT IF EXISTS translations_project_id_foreign;
ALTER TABLE IF EXISTS ONLY public.themes DROP CONSTRAINT IF EXISTS themes_root_menu_item_id_foreign;
ALTER TABLE IF EXISTS ONLY public.pois DROP CONSTRAINT IF EXISTS pois_source_id_foreign;
ALTER TABLE IF EXISTS ONLY public.menu_items DROP CONSTRAINT IF EXISTS menu_items_theme_id_foreign;
ALTER TABLE IF EXISTS ONLY public.menu_items_sources DROP CONSTRAINT IF EXISTS menu_items_sources_sources_id_foreign;
ALTER TABLE IF EXISTS ONLY public.menu_items_sources DROP CONSTRAINT IF EXISTS menu_items_sources_menu_items_id_foreign;
ALTER TABLE IF EXISTS ONLY public.menu_items DROP CONSTRAINT IF EXISTS menu_items_popup_fields_id_foreign;
ALTER TABLE IF EXISTS ONLY public.menu_items DROP CONSTRAINT IF EXISTS menu_items_parent_id_foreign;
ALTER TABLE IF EXISTS ONLY public.menu_items DROP CONSTRAINT IF EXISTS menu_items_list_fields_id_foreign;
ALTER TABLE IF EXISTS ONLY public.sources DROP CONSTRAINT IF EXISTS menu_items_fk_project_id;
ALTER TABLE IF EXISTS ONLY public.themes DROP CONSTRAINT IF EXISTS menu_items_fk_project_id;
ALTER TABLE IF EXISTS ONLY public.menu_items_filters DROP CONSTRAINT IF EXISTS menu_items_filters_menu_items_id_foreign;
ALTER TABLE IF EXISTS ONLY public.menu_items_filters DROP CONSTRAINT IF EXISTS menu_items_filters_filters_id_foreign;
ALTER TABLE IF EXISTS ONLY public.menu_items DROP CONSTRAINT IF EXISTS menu_items_details_fields_id_foreign;
ALTER TABLE IF EXISTS ONLY public.filters DROP CONSTRAINT IF EXISTS filters_project_id_foreign;
ALTER TABLE IF EXISTS ONLY public.fields DROP CONSTRAINT IF EXISTS fields_project_id_foreign;
ALTER TABLE IF EXISTS ONLY public.fields_fields DROP CONSTRAINT IF EXISTS fields_fields_related_fields_id_foreign;
ALTER TABLE IF EXISTS ONLY public.fields_fields DROP CONSTRAINT IF EXISTS fields_fields_fields_id_foreign;
DROP INDEX IF EXISTS public.pois_idx_source_id;
DROP INDEX IF EXISTS public.pois_idx_slug_original_id_integer;
DROP INDEX IF EXISTS public.fields_fields_idx_fields_id;
ALTER TABLE IF EXISTS ONLY public.translations DROP CONSTRAINT IF EXISTS translations_pkey;
ALTER TABLE IF EXISTS ONLY public.translations DROP CONSTRAINT IF EXISTS translation_uniq_project_id_key;
ALTER TABLE IF EXISTS ONLY public.themes DROP CONSTRAINT IF EXISTS themes_project_id_slug_key;
ALTER TABLE IF EXISTS ONLY public.themes DROP CONSTRAINT IF EXISTS themes_pkey;
ALTER TABLE IF EXISTS ONLY public.sources DROP CONSTRAINT IF EXISTS sources_pkey;
ALTER TABLE IF EXISTS ONLY public.property_labels DROP CONSTRAINT IF EXISTS property_labels_pkey;
ALTER TABLE IF EXISTS ONLY public.projects DROP CONSTRAINT IF EXISTS projects_slug_unique;
ALTER TABLE IF EXISTS ONLY public.projects DROP CONSTRAINT IF EXISTS projects_pkey;
ALTER TABLE IF EXISTS ONLY public.pois DROP CONSTRAINT IF EXISTS pois_pkey;
ALTER TABLE IF EXISTS ONLY public.menu_items_sources DROP CONSTRAINT IF EXISTS menu_items_sources_pkey;
ALTER TABLE IF EXISTS ONLY public.menu_items DROP CONSTRAINT IF EXISTS menu_items_pkey;
ALTER TABLE IF EXISTS ONLY public.menu_items_filters DROP CONSTRAINT IF EXISTS menu_items_filters_pkey;
ALTER TABLE IF EXISTS ONLY public.menu_items_childrens DROP CONSTRAINT IF EXISTS menu_items_childrens_pkey;
ALTER TABLE IF EXISTS ONLY public.junction_directus_roles_undefined DROP CONSTRAINT IF EXISTS junction_directus_roles_undefined_pkey;
ALTER TABLE IF EXISTS ONLY public.filters DROP CONSTRAINT IF EXISTS filters_pkey;
ALTER TABLE IF EXISTS ONLY public.fields DROP CONSTRAINT IF EXISTS fields_project_id_field_group_key;
ALTER TABLE IF EXISTS ONLY public.fields DROP CONSTRAINT IF EXISTS fields_pkey;
ALTER TABLE IF EXISTS ONLY public.fields_fields DROP CONSTRAINT IF EXISTS fields_fields_pkey;
ALTER TABLE IF EXISTS public.translations ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.menu_items_sources ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.menu_items_filters ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.menu_items_childrens ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.junction_directus_roles_undefined ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.filters ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.fields_fields ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.fields ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.translations_id_seq;
DROP TABLE IF EXISTS public.translations;
DROP TABLE IF EXISTS public.themes;
DROP TABLE IF EXISTS public.sources;
DROP TABLE IF EXISTS public.property_labels;
DROP TABLE IF EXISTS public.projects;
DROP TABLE IF EXISTS public.pois;
DROP SEQUENCE IF EXISTS public.menu_items_sources_id_seq;
DROP TABLE IF EXISTS public.menu_items_sources;
DROP SEQUENCE IF EXISTS public.menu_items_filters_id_seq;
DROP TABLE IF EXISTS public.menu_items_filters;
DROP SEQUENCE IF EXISTS public.menu_items_childrens_id_seq;
DROP TABLE IF EXISTS public.menu_items_childrens;
DROP TABLE IF EXISTS public.menu_items;
DROP SEQUENCE IF EXISTS public.junction_directus_roles_undefined_id_seq;
DROP TABLE IF EXISTS public.junction_directus_roles_undefined;
DROP SEQUENCE IF EXISTS public.filters_id_seq;
DROP TABLE IF EXISTS public.filters;
DROP SEQUENCE IF EXISTS public.fields_id_seq;
DROP SEQUENCE IF EXISTS public.fields_fields_id_seq;
DROP TABLE IF EXISTS public.fields_fields;
DROP TABLE IF EXISTS public.fields;
DROP TYPE IF EXISTS public.menu_item_display_mode_type;
DROP TYPE IF EXISTS public.category_filters_type_type;
DROP SCHEMA IF EXISTS public;
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
-- Name: fields; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fields (
    id integer NOT NULL,
    type character varying(255) DEFAULT NULL::character varying NOT NULL,
    field character varying(255),
    "group" character varying(255),
    display_mode character varying(255),
    icon character varying(255),
    project_id integer NOT NULL,
    label boolean DEFAULT false
);


ALTER TABLE public.fields OWNER TO postgres;

--
-- Name: fields_fields; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fields_fields (
    id integer NOT NULL,
    fields_id integer NOT NULL,
    related_fields_id integer NOT NULL,
    index integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.fields_fields OWNER TO postgres;

--
-- Name: fields_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fields_fields_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fields_fields_id_seq OWNER TO postgres;

--
-- Name: fields_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fields_fields_id_seq OWNED BY public.fields_fields.id;


--
-- Name: fields_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fields_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fields_id_seq OWNER TO postgres;

--
-- Name: fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fields_id_seq OWNED BY public.fields.id;


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
    project_id integer NOT NULL,
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
    type character varying(255),
    popup_fields_id integer,
    details_fields_id integer,
    list_fields_id integer,
    slugs json NOT NULL,
    name_singular json
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
    source_id integer,
    slugs json
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
    slug character varying(255) DEFAULT NULL::character varying,
    articles json,
    default_country character varying(255),
    default_country_state_opening_hours character varying(255),
    polygons_extra json
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
    project_id integer DEFAULT 0 NOT NULL,
    slug character varying NOT NULL,
    name jsonb NOT NULL,
    description jsonb,
    logo_url character varying NOT NULL,
    favicon_url character varying NOT NULL,
    root_menu_item_id integer,
    site_url json NOT NULL,
    main_url json NOT NULL,
    keywords json,
    favorites_mode boolean DEFAULT true,
    explorer_mode boolean DEFAULT true
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
-- Name: translations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.translations (
    id integer NOT NULL,
    project_id integer NOT NULL,
    key character varying(255) DEFAULT NULL::character varying NOT NULL,
    key_translations json NOT NULL,
    values_translations json
);


ALTER TABLE public.translations OWNER TO postgres;

--
-- Name: translations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.translations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.translations_id_seq OWNER TO postgres;

--
-- Name: translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.translations_id_seq OWNED BY public.translations.id;


--
-- Name: fields id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields ALTER COLUMN id SET DEFAULT nextval('public.fields_id_seq'::regclass);


--
-- Name: fields_fields id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields_fields ALTER COLUMN id SET DEFAULT nextval('public.fields_fields_id_seq'::regclass);


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
-- Name: translations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.translations ALTER COLUMN id SET DEFAULT nextval('public.translations_id_seq'::regclass);


--
-- Name: fields_fields fields_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields_fields
    ADD CONSTRAINT fields_fields_pkey PRIMARY KEY (id);


--
-- Name: fields fields_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields
    ADD CONSTRAINT fields_pkey PRIMARY KEY (id);


--
-- Name: fields fields_project_id_field_group_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields
    ADD CONSTRAINT fields_project_id_field_group_key UNIQUE (project_id, field, "group");


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
-- Name: translations translation_uniq_project_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.translations
    ADD CONSTRAINT translation_uniq_project_id_key UNIQUE (project_id, key);


--
-- Name: translations translations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.translations
    ADD CONSTRAINT translations_pkey PRIMARY KEY (id);


--
-- Name: fields_fields_idx_fields_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fields_fields_idx_fields_id ON public.fields_fields USING btree (fields_id);


--
-- Name: pois_idx_slug_original_id_integer; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pois_idx_slug_original_id_integer ON public.pois USING btree (((slugs ->> 'original_id'::text)));


--
-- Name: pois_idx_source_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pois_idx_source_id ON public.pois USING btree (source_id);


--
-- Name: fields_fields fields_fields_fields_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields_fields
    ADD CONSTRAINT fields_fields_fields_id_foreign FOREIGN KEY (fields_id) REFERENCES public.fields(id) ON DELETE CASCADE;


--
-- Name: fields_fields fields_fields_related_fields_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields_fields
    ADD CONSTRAINT fields_fields_related_fields_id_foreign FOREIGN KEY (related_fields_id) REFERENCES public.fields(id) ON DELETE CASCADE;


--
-- Name: fields fields_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields
    ADD CONSTRAINT fields_project_id_foreign FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: filters filters_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters
    ADD CONSTRAINT filters_project_id_foreign FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: menu_items menu_items_details_fields_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_details_fields_id_foreign FOREIGN KEY (details_fields_id) REFERENCES public.fields(id) ON DELETE SET NULL;


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
-- Name: menu_items menu_items_list_fields_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_list_fields_id_foreign FOREIGN KEY (list_fields_id) REFERENCES public.fields(id) ON DELETE SET NULL;


--
-- Name: menu_items menu_items_parent_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_parent_id_foreign FOREIGN KEY (parent_id) REFERENCES public.menu_items(id);


--
-- Name: menu_items menu_items_popup_fields_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_popup_fields_id_foreign FOREIGN KEY (popup_fields_id) REFERENCES public.fields(id) ON DELETE SET NULL;


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
-- Name: translations translations_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.translations
    ADD CONSTRAINT translations_project_id_foreign FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

