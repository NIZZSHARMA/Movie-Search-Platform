-- C2: Add the application framework to the existing movie database.
-- Run after B2 and before 02_user_functions.sql.
-- Existing framework schemas are left unchanged; repeating is a no-op.
-- Movie tables and movie data are not modified.
BEGIN;
DO $build_framework$
BEGIN
    IF to_regclass('movie.title') IS NULL OR to_regclass('movie.person') IS NULL THEN
        RAISE EXCEPTION 'Run B2 first: movie.title and movie.person are required';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'framework') THEN
        RAISE NOTICE 'framework schema already exists; build skipped.';
        RETURN;
    END IF;
    EXECUTE $framework_sql$
CREATE SCHEMA framework;

CREATE TABLE framework.app_user (
    user_id bigint NOT NULL,
    username text NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL
);

ALTER TABLE framework.app_user ALTER COLUMN user_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME framework.app_user_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE framework.title_rating_history (
    event_id bigint NOT NULL,
    user_id bigint NOT NULL,
    tconst text NOT NULL,
    rating smallint NOT NULL,
    rated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT title_rating_history_rating_check CHECK (((rating >= 1) AND (rating <= 10)))
);

ALTER TABLE framework.title_rating_history ALTER COLUMN event_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME framework.title_rating_history_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE framework.user_bookmark_person (
    user_id bigint NOT NULL,
    nconst text NOT NULL
);

CREATE TABLE framework.user_bookmark_title (
    user_id bigint NOT NULL,
    tconst text NOT NULL
);

CREATE TABLE framework.user_search_history (
    search_id bigint NOT NULL,
    user_id bigint NOT NULL,
    query_text text NOT NULL,
    performed_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE framework.user_search_history ALTER COLUMN search_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME framework.user_search_history_search_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE framework.user_title_rating (
    rating_id bigint NOT NULL,
    user_id bigint NOT NULL,
    tconst text NOT NULL,
    rating smallint NOT NULL,
    rated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT user_title_rating_rating_check CHECK (((rating >= 1) AND (rating <= 10)))
);

ALTER TABLE framework.user_title_rating ALTER COLUMN rating_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME framework.user_title_rating_rating_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

ALTER TABLE ONLY framework.app_user
    ADD CONSTRAINT app_user_email_key UNIQUE (email);

ALTER TABLE ONLY framework.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (user_id);

ALTER TABLE ONLY framework.app_user
    ADD CONSTRAINT app_user_username_key UNIQUE (username);

ALTER TABLE ONLY framework.title_rating_history
    ADD CONSTRAINT title_rating_history_pkey PRIMARY KEY (event_id);

ALTER TABLE ONLY framework.user_bookmark_person
    ADD CONSTRAINT user_bookmark_person_pkey PRIMARY KEY (user_id, nconst);

ALTER TABLE ONLY framework.user_bookmark_title
    ADD CONSTRAINT user_bookmark_title_pkey PRIMARY KEY (user_id, tconst);

ALTER TABLE ONLY framework.user_search_history
    ADD CONSTRAINT user_search_history_pkey PRIMARY KEY (search_id);

ALTER TABLE ONLY framework.user_title_rating
    ADD CONSTRAINT user_title_rating_pkey PRIMARY KEY (rating_id);

ALTER TABLE ONLY framework.user_title_rating
    ADD CONSTRAINT user_title_rating_user_id_tconst_key UNIQUE (user_id, tconst);

ALTER TABLE ONLY framework.title_rating_history
    ADD CONSTRAINT title_rating_history_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);

ALTER TABLE ONLY framework.title_rating_history
    ADD CONSTRAINT title_rating_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES framework.app_user(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY framework.user_bookmark_person
    ADD CONSTRAINT user_bookmark_person_nconst_fkey FOREIGN KEY (nconst) REFERENCES movie.person(nconst);

ALTER TABLE ONLY framework.user_bookmark_person
    ADD CONSTRAINT user_bookmark_person_user_id_fkey FOREIGN KEY (user_id) REFERENCES framework.app_user(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY framework.user_bookmark_title
    ADD CONSTRAINT user_bookmark_title_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);

ALTER TABLE ONLY framework.user_bookmark_title
    ADD CONSTRAINT user_bookmark_title_user_id_fkey FOREIGN KEY (user_id) REFERENCES framework.app_user(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY framework.user_search_history
    ADD CONSTRAINT user_search_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES framework.app_user(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY framework.user_title_rating
    ADD CONSTRAINT user_title_rating_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);

ALTER TABLE ONLY framework.user_title_rating
    ADD CONSTRAINT user_title_rating_user_id_fkey FOREIGN KEY (user_id) REFERENCES framework.app_user(user_id) ON DELETE CASCADE;
$framework_sql$;
END;
$build_framework$;
COMMIT;
