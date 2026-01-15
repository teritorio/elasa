--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4 (Debian 17.4-1.pgdg110+2)
-- Dumped by pg_dump version 17.4 (Debian 17.4-1.pgdg110+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--



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

--
-- Name: jsonb_pois_keys_array(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_pois_keys_array(jsonb) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $_$
    SELECT array_agg(jsonb_object_keys) FROM (
        SELECT * FROM jsonb_object_keys($1->'tags')
        UNION ALL
        SELECT * FROM jsonb_object_keys($1->'natives')
    ) AS t
$_$;


ALTER FUNCTION public.jsonb_pois_keys_array(jsonb) OWNER TO postgres;

--
-- Name: jsonb_to_text_array(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_to_text_array(j jsonb) RETURNS text[]
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $$ SELECT array_agg(key || '=' || value) FROM jsonb_each_text(j) $$;


ALTER FUNCTION public.jsonb_to_text_array(j jsonb) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: pois; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pois (
    id integer NOT NULL,
    geom public.geometry(Geometry,4326),
    properties jsonb,
    source_id integer,
    slugs json,
    website_details text,
    properties_id text GENERATED ALWAYS AS ((properties ->> 'id'::text)) STORED,
    properties_tags_name text GENERATED ALWAYS AS (((properties -> 'tags'::text) ->> 'name'::text)) STORED
);


ALTER TABLE public.pois OWNER TO postgres;

--
-- Name: pois_pois; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pois_pois (
    id integer NOT NULL,
    parent_pois_id integer NOT NULL,
    children_pois_id integer NOT NULL,
    index integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.pois_pois OWNER TO postgres;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.ar_internal_metadata OWNER TO postgres;

--
-- Name: articles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.articles (
    id integer NOT NULL,
    project_id integer NOT NULL
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
-- Name: directus_access; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_access (
    id uuid NOT NULL,
    role uuid,
    "user" uuid,
    policy uuid NOT NULL,
    sort integer
);


ALTER TABLE public.directus_access OWNER TO postgres;

--
-- Name: directus_activity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_activity (
    id integer NOT NULL,
    action character varying(45) NOT NULL,
    "user" uuid,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ip character varying(50),
    user_agent text,
    collection character varying(64) NOT NULL,
    item character varying(255) NOT NULL,
    origin character varying(255)
);


ALTER TABLE public.directus_activity OWNER TO postgres;

--
-- Name: directus_activity_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_activity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.directus_activity_id_seq OWNER TO postgres;

--
-- Name: directus_activity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_activity_id_seq OWNED BY public.directus_activity.id;


--
-- Name: directus_collections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_collections (
    collection character varying(64) NOT NULL,
    icon character varying(64),
    note text,
    display_template character varying(255),
    hidden boolean DEFAULT false NOT NULL,
    singleton boolean DEFAULT false NOT NULL,
    translations json,
    archive_field character varying(64),
    archive_app_filter boolean DEFAULT true NOT NULL,
    archive_value character varying(255),
    unarchive_value character varying(255),
    sort_field character varying(64),
    accountability character varying(255) DEFAULT 'all'::character varying,
    color character varying(255),
    item_duplication_fields json,
    sort integer,
    "group" character varying(64),
    collapse character varying(255) DEFAULT 'open'::character varying NOT NULL,
    preview_url character varying(255),
    versioning boolean DEFAULT false NOT NULL
);


ALTER TABLE public.directus_collections OWNER TO postgres;

--
-- Name: directus_comments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_comments (
    id uuid NOT NULL,
    collection character varying(64) NOT NULL,
    item character varying(255) NOT NULL,
    comment text NOT NULL,
    date_created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    date_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_created uuid,
    user_updated uuid
);


ALTER TABLE public.directus_comments OWNER TO postgres;

--
-- Name: directus_dashboards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_dashboards (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    icon character varying(64) DEFAULT 'dashboard'::character varying NOT NULL,
    note text,
    date_created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_created uuid,
    color character varying(255)
);


ALTER TABLE public.directus_dashboards OWNER TO postgres;

--
-- Name: directus_extensions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_extensions (
    enabled boolean DEFAULT true NOT NULL,
    id uuid NOT NULL,
    folder character varying(255) NOT NULL,
    source character varying(255) NOT NULL,
    bundle uuid
);


ALTER TABLE public.directus_extensions OWNER TO postgres;

--
-- Name: directus_fields; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_fields (
    id integer NOT NULL,
    collection character varying(64) NOT NULL,
    field character varying(64) NOT NULL,
    special character varying(64),
    interface character varying(64),
    options json,
    display character varying(64),
    display_options json,
    readonly boolean DEFAULT false NOT NULL,
    hidden boolean DEFAULT false NOT NULL,
    sort integer,
    width character varying(30) DEFAULT 'full'::character varying,
    translations json,
    note text,
    conditions json,
    required boolean DEFAULT false,
    "group" character varying(64),
    validation json,
    validation_message text
);


ALTER TABLE public.directus_fields OWNER TO postgres;

--
-- Name: directus_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_fields_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.directus_fields_id_seq OWNER TO postgres;

--
-- Name: directus_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_fields_id_seq OWNED BY public.directus_fields.id;


--
-- Name: directus_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_files (
    id uuid NOT NULL,
    storage character varying(255) NOT NULL,
    filename_disk character varying(255),
    filename_download character varying(255) NOT NULL,
    title character varying(255),
    type character varying(255),
    folder uuid,
    uploaded_by uuid,
    created_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by uuid,
    modified_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    charset character varying(50),
    filesize bigint,
    width integer,
    height integer,
    duration integer,
    embed character varying(200),
    description text,
    location text,
    tags text,
    metadata json,
    focal_point_x integer,
    focal_point_y integer,
    tus_id character varying(64),
    tus_data json,
    project_id integer,
    uploaded_on timestamp with time zone
);


ALTER TABLE public.directus_files OWNER TO postgres;

--
-- Name: directus_flows; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_flows (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    icon character varying(64),
    color character varying(255),
    description text,
    status character varying(255) DEFAULT 'active'::character varying NOT NULL,
    trigger character varying(255),
    accountability character varying(255) DEFAULT 'all'::character varying,
    options json,
    operation uuid,
    date_created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_created uuid
);


ALTER TABLE public.directus_flows OWNER TO postgres;

--
-- Name: directus_folders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_folders (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    parent uuid,
    project_id integer NOT NULL
);


ALTER TABLE public.directus_folders OWNER TO postgres;

--
-- Name: directus_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_migrations (
    version character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.directus_migrations OWNER TO postgres;

--
-- Name: directus_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_notifications (
    id integer NOT NULL,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(255) DEFAULT 'inbox'::character varying,
    recipient uuid NOT NULL,
    sender uuid,
    subject character varying(255) NOT NULL,
    message text,
    collection character varying(64),
    item character varying(255)
);


ALTER TABLE public.directus_notifications OWNER TO postgres;

--
-- Name: directus_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.directus_notifications_id_seq OWNER TO postgres;

--
-- Name: directus_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_notifications_id_seq OWNED BY public.directus_notifications.id;


--
-- Name: directus_operations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_operations (
    id uuid NOT NULL,
    name character varying(255),
    key character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    position_x integer NOT NULL,
    position_y integer NOT NULL,
    options json,
    resolve uuid,
    reject uuid,
    flow uuid NOT NULL,
    date_created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_created uuid
);


ALTER TABLE public.directus_operations OWNER TO postgres;

--
-- Name: directus_panels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_panels (
    id uuid NOT NULL,
    dashboard uuid NOT NULL,
    name character varying(255),
    icon character varying(64) DEFAULT NULL::character varying,
    color character varying(10),
    show_header boolean DEFAULT false NOT NULL,
    note text,
    type character varying(255) NOT NULL,
    position_x integer NOT NULL,
    position_y integer NOT NULL,
    width integer NOT NULL,
    height integer NOT NULL,
    options json,
    date_created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_created uuid
);


ALTER TABLE public.directus_panels OWNER TO postgres;

--
-- Name: directus_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_permissions (
    id integer NOT NULL,
    collection character varying(64) NOT NULL,
    action character varying(10) NOT NULL,
    permissions json,
    validation json,
    presets json,
    fields text,
    policy uuid NOT NULL
);


ALTER TABLE public.directus_permissions OWNER TO postgres;

--
-- Name: directus_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.directus_permissions_id_seq OWNER TO postgres;

--
-- Name: directus_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_permissions_id_seq OWNED BY public.directus_permissions.id;


--
-- Name: directus_policies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_policies (
    id uuid NOT NULL,
    name character varying(100) NOT NULL,
    icon character varying(64) DEFAULT 'badge'::character varying NOT NULL,
    description text,
    ip_access text,
    enforce_tfa boolean DEFAULT false NOT NULL,
    admin_access boolean DEFAULT false NOT NULL,
    app_access boolean DEFAULT false NOT NULL
);


ALTER TABLE public.directus_policies OWNER TO postgres;

--
-- Name: directus_presets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_presets (
    id integer NOT NULL,
    bookmark character varying(255),
    "user" uuid,
    role uuid,
    collection character varying(64),
    search character varying(100),
    layout character varying(100) DEFAULT 'tabular'::character varying,
    layout_query json,
    layout_options json,
    refresh_interval integer,
    filter json,
    icon character varying(64) DEFAULT 'bookmark'::character varying,
    color character varying(255)
);


ALTER TABLE public.directus_presets OWNER TO postgres;

--
-- Name: directus_presets_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_presets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.directus_presets_id_seq OWNER TO postgres;

--
-- Name: directus_presets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_presets_id_seq OWNED BY public.directus_presets.id;


--
-- Name: directus_relations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_relations (
    id integer NOT NULL,
    many_collection character varying(64) NOT NULL,
    many_field character varying(64) NOT NULL,
    one_collection character varying(64),
    one_field character varying(64),
    one_collection_field character varying(64),
    one_allowed_collections text,
    junction_field character varying(64),
    sort_field character varying(64),
    one_deselect_action character varying(255) DEFAULT 'nullify'::character varying NOT NULL
);


ALTER TABLE public.directus_relations OWNER TO postgres;

--
-- Name: directus_relations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_relations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.directus_relations_id_seq OWNER TO postgres;

--
-- Name: directus_relations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_relations_id_seq OWNED BY public.directus_relations.id;


--
-- Name: directus_revisions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_revisions (
    id integer NOT NULL,
    activity integer NOT NULL,
    collection character varying(64) NOT NULL,
    item character varying(255) NOT NULL,
    data json,
    delta json,
    parent integer,
    version uuid
);


ALTER TABLE public.directus_revisions OWNER TO postgres;

--
-- Name: directus_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_revisions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.directus_revisions_id_seq OWNER TO postgres;

--
-- Name: directus_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_revisions_id_seq OWNED BY public.directus_revisions.id;


--
-- Name: directus_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_roles (
    id uuid NOT NULL,
    name character varying(100) NOT NULL,
    icon character varying(64) DEFAULT 'supervised_user_circle'::character varying NOT NULL,
    description text,
    parent uuid
);


ALTER TABLE public.directus_roles OWNER TO postgres;

--
-- Name: directus_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_sessions (
    token character varying(64) NOT NULL,
    "user" uuid,
    expires timestamp with time zone NOT NULL,
    ip character varying(255),
    user_agent text,
    share uuid,
    origin character varying(255),
    next_token character varying(64)
);


ALTER TABLE public.directus_sessions OWNER TO postgres;

--
-- Name: directus_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_settings (
    id integer NOT NULL,
    project_name character varying(100) DEFAULT 'Directus'::character varying NOT NULL,
    project_url character varying(255),
    project_color character varying(255) DEFAULT '#6644FF'::character varying NOT NULL,
    project_logo uuid,
    public_foreground uuid,
    public_background uuid,
    public_note text,
    auth_login_attempts integer DEFAULT 25,
    auth_password_policy character varying(100),
    storage_asset_transform character varying(7) DEFAULT 'all'::character varying,
    storage_asset_presets json,
    custom_css text,
    storage_default_folder uuid,
    basemaps json,
    mapbox_key character varying(255),
    module_bar json,
    project_descriptor character varying(100),
    default_language character varying(255) DEFAULT 'en-US'::character varying NOT NULL,
    custom_aspect_ratios json,
    public_favicon uuid,
    default_appearance character varying(255) DEFAULT 'auto'::character varying NOT NULL,
    default_theme_light character varying(255),
    theme_light_overrides json,
    default_theme_dark character varying(255),
    theme_dark_overrides json,
    report_error_url character varying(255),
    report_bug_url character varying(255),
    report_feature_url character varying(255),
    public_registration boolean DEFAULT false NOT NULL,
    public_registration_verify_email boolean DEFAULT true NOT NULL,
    public_registration_role uuid,
    public_registration_email_filter json,
    visual_editor_urls json
);


ALTER TABLE public.directus_settings OWNER TO postgres;

--
-- Name: directus_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.directus_settings_id_seq OWNER TO postgres;

--
-- Name: directus_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_settings_id_seq OWNED BY public.directus_settings.id;


--
-- Name: directus_shares; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_shares (
    id uuid NOT NULL,
    name character varying(255),
    collection character varying(64) NOT NULL,
    item character varying(255) NOT NULL,
    role uuid,
    password character varying(255),
    user_created uuid,
    date_created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    date_start timestamp with time zone,
    date_end timestamp with time zone,
    times_used integer DEFAULT 0,
    max_uses integer
);


ALTER TABLE public.directus_shares OWNER TO postgres;

--
-- Name: directus_translations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_translations (
    id uuid NOT NULL,
    language character varying(255) NOT NULL,
    key character varying(255) NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.directus_translations OWNER TO postgres;

--
-- Name: directus_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_users (
    id uuid NOT NULL,
    first_name character varying(50),
    last_name character varying(50),
    email character varying(128),
    password character varying(255),
    location character varying(255),
    title character varying(50),
    description text,
    tags json,
    avatar uuid,
    language character varying(255) DEFAULT NULL::character varying,
    tfa_secret character varying(255),
    status character varying(16) DEFAULT 'active'::character varying NOT NULL,
    role uuid,
    token character varying(255),
    last_access timestamp with time zone,
    last_page character varying(255),
    provider character varying(128) DEFAULT 'default'::character varying NOT NULL,
    external_identifier character varying(255),
    auth_data json,
    email_notifications boolean DEFAULT true,
    project_id integer,
    appearance character varying(255),
    theme_dark character varying(255),
    theme_light character varying(255),
    theme_light_overrides json,
    theme_dark_overrides json
);


ALTER TABLE public.directus_users OWNER TO postgres;

--
-- Name: directus_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_versions (
    id uuid NOT NULL,
    key character varying(64) NOT NULL,
    name character varying(255),
    collection character varying(64) NOT NULL,
    item character varying(255) NOT NULL,
    hash character varying(255),
    date_created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    date_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_created uuid,
    user_updated uuid,
    delta json
);


ALTER TABLE public.directus_versions OWNER TO postgres;

--
-- Name: directus_webhooks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_webhooks (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    method character varying(10) DEFAULT 'POST'::character varying NOT NULL,
    url character varying(255) NOT NULL,
    status character varying(10) DEFAULT 'active'::character varying NOT NULL,
    data boolean DEFAULT true NOT NULL,
    actions character varying(100) NOT NULL,
    collections character varying(255) NOT NULL,
    headers json,
    was_active_before_deprecation boolean DEFAULT false NOT NULL,
    migrated_flow uuid
);


ALTER TABLE public.directus_webhooks OWNER TO postgres;

--
-- Name: directus_webhooks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_webhooks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.directus_webhooks_id_seq OWNER TO postgres;

--
-- Name: directus_webhooks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_webhooks_id_seq OWNED BY public.directus_webhooks.id;


--
-- Name: fields; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fields (
    id integer NOT NULL,
    type character varying(255) NOT NULL,
    field character varying(255),
    "group" character varying(255),
    display_mode character varying(255),
    icon character varying(255),
    project_id integer NOT NULL,
    label_large boolean DEFAULT false NOT NULL,
    values_translations json,
    label_small boolean DEFAULT false NOT NULL,
    multilingual boolean,
    media_type character varying,
    role character varying,
    "array" boolean,
    json_schema jsonb
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


ALTER SEQUENCE public.fields_fields_id_seq OWNER TO postgres;

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


ALTER SEQUENCE public.fields_id_seq OWNER TO postgres;

--
-- Name: fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fields_id_seq OWNED BY public.fields.id;


--
-- Name: fields_translations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fields_translations (
    id integer NOT NULL,
    fields_id integer,
    languages_code character varying(255),
    name character varying(255),
    name_small character varying(255),
    name_large character varying(255),
    name_title character varying(255)
);


ALTER TABLE public.fields_translations OWNER TO postgres;

--
-- Name: fields_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fields_translations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fields_translations_id_seq OWNER TO postgres;

--
-- Name: fields_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fields_translations_id_seq OWNED BY public.fields_translations.id;


--
-- Name: filters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.filters (
    id integer NOT NULL,
    type character varying(255),
    min integer,
    max integer,
    project_id integer NOT NULL,
    multiselection_property integer,
    checkboxes_list_property integer,
    boolean_property integer,
    property_begin integer,
    property_end integer,
    number_range_property integer
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


ALTER SEQUENCE public.filters_id_seq OWNER TO postgres;

--
-- Name: filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.filters_id_seq OWNED BY public.filters.id;


--
-- Name: filters_translations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.filters_translations (
    id integer NOT NULL,
    filters_id integer,
    languages_code character varying(255) NOT NULL,
    name character varying(255)
);


ALTER TABLE public.filters_translations OWNER TO postgres;

--
-- Name: filters_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.filters_translations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.filters_translations_id_seq OWNER TO postgres;

--
-- Name: filters_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.filters_translations_id_seq OWNED BY public.filters_translations.id;


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


ALTER SEQUENCE public.junction_directus_roles_undefined_id_seq OWNER TO postgres;

--
-- Name: junction_directus_roles_undefined_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.junction_directus_roles_undefined_id_seq OWNED BY public.junction_directus_roles_undefined.id;


--
-- Name: languages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.languages (
    code character varying(255) NOT NULL,
    name character varying(255),
    direction character varying(255) DEFAULT 'ltr'::character varying
);


ALTER TABLE public.languages OWNER TO postgres;

--
-- Name: menu_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.menu_items (
    id integer NOT NULL,
    index_order smallint DEFAULT 0 NOT NULL,
    hidden boolean DEFAULT false NOT NULL,
    selected_by_default boolean DEFAULT false NOT NULL,
    parent_id integer,
    project_id integer NOT NULL,
    icon character varying(255) NOT NULL,
    display_mode public.menu_item_display_mode_type DEFAULT 'compact'::public.menu_item_display_mode_type NOT NULL,
    search_indexed boolean DEFAULT true,
    style_merge boolean DEFAULT true,
    zoom integer DEFAULT 16,
    color_fill character varying(255),
    color_line character varying(255),
    href character varying(255),
    style_class jsonb,
    type character varying(255),
    popup_fields_id integer,
    details_fields_id integer,
    list_fields_id integer,
    use_internal_details_link boolean DEFAULT true,
    use_external_details_link boolean DEFAULT true
);


ALTER TABLE public.menu_items OWNER TO postgres;

--
-- Name: menu_items_filters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.menu_items_filters (
    id integer NOT NULL,
    menu_items_id integer,
    filters_id integer,
    index integer DEFAULT 1 NOT NULL
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


ALTER SEQUENCE public.menu_items_filters_id_seq OWNER TO postgres;

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


ALTER SEQUENCE public.menu_items_sources_id_seq OWNER TO postgres;

--
-- Name: menu_items_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.menu_items_sources_id_seq OWNED BY public.menu_items_sources.id;


--
-- Name: menu_items_translations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.menu_items_translations (
    id integer NOT NULL,
    menu_items_id integer,
    languages_code character varying(255) NOT NULL,
    name character varying(255),
    slug character varying(255),
    name_singular character varying(255)
);


ALTER TABLE public.menu_items_translations OWNER TO postgres;

--
-- Name: menu_items_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.menu_items_translations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.menu_items_translations_id_seq OWNER TO postgres;

--
-- Name: menu_items_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.menu_items_translations_id_seq OWNED BY public.menu_items_translations.id;


--
-- Name: pois_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pois_files (
    id integer NOT NULL,
    pois_id integer NOT NULL,
    directus_files_id uuid NOT NULL,
    index integer NOT NULL
);


ALTER TABLE public.pois_files OWNER TO postgres;

--
-- Name: pois_files_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pois_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pois_files_id_seq OWNER TO postgres;

--
-- Name: pois_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pois_files_id_seq OWNED BY public.pois_files.id;


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
-- Name: pois_pois_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pois_pois_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pois_pois_id_seq OWNER TO postgres;

--
-- Name: pois_pois_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pois_pois_id_seq OWNED BY public.pois_pois.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    icon_font_css_url character varying NOT NULL,
    polygon public.geometry(Geometry,4326),
    bbox_line public.geometry(LineString,4326),
    slug character varying(255) NOT NULL,
    default_country character varying(255),
    default_country_state_opening_hours character varying(255),
    polygons_extra json,
    datasources_slug character varying(255),
    api_key uuid DEFAULT gen_random_uuid() NOT NULL,
    image_proxy_hosts jsonb
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
-- Name: projects_translations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_translations (
    id integer NOT NULL,
    projects_id integer,
    languages_code character varying(255) NOT NULL,
    name character varying(255)
);


ALTER TABLE public.projects_translations OWNER TO postgres;

--
-- Name: projects_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_translations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_translations_id_seq OWNER TO postgres;

--
-- Name: projects_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_translations_id_seq OWNED BY public.projects_translations.id;


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
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO postgres;

--
-- Name: sources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sources (
    id integer NOT NULL,
    project_id integer NOT NULL,
    slug character varying NOT NULL,
    attribution text,
    report_issue jsonb,
    extends_source_id integer
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
-- Name: sources_translations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sources_translations (
    id integer NOT NULL,
    sources_id integer,
    languages_code character varying(255) NOT NULL,
    name character varying(255)
);


ALTER TABLE public.sources_translations OWNER TO postgres;

--
-- Name: sources_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sources_translations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sources_translations_id_seq OWNER TO postgres;

--
-- Name: sources_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sources_translations_id_seq OWNED BY public.sources_translations.id;


--
-- Name: themes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.themes (
    id integer NOT NULL,
    project_id integer NOT NULL,
    slug character varying NOT NULL,
    root_menu_item_id integer,
    favorites_mode boolean DEFAULT true,
    explorer_mode boolean DEFAULT true,
    logo uuid,
    favicon uuid,
    isochrone boolean DEFAULT false,
    map_style_base_url character varying(255) NOT NULL,
    map_style_satellite_url character varying(255) NOT NULL,
    map_bicycle_style_url character varying(255),
    matomo_url character varying(255),
    matomo_siteid character varying(255),
    google_site_verification character varying(255),
    google_tag_manager_id character varying(255),
    cookies_usage_detail_url character varying(255),
    report_issue boolean DEFAULT false
);


ALTER TABLE public.themes OWNER TO postgres;

--
-- Name: themes_articles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.themes_articles (
    id integer NOT NULL,
    articles_id integer,
    index integer,
    themes_id integer NOT NULL
);


ALTER TABLE public.themes_articles OWNER TO postgres;

--
-- Name: themes_articles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.themes_articles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.themes_articles_id_seq OWNER TO postgres;

--
-- Name: themes_articles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.themes_articles_id_seq OWNED BY public.themes_articles.id;


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
-- Name: themes_translations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.themes_translations (
    id integer NOT NULL,
    themes_id integer,
    languages_code character varying(255) NOT NULL,
    name character varying(255),
    description character varying(255),
    site_url character varying(255),
    main_url character varying(255),
    keywords character varying(255),
    cookies_consent_message text
);


ALTER TABLE public.themes_translations OWNER TO postgres;

--
-- Name: themes_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.themes_translations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.themes_translations_id_seq OWNER TO postgres;

--
-- Name: themes_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.themes_translations_id_seq OWNED BY public.themes_translations.id;


--
-- Name: articles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles ALTER COLUMN id SET DEFAULT nextval('public.articles_id_seq'::regclass);


--
-- Name: articles_translations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles_translations ALTER COLUMN id SET DEFAULT nextval('public.articles_translations_id_seq'::regclass);


--
-- Name: directus_activity id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_activity ALTER COLUMN id SET DEFAULT nextval('public.directus_activity_id_seq'::regclass);


--
-- Name: directus_fields id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_fields ALTER COLUMN id SET DEFAULT nextval('public.directus_fields_id_seq'::regclass);


--
-- Name: directus_notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_notifications ALTER COLUMN id SET DEFAULT nextval('public.directus_notifications_id_seq'::regclass);


--
-- Name: directus_permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_permissions ALTER COLUMN id SET DEFAULT nextval('public.directus_permissions_id_seq'::regclass);


--
-- Name: directus_presets id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_presets ALTER COLUMN id SET DEFAULT nextval('public.directus_presets_id_seq'::regclass);


--
-- Name: directus_relations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_relations ALTER COLUMN id SET DEFAULT nextval('public.directus_relations_id_seq'::regclass);


--
-- Name: directus_revisions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_revisions ALTER COLUMN id SET DEFAULT nextval('public.directus_revisions_id_seq'::regclass);


--
-- Name: directus_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_settings ALTER COLUMN id SET DEFAULT nextval('public.directus_settings_id_seq'::regclass);


--
-- Name: directus_webhooks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_webhooks ALTER COLUMN id SET DEFAULT nextval('public.directus_webhooks_id_seq'::regclass);


--
-- Name: fields id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields ALTER COLUMN id SET DEFAULT nextval('public.fields_id_seq'::regclass);


--
-- Name: fields_fields id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields_fields ALTER COLUMN id SET DEFAULT nextval('public.fields_fields_id_seq'::regclass);


--
-- Name: fields_translations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields_translations ALTER COLUMN id SET DEFAULT nextval('public.fields_translations_id_seq'::regclass);


--
-- Name: filters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters ALTER COLUMN id SET DEFAULT nextval('public.filters_id_seq'::regclass);


--
-- Name: filters_translations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters_translations ALTER COLUMN id SET DEFAULT nextval('public.filters_translations_id_seq'::regclass);


--
-- Name: junction_directus_roles_undefined id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.junction_directus_roles_undefined ALTER COLUMN id SET DEFAULT nextval('public.junction_directus_roles_undefined_id_seq'::regclass);


--
-- Name: menu_items_filters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_filters ALTER COLUMN id SET DEFAULT nextval('public.menu_items_filters_id_seq'::regclass);


--
-- Name: menu_items_sources id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_sources ALTER COLUMN id SET DEFAULT nextval('public.menu_items_sources_id_seq'::regclass);


--
-- Name: menu_items_translations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_translations ALTER COLUMN id SET DEFAULT nextval('public.menu_items_translations_id_seq'::regclass);


--
-- Name: pois_files id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pois_files ALTER COLUMN id SET DEFAULT nextval('public.pois_files_id_seq'::regclass);


--
-- Name: pois_pois id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pois_pois ALTER COLUMN id SET DEFAULT nextval('public.pois_pois_id_seq'::regclass);


--
-- Name: projects_translations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_translations ALTER COLUMN id SET DEFAULT nextval('public.projects_translations_id_seq'::regclass);


--
-- Name: sources_translations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources_translations ALTER COLUMN id SET DEFAULT nextval('public.sources_translations_id_seq'::regclass);


--
-- Name: themes_articles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes_articles ALTER COLUMN id SET DEFAULT nextval('public.themes_articles_id_seq'::regclass);


--
-- Name: themes_translations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes_translations ALTER COLUMN id SET DEFAULT nextval('public.themes_translations_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


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
-- Name: directus_access directus_access_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_access
    ADD CONSTRAINT directus_access_pkey PRIMARY KEY (id);


--
-- Name: directus_activity directus_activity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_activity
    ADD CONSTRAINT directus_activity_pkey PRIMARY KEY (id);


--
-- Name: directus_collections directus_collections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_collections
    ADD CONSTRAINT directus_collections_pkey PRIMARY KEY (collection);


--
-- Name: directus_comments directus_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_comments
    ADD CONSTRAINT directus_comments_pkey PRIMARY KEY (id);


--
-- Name: directus_dashboards directus_dashboards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_dashboards
    ADD CONSTRAINT directus_dashboards_pkey PRIMARY KEY (id);


--
-- Name: directus_extensions directus_extensions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_extensions
    ADD CONSTRAINT directus_extensions_pkey PRIMARY KEY (id);


--
-- Name: directus_fields directus_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_fields
    ADD CONSTRAINT directus_fields_pkey PRIMARY KEY (id);


--
-- Name: directus_files directus_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_files
    ADD CONSTRAINT directus_files_pkey PRIMARY KEY (id);


--
-- Name: directus_flows directus_flows_operation_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_flows
    ADD CONSTRAINT directus_flows_operation_unique UNIQUE (operation);


--
-- Name: directus_flows directus_flows_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_flows
    ADD CONSTRAINT directus_flows_pkey PRIMARY KEY (id);


--
-- Name: directus_folders directus_folders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_folders
    ADD CONSTRAINT directus_folders_pkey PRIMARY KEY (id);


--
-- Name: directus_migrations directus_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_migrations
    ADD CONSTRAINT directus_migrations_pkey PRIMARY KEY (version);


--
-- Name: directus_notifications directus_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_notifications
    ADD CONSTRAINT directus_notifications_pkey PRIMARY KEY (id);


--
-- Name: directus_operations directus_operations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_operations
    ADD CONSTRAINT directus_operations_pkey PRIMARY KEY (id);


--
-- Name: directus_operations directus_operations_reject_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_operations
    ADD CONSTRAINT directus_operations_reject_unique UNIQUE (reject);


--
-- Name: directus_operations directus_operations_resolve_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_operations
    ADD CONSTRAINT directus_operations_resolve_unique UNIQUE (resolve);


--
-- Name: directus_panels directus_panels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_panels
    ADD CONSTRAINT directus_panels_pkey PRIMARY KEY (id);


--
-- Name: directus_permissions directus_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_permissions
    ADD CONSTRAINT directus_permissions_pkey PRIMARY KEY (id);


--
-- Name: directus_policies directus_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_policies
    ADD CONSTRAINT directus_policies_pkey PRIMARY KEY (id);


--
-- Name: directus_presets directus_presets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_presets
    ADD CONSTRAINT directus_presets_pkey PRIMARY KEY (id);


--
-- Name: directus_relations directus_relations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_relations
    ADD CONSTRAINT directus_relations_pkey PRIMARY KEY (id);


--
-- Name: directus_revisions directus_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_revisions
    ADD CONSTRAINT directus_revisions_pkey PRIMARY KEY (id);


--
-- Name: directus_roles directus_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_roles
    ADD CONSTRAINT directus_roles_pkey PRIMARY KEY (id);


--
-- Name: directus_sessions directus_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_sessions
    ADD CONSTRAINT directus_sessions_pkey PRIMARY KEY (token);


--
-- Name: directus_settings directus_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_pkey PRIMARY KEY (id);


--
-- Name: directus_shares directus_shares_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_shares
    ADD CONSTRAINT directus_shares_pkey PRIMARY KEY (id);


--
-- Name: directus_translations directus_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_translations
    ADD CONSTRAINT directus_translations_pkey PRIMARY KEY (id);


--
-- Name: directus_users directus_users_email_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_users
    ADD CONSTRAINT directus_users_email_unique UNIQUE (email);


--
-- Name: directus_users directus_users_external_identifier_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_users
    ADD CONSTRAINT directus_users_external_identifier_unique UNIQUE (external_identifier);


--
-- Name: directus_users directus_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_users
    ADD CONSTRAINT directus_users_pkey PRIMARY KEY (id);


--
-- Name: directus_users directus_users_token_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_users
    ADD CONSTRAINT directus_users_token_unique UNIQUE (token);


--
-- Name: directus_versions directus_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_versions
    ADD CONSTRAINT directus_versions_pkey PRIMARY KEY (id);


--
-- Name: directus_webhooks directus_webhooks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_webhooks
    ADD CONSTRAINT directus_webhooks_pkey PRIMARY KEY (id);


--
-- Name: fields_fields fields_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields_fields
    ADD CONSTRAINT fields_fields_pkey PRIMARY KEY (id);


--
-- Name: fields_fields fields_fields_uniq_fields_id_related_fields_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields_fields
    ADD CONSTRAINT fields_fields_uniq_fields_id_related_fields_id UNIQUE (fields_id, related_fields_id);


--
-- Name: fields fields_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields
    ADD CONSTRAINT fields_pkey PRIMARY KEY (id);


--
-- Name: fields_translations fields_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields_translations
    ADD CONSTRAINT fields_translations_pkey PRIMARY KEY (id);


--
-- Name: fields_translations fields_translations_uniq_fields_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields_translations
    ADD CONSTRAINT fields_translations_uniq_fields_id UNIQUE (fields_id, languages_code);


--
-- Name: fields fields_uniq_field_group; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields
    ADD CONSTRAINT fields_uniq_field_group UNIQUE NULLS NOT DISTINCT (project_id, "group", field);


--
-- Name: filters filters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters
    ADD CONSTRAINT filters_pkey PRIMARY KEY (id);


--
-- Name: filters_translations filters_translations_filter_id_languages_code; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters_translations
    ADD CONSTRAINT filters_translations_filter_id_languages_code UNIQUE (filters_id, languages_code);


--
-- Name: filters_translations filters_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters_translations
    ADD CONSTRAINT filters_translations_pkey PRIMARY KEY (id);


--
-- Name: junction_directus_roles_undefined junction_directus_roles_undefined_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.junction_directus_roles_undefined
    ADD CONSTRAINT junction_directus_roles_undefined_pkey PRIMARY KEY (id);


--
-- Name: languages languages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (code);


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
-- Name: menu_items_translations menu_items_translations_menu_item_id_languages_code; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_translations
    ADD CONSTRAINT menu_items_translations_menu_item_id_languages_code UNIQUE (menu_items_id, languages_code);


--
-- Name: menu_items_translations menu_items_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_translations
    ADD CONSTRAINT menu_items_translations_pkey PRIMARY KEY (id);


--
-- Name: pois_files pois_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pois_files
    ADD CONSTRAINT pois_files_pkey PRIMARY KEY (id);


--
-- Name: pois_files pois_files_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pois_files
    ADD CONSTRAINT pois_files_uniq UNIQUE (pois_id, directus_files_id);


--
-- Name: pois pois_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pois
    ADD CONSTRAINT pois_pkey PRIMARY KEY (id);


--
-- Name: pois_pois pois_pois_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pois_pois
    ADD CONSTRAINT pois_pois_pkey PRIMARY KEY (id);


--
-- Name: pois_pois pois_pois_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pois_pois
    ADD CONSTRAINT pois_pois_uniq UNIQUE (parent_pois_id, children_pois_id);


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
-- Name: projects_translations projects_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_translations
    ADD CONSTRAINT projects_translations_pkey PRIMARY KEY (id);


--
-- Name: projects_translations projects_translations_project_id_languages_code; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_translations
    ADD CONSTRAINT projects_translations_project_id_languages_code UNIQUE (projects_id, languages_code);


--
-- Name: property_labels property_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_labels
    ADD CONSTRAINT property_labels_pkey PRIMARY KEY (property);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sources sources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (id);


--
-- Name: sources_translations sources_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources_translations
    ADD CONSTRAINT sources_translations_pkey PRIMARY KEY (id);


--
-- Name: sources_translations sources_translations_sources_id_languages_code; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources_translations
    ADD CONSTRAINT sources_translations_sources_id_languages_code UNIQUE (sources_id, languages_code);


--
-- Name: themes_articles themes_articles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes_articles
    ADD CONSTRAINT themes_articles_pkey PRIMARY KEY (id);


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
-- Name: themes_translations themes_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes_translations
    ADD CONSTRAINT themes_translations_pkey PRIMARY KEY (id);


--
-- Name: themes_translations themes_translations_theme_id_languages_code; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes_translations
    ADD CONSTRAINT themes_translations_theme_id_languages_code UNIQUE (themes_id, languages_code);


--
-- Name: fields_fields_idx_fields_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fields_fields_idx_fields_id ON public.fields_fields USING btree (fields_id);


--
-- Name: menu_items_filters_idx_menu_items_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX menu_items_filters_idx_menu_items_id ON public.menu_items_filters USING btree (menu_items_id);


--
-- Name: pois_idx_geom; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pois_idx_geom ON public.pois USING gist (geom);


--
-- Name: pois_idx_ref; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pois_idx_ref ON public.pois USING gin ((((properties -> 'tags'::text) -> 'ref'::text))) WHERE ((properties -> 'tags'::text) ? 'ref'::text);


--
-- Name: pois_idx_ref_flat; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pois_idx_ref_flat ON public.pois USING gin (public.jsonb_to_text_array(((properties -> 'tags'::text) -> 'ref'::text))) WHERE ((properties -> 'tags'::text) ? 'ref'::text);


--
-- Name: pois_idx_slug_original_id_integer; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pois_idx_slug_original_id_integer ON public.pois USING btree (((slugs ->> 'original_id'::text)));


--
-- Name: pois_idx_source_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pois_idx_source_id ON public.pois USING btree (source_id);


--
-- Name: pois_keys_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pois_keys_idx ON public.pois USING gin (public.jsonb_pois_keys_array(properties));


--
-- Name: articles articles_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_project_id_foreign FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


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
-- Name: directus_access directus_access_policy_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_access
    ADD CONSTRAINT directus_access_policy_foreign FOREIGN KEY (policy) REFERENCES public.directus_policies(id) ON DELETE CASCADE;


--
-- Name: directus_access directus_access_role_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_access
    ADD CONSTRAINT directus_access_role_foreign FOREIGN KEY (role) REFERENCES public.directus_roles(id) ON DELETE CASCADE;


--
-- Name: directus_access directus_access_user_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_access
    ADD CONSTRAINT directus_access_user_foreign FOREIGN KEY ("user") REFERENCES public.directus_users(id) ON DELETE CASCADE;


--
-- Name: directus_collections directus_collections_group_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_collections
    ADD CONSTRAINT directus_collections_group_foreign FOREIGN KEY ("group") REFERENCES public.directus_collections(collection);


--
-- Name: directus_comments directus_comments_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_comments
    ADD CONSTRAINT directus_comments_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id) ON DELETE SET NULL;


--
-- Name: directus_comments directus_comments_user_updated_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_comments
    ADD CONSTRAINT directus_comments_user_updated_foreign FOREIGN KEY (user_updated) REFERENCES public.directus_users(id);


--
-- Name: directus_dashboards directus_dashboards_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_dashboards
    ADD CONSTRAINT directus_dashboards_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id) ON DELETE SET NULL;


--
-- Name: directus_files directus_files_folder_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_files
    ADD CONSTRAINT directus_files_folder_foreign FOREIGN KEY (folder) REFERENCES public.directus_folders(id) ON DELETE SET NULL;


--
-- Name: directus_files directus_files_modified_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_files
    ADD CONSTRAINT directus_files_modified_by_foreign FOREIGN KEY (modified_by) REFERENCES public.directus_users(id);


--
-- Name: directus_files directus_files_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_files
    ADD CONSTRAINT directus_files_project_id_foreign FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: directus_files directus_files_uploaded_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_files
    ADD CONSTRAINT directus_files_uploaded_by_foreign FOREIGN KEY (uploaded_by) REFERENCES public.directus_users(id);


--
-- Name: directus_flows directus_flows_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_flows
    ADD CONSTRAINT directus_flows_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id) ON DELETE SET NULL;


--
-- Name: directus_folders directus_folders_parent_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_folders
    ADD CONSTRAINT directus_folders_parent_foreign FOREIGN KEY (parent) REFERENCES public.directus_folders(id);


--
-- Name: directus_folders directus_folders_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_folders
    ADD CONSTRAINT directus_folders_project_id_foreign FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: directus_notifications directus_notifications_recipient_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_notifications
    ADD CONSTRAINT directus_notifications_recipient_foreign FOREIGN KEY (recipient) REFERENCES public.directus_users(id) ON DELETE CASCADE;


--
-- Name: directus_notifications directus_notifications_sender_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_notifications
    ADD CONSTRAINT directus_notifications_sender_foreign FOREIGN KEY (sender) REFERENCES public.directus_users(id);


--
-- Name: directus_operations directus_operations_flow_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_operations
    ADD CONSTRAINT directus_operations_flow_foreign FOREIGN KEY (flow) REFERENCES public.directus_flows(id) ON DELETE CASCADE;


--
-- Name: directus_operations directus_operations_reject_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_operations
    ADD CONSTRAINT directus_operations_reject_foreign FOREIGN KEY (reject) REFERENCES public.directus_operations(id);


--
-- Name: directus_operations directus_operations_resolve_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_operations
    ADD CONSTRAINT directus_operations_resolve_foreign FOREIGN KEY (resolve) REFERENCES public.directus_operations(id);


--
-- Name: directus_operations directus_operations_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_operations
    ADD CONSTRAINT directus_operations_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id) ON DELETE SET NULL;


--
-- Name: directus_panels directus_panels_dashboard_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_panels
    ADD CONSTRAINT directus_panels_dashboard_foreign FOREIGN KEY (dashboard) REFERENCES public.directus_dashboards(id) ON DELETE CASCADE;


--
-- Name: directus_panels directus_panels_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_panels
    ADD CONSTRAINT directus_panels_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id) ON DELETE SET NULL;


--
-- Name: directus_permissions directus_permissions_policy_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_permissions
    ADD CONSTRAINT directus_permissions_policy_foreign FOREIGN KEY (policy) REFERENCES public.directus_policies(id) ON DELETE CASCADE;


--
-- Name: directus_presets directus_presets_role_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_presets
    ADD CONSTRAINT directus_presets_role_foreign FOREIGN KEY (role) REFERENCES public.directus_roles(id) ON DELETE CASCADE;


--
-- Name: directus_presets directus_presets_user_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_presets
    ADD CONSTRAINT directus_presets_user_foreign FOREIGN KEY ("user") REFERENCES public.directus_users(id) ON DELETE CASCADE;


--
-- Name: directus_revisions directus_revisions_activity_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_revisions
    ADD CONSTRAINT directus_revisions_activity_foreign FOREIGN KEY (activity) REFERENCES public.directus_activity(id) ON DELETE CASCADE;


--
-- Name: directus_revisions directus_revisions_parent_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_revisions
    ADD CONSTRAINT directus_revisions_parent_foreign FOREIGN KEY (parent) REFERENCES public.directus_revisions(id);


--
-- Name: directus_revisions directus_revisions_version_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_revisions
    ADD CONSTRAINT directus_revisions_version_foreign FOREIGN KEY (version) REFERENCES public.directus_versions(id) ON DELETE CASCADE;


--
-- Name: directus_roles directus_roles_parent_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_roles
    ADD CONSTRAINT directus_roles_parent_foreign FOREIGN KEY (parent) REFERENCES public.directus_roles(id);


--
-- Name: directus_sessions directus_sessions_share_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_sessions
    ADD CONSTRAINT directus_sessions_share_foreign FOREIGN KEY (share) REFERENCES public.directus_shares(id) ON DELETE CASCADE;


--
-- Name: directus_sessions directus_sessions_user_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_sessions
    ADD CONSTRAINT directus_sessions_user_foreign FOREIGN KEY ("user") REFERENCES public.directus_users(id) ON DELETE CASCADE;


--
-- Name: directus_settings directus_settings_project_logo_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_project_logo_foreign FOREIGN KEY (project_logo) REFERENCES public.directus_files(id);


--
-- Name: directus_settings directus_settings_public_background_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_public_background_foreign FOREIGN KEY (public_background) REFERENCES public.directus_files(id);


--
-- Name: directus_settings directus_settings_public_favicon_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_public_favicon_foreign FOREIGN KEY (public_favicon) REFERENCES public.directus_files(id);


--
-- Name: directus_settings directus_settings_public_foreground_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_public_foreground_foreign FOREIGN KEY (public_foreground) REFERENCES public.directus_files(id);


--
-- Name: directus_settings directus_settings_public_registration_role_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_public_registration_role_foreign FOREIGN KEY (public_registration_role) REFERENCES public.directus_roles(id) ON DELETE SET NULL;


--
-- Name: directus_settings directus_settings_storage_default_folder_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_storage_default_folder_foreign FOREIGN KEY (storage_default_folder) REFERENCES public.directus_folders(id) ON DELETE SET NULL;


--
-- Name: directus_shares directus_shares_collection_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_shares
    ADD CONSTRAINT directus_shares_collection_foreign FOREIGN KEY (collection) REFERENCES public.directus_collections(collection) ON DELETE CASCADE;


--
-- Name: directus_shares directus_shares_role_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_shares
    ADD CONSTRAINT directus_shares_role_foreign FOREIGN KEY (role) REFERENCES public.directus_roles(id) ON DELETE CASCADE;


--
-- Name: directus_shares directus_shares_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_shares
    ADD CONSTRAINT directus_shares_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id) ON DELETE SET NULL;


--
-- Name: directus_users directus_users_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_users
    ADD CONSTRAINT directus_users_project_id_foreign FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;


--
-- Name: directus_users directus_users_role_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_users
    ADD CONSTRAINT directus_users_role_foreign FOREIGN KEY (role) REFERENCES public.directus_roles(id) ON DELETE SET NULL;


--
-- Name: directus_versions directus_versions_collection_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_versions
    ADD CONSTRAINT directus_versions_collection_foreign FOREIGN KEY (collection) REFERENCES public.directus_collections(collection) ON DELETE CASCADE;


--
-- Name: directus_versions directus_versions_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_versions
    ADD CONSTRAINT directus_versions_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id) ON DELETE SET NULL;


--
-- Name: directus_versions directus_versions_user_updated_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_versions
    ADD CONSTRAINT directus_versions_user_updated_foreign FOREIGN KEY (user_updated) REFERENCES public.directus_users(id);


--
-- Name: directus_webhooks directus_webhooks_migrated_flow_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_webhooks
    ADD CONSTRAINT directus_webhooks_migrated_flow_foreign FOREIGN KEY (migrated_flow) REFERENCES public.directus_flows(id) ON DELETE SET NULL;


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
-- Name: fields_translations fields_translations_fields_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields_translations
    ADD CONSTRAINT fields_translations_fields_id_foreign FOREIGN KEY (fields_id) REFERENCES public.fields(id) ON DELETE SET NULL;


--
-- Name: fields_translations fields_translations_languages_code_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fields_translations
    ADD CONSTRAINT fields_translations_languages_code_foreign FOREIGN KEY (languages_code) REFERENCES public.languages(code) ON DELETE SET NULL;


--
-- Name: filters filters_boolean_property_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters
    ADD CONSTRAINT filters_boolean_property_foreign FOREIGN KEY (boolean_property) REFERENCES public.fields(id) ON DELETE SET NULL;


--
-- Name: filters filters_checkboxes_list_property_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters
    ADD CONSTRAINT filters_checkboxes_list_property_foreign FOREIGN KEY (checkboxes_list_property) REFERENCES public.fields(id) ON DELETE SET NULL;


--
-- Name: filters filters_multiselection_property_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters
    ADD CONSTRAINT filters_multiselection_property_foreign FOREIGN KEY (multiselection_property) REFERENCES public.fields(id) ON DELETE SET NULL;


--
-- Name: filters filters_number_range_property_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters
    ADD CONSTRAINT filters_number_range_property_foreign FOREIGN KEY (number_range_property) REFERENCES public.fields(id) ON DELETE SET NULL;


--
-- Name: filters filters_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters
    ADD CONSTRAINT filters_project_id_foreign FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: filters filters_property_begin_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters
    ADD CONSTRAINT filters_property_begin_foreign FOREIGN KEY (property_begin) REFERENCES public.fields(id) ON DELETE SET NULL;


--
-- Name: filters filters_property_end_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters
    ADD CONSTRAINT filters_property_end_foreign FOREIGN KEY (property_end) REFERENCES public.fields(id) ON DELETE SET NULL;


--
-- Name: filters_translations filters_translations_filters_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters_translations
    ADD CONSTRAINT filters_translations_filters_id_foreign FOREIGN KEY (filters_id) REFERENCES public.filters(id) ON DELETE CASCADE;


--
-- Name: filters_translations filters_translations_languages_code_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filters_translations
    ADD CONSTRAINT filters_translations_languages_code_foreign FOREIGN KEY (languages_code) REFERENCES public.languages(code) ON DELETE CASCADE;


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
-- Name: sources menu_items_fk_project_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT menu_items_fk_project_id FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: themes menu_items_fk_project_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes
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
-- Name: menu_items menu_items_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_project_id_foreign FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


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
-- Name: menu_items_translations menu_items_translations_languages_code_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_translations
    ADD CONSTRAINT menu_items_translations_languages_code_foreign FOREIGN KEY (languages_code) REFERENCES public.languages(code) ON DELETE CASCADE;


--
-- Name: menu_items_translations menu_items_translations_menu_items_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items_translations
    ADD CONSTRAINT menu_items_translations_menu_items_id_foreign FOREIGN KEY (menu_items_id) REFERENCES public.menu_items(id) ON DELETE CASCADE;


--
-- Name: pois_files pois_files_directus_files_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pois_files
    ADD CONSTRAINT pois_files_directus_files_id_foreign FOREIGN KEY (directus_files_id) REFERENCES public.directus_files(id) ON DELETE CASCADE;


--
-- Name: pois_files pois_files_pois_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pois_files
    ADD CONSTRAINT pois_files_pois_id_foreign FOREIGN KEY (pois_id) REFERENCES public.pois(id) ON DELETE CASCADE;


--
-- Name: pois_pois pois_pois_children_pois_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pois_pois
    ADD CONSTRAINT pois_pois_children_pois_id_fkey FOREIGN KEY (children_pois_id) REFERENCES public.pois(id) ON DELETE CASCADE;


--
-- Name: pois_pois pois_pois_parent_pois_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pois_pois
    ADD CONSTRAINT pois_pois_parent_pois_id_fkey FOREIGN KEY (parent_pois_id) REFERENCES public.pois(id) ON DELETE CASCADE;


--
-- Name: pois pois_source_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pois
    ADD CONSTRAINT pois_source_id_foreign FOREIGN KEY (source_id) REFERENCES public.sources(id) ON DELETE CASCADE;


--
-- Name: projects_translations projects_translations_languages_code_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_translations
    ADD CONSTRAINT projects_translations_languages_code_foreign FOREIGN KEY (languages_code) REFERENCES public.languages(code) ON DELETE CASCADE;


--
-- Name: projects_translations projects_translations_projects_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_translations
    ADD CONSTRAINT projects_translations_projects_id_foreign FOREIGN KEY (projects_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: sources sources_extends_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT sources_extends_source_id_fkey FOREIGN KEY (extends_source_id) REFERENCES public.sources(id);


--
-- Name: sources_translations sources_translations_languages_code_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources_translations
    ADD CONSTRAINT sources_translations_languages_code_foreign FOREIGN KEY (languages_code) REFERENCES public.languages(code) ON DELETE CASCADE;


--
-- Name: sources_translations sources_translations_sources_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources_translations
    ADD CONSTRAINT sources_translations_sources_id_foreign FOREIGN KEY (sources_id) REFERENCES public.sources(id) ON DELETE CASCADE;


--
-- Name: themes_articles themes_articles_articles_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes_articles
    ADD CONSTRAINT themes_articles_articles_id_foreign FOREIGN KEY (articles_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: themes_articles themes_articles_themes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes_articles
    ADD CONSTRAINT themes_articles_themes_id_fkey FOREIGN KEY (themes_id) REFERENCES public.themes(id);


--
-- Name: themes themes_favicon_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT themes_favicon_foreign FOREIGN KEY (favicon) REFERENCES public.directus_files(id);


--
-- Name: themes themes_logo_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT themes_logo_foreign FOREIGN KEY (logo) REFERENCES public.directus_files(id);


--
-- Name: themes themes_root_menu_item_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT themes_root_menu_item_id_foreign FOREIGN KEY (root_menu_item_id) REFERENCES public.menu_items(id) ON DELETE SET NULL;


--
-- Name: themes_translations themes_translations_languages_code_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes_translations
    ADD CONSTRAINT themes_translations_languages_code_foreign FOREIGN KEY (languages_code) REFERENCES public.languages(code) ON DELETE CASCADE;


--
-- Name: themes_translations themes_translations_themes_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes_translations
    ADD CONSTRAINT themes_translations_themes_id_foreign FOREIGN KEY (themes_id) REFERENCES public.themes(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

