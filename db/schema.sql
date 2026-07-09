\restrict dbmate

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

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
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: federationlevel; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.federationlevel AS ENUM (
    'full',
    'explorative',
    'blocked'
);


--
-- Name: item_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.item_type_enum AS ENUM (
    'text',
    'media',
    'article'
);


--
-- Name: log_level; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.log_level AS ENUM (
    'info',
    'warn',
    'error',
    'debug'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: instances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instances (
    id uuid NOT NULL,
    name text NOT NULL,
    shared_secret bytea,
    exchange public.federationlevel,
    reason text
);


--
-- Name: TABLE instances; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.instances IS 'Stores local and federated instance details, tracking trust and timeline exchange states.';


--
-- Name: COLUMN instances.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.instances.id IS 'Internal UUID used by the local instance to identify this specific instance.';


--
-- Name: COLUMN instances.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.instances.name IS 'The unique domain name of the federated instance.';


--
-- Name: COLUMN instances.shared_secret; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.instances.shared_secret IS 'The HMAC symmetric federation secret. Generated on first true federation; NULLed if trust breaks.';


--
-- Name: COLUMN instances.exchange; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.instances.exchange IS 'Federation level is set to one of: full, explorative, or blocked. When NULL, acts like explorative but if the other instance decides to ask for full federation, may prompt an admin to upgrade to full. (if admin dismisses this, it becomes explorative.)';


--
-- Name: COLUMN instances.reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.instances.reason IS 'Administrative or automated explanation for why the exchange state was set to FALSE.';


--
-- Name: items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.items (
    id uuid NOT NULL,
    item_type public.item_type_enum,
    author_id bytea NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE items; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.items IS 'All items and their types are linked over this table, items are polymorphic which makes this table able to provide proper forwards.';


--
-- Name: logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.logs (
    id bigint NOT NULL,
    level public.log_level,
    namespace text,
    message text NOT NULL,
    variables jsonb,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.logs_id_seq OWNED BY public.logs.id;


--
-- Name: post_article; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_article (
    id uuid NOT NULL,
    title text NOT NULL,
    content text NOT NULL,
    foreign_post_id uuid
);


--
-- Name: post_media; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_media (
    id uuid NOT NULL,
    upload_id text NOT NULL,
    caption text,
    foreign_post_id uuid
);


--
-- Name: post_text; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_text (
    id uuid NOT NULL,
    content text NOT NULL,
    foreign_post_id uuid
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: timelines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.timelines (
    tlid uuid NOT NULL,
    item_id uuid NOT NULL,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bytea NOT NULL,
    private_key bytea,
    instance_id uuid NOT NULL,
    email text,
    username text NOT NULL,
    password text
);


--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.users IS 'Stores all users the instance knows about.';


--
-- Name: COLUMN users.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.id IS 'The public key of this user, combined with the instance_id this means we can lookup a user instantly, but even without, we can verify the users signed messages as it also is a ed25519 public key.';


--
-- Name: COLUMN users.private_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.private_key IS 'The ed25519 private key of a local user, used to sign important changes and, if requested, also posts and edits.';


--
-- Name: COLUMN users.instance_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.instance_id IS 'The instance id of this user.';


--
-- Name: COLUMN users.email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.email IS 'The email address of a local user, for administration purposes.';


--
-- Name: COLUMN users.username; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.username IS 'The user-set and human-readable name for a user. For local users this contains only a username, for non-local users this is to be post-fixed with "@<instance-name>".';


--
-- Name: COLUMN users.password; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.password IS 'The password has of a local user, for authentication.';


--
-- Name: usersessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usersessions (
    id uuid NOT NULL,
    user_id bytea NOT NULL,
    session_key text NOT NULL,
    last_touched timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE usersessions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.usersessions IS 'User sessions are not to be confused with the Session Store ETS table, user sessions refer to logged in sessions. However, the "id" used here, refers to the SessionStore entry.';


--
-- Name: COLUMN usersessions.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.usersessions.id IS 'Session id as found in the SessionStore ETS table and in browser cookies.';


--
-- Name: COLUMN usersessions.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.usersessions.user_id IS 'The user logged in to this session.';


--
-- Name: COLUMN usersessions.session_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.usersessions.session_key IS 'Secret hash that on match allows a session to be revived. Upon successful revival, the id is replaced with the id of the session that revived the user session.';


--
-- Name: COLUMN usersessions.last_touched; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.usersessions.last_touched IS 'Changed on INSERT or UPDATE to allow garbage cleanup of user sessions if they are older than 30 days.';


--
-- Name: logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs ALTER COLUMN id SET DEFAULT nextval('public.logs_id_seq'::regclass);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: post_article post_article_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_article
    ADD CONSTRAINT post_article_pkey PRIMARY KEY (id);


--
-- Name: post_media post_media_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_media
    ADD CONSTRAINT post_media_pkey PRIMARY KEY (id);


--
-- Name: post_text post_text_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_text
    ADD CONSTRAINT post_text_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: timelines timelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timelines
    ADD CONSTRAINT timelines_pkey PRIMARY KEY (tlid, item_id);


--
-- Name: users unique_username_per_instance; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT unique_username_per_instance UNIQUE (username, instance_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: usersessions usersessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usersessions
    ADD CONSTRAINT usersessions_pkey PRIMARY KEY (id);


--
-- Name: usersessions usersessions_session_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usersessions
    ADD CONSTRAINT usersessions_session_key_key UNIQUE (session_key);


--
-- Name: idx_items_author; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_items_author ON public.items USING btree (author_id);


--
-- Name: idx_timelines_ts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_timelines_ts ON public.timelines USING btree ("timestamp");


--
-- Name: idx_users_instance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_instance ON public.users USING btree (instance_id);


--
-- Name: items items_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: post_article post_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_article
    ADD CONSTRAINT post_article_id_fkey FOREIGN KEY (id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: post_media post_media_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_media
    ADD CONSTRAINT post_media_id_fkey FOREIGN KEY (id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: post_text post_text_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_text
    ADD CONSTRAINT post_text_id_fkey FOREIGN KEY (id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: timelines timelines_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timelines
    ADD CONSTRAINT timelines_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: users users_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.instances(id) ON DELETE CASCADE;


--
-- Name: usersessions usersessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usersessions
    ADD CONSTRAINT usersessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict dbmate


--
-- Dbmate schema migrations
--

INSERT INTO public.schema_migrations (version) VALUES
    ('20260704175437');
