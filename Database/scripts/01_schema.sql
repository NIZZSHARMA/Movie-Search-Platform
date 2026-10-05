--
-- PostgreSQL database dump
--

-- Dumped from database version 17.0
-- Dumped by pg_dump version 17.0

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

-- framework; Type: SCHEMA; Schema: -; Owner: postgres

CREATE SCHEMA framework;


ALTER SCHEMA framework OWNER TO postgres;

-- movie; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA movie;


ALTER SCHEMA movie OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

-- app_user; Type: TABLE; Schema: framework; Owner: postgres

CREATE TABLE framework.app_user (
    user_id bigint NOT NULL,
    username text NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL
);


ALTER TABLE framework.app_user OWNER TO postgres;

-- app_user_user_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres

ALTER TABLE framework.app_user ALTER COLUMN user_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME framework.app_user_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- title_rating_history; Type: TABLE; Schema: framework; Owner: postgres

CREATE TABLE framework.title_rating_history (
    event_id bigint NOT NULL,
    user_id bigint NOT NULL,
    tconst text NOT NULL,
    rating smallint NOT NULL,
    rated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT title_rating_history_rating_check CHECK (((rating >= 1) AND (rating <= 10)))
);


ALTER TABLE framework.title_rating_history OWNER TO postgres;

-- title_rating_history_event_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres


ALTER TABLE framework.title_rating_history ALTER COLUMN event_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME framework.title_rating_history_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--user_bookmark_person; Type: TABLE; Schema: framework; Owner: postgres

CREATE TABLE framework.user_bookmark_person (
    user_id bigint NOT NULL,
    nconst text NOT NULL
);


ALTER TABLE framework.user_bookmark_person OWNER TO postgres;

-- user_bookmark_title; Type: TABLE; Schema: framework; Owner: postgres

CREATE TABLE framework.user_bookmark_title (
    user_id bigint NOT NULL,
    tconst text NOT NULL
);


ALTER TABLE framework.user_bookmark_title OWNER TO postgres;

-- user_search_history; Type: TABLE; Schema: framework; Owner: postgres

CREATE TABLE framework.user_search_history (
    search_id bigint NOT NULL,
    user_id bigint NOT NULL,
    query_text text NOT NULL,
    performed_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE framework.user_search_history OWNER TO postgres;

-- user_search_history_search_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres

ALTER TABLE framework.user_search_history ALTER COLUMN search_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME framework.user_search_history_search_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- user_title_rating; Type: TABLE; Schema: framework; Owner: postgres
CREATE TABLE framework.user_title_rating (
    rating_id bigint NOT NULL,
    user_id bigint NOT NULL,
    tconst text NOT NULL,
    rating smallint NOT NULL,
    rated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT user_title_rating_rating_check CHECK (((rating >= 1) AND (rating <= 10)))
);


ALTER TABLE framework.user_title_rating OWNER TO postgres;

-- user_title_rating_rating_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres

ALTER TABLE framework.user_title_rating ALTER COLUMN rating_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME framework.user_title_rating_rating_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


-- credit; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.credit (
    tconst text NOT NULL,
    ordering integer NOT NULL,
    nconst text NOT NULL,
    category text,
    job text,
    characters text
);


ALTER TABLE movie.credit OWNER TO postgres;

-- credit_character; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.credit_character (
    tconst text NOT NULL,
    ordering integer NOT NULL,
    character_name text NOT NULL COLLATE pg_catalog."C",
    CONSTRAINT credit_character_character_name_check CHECK ((btrim(character_name) <> ''::text))
);


ALTER TABLE movie.credit_character OWNER TO postgres;

-- genre; Type: TABLE; Schema: movie; Owner: postgres
--

CREATE TABLE movie.genre (
    genre text NOT NULL
);


ALTER TABLE movie.genre OWNER TO postgres;

-- omdb_extra; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.omdb_extra (
    tconst text NOT NULL,
    plot text,
    poster text
);


ALTER TABLE movie.omdb_extra OWNER TO postgres;

-- person; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.person (
    nconst text NOT NULL,
    primary_name text,
    birth_year integer,
    death_year integer
);


ALTER TABLE movie.person OWNER TO postgres;

-- person_known_for; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.person_known_for (
    nconst text NOT NULL,
    tconst text NOT NULL
);


ALTER TABLE movie.person_known_for OWNER TO postgres;

-- person_profession; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.person_profession (
    nconst text NOT NULL,
    profession text NOT NULL
);


ALTER TABLE movie.person_profession OWNER TO postgres;

-- profession; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.profession (
    profession text NOT NULL
);


ALTER TABLE movie.profession OWNER TO postgres;

-- title; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.title (
    tconst text NOT NULL,
    title_type text,
    primary_title text,
    original_title text,
    is_adult boolean,
    start_year integer,
    end_year integer,
    runtime_minutes integer,
    base_average_rating numeric(3,1),
    base_num_votes integer
);


ALTER TABLE movie.title OWNER TO postgres;

-- title_aka; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.title_aka (
    tconst text NOT NULL,
    ordering integer NOT NULL,
    title text,
    region text,
    language text,
    is_original_title boolean
);


ALTER TABLE movie.title_aka OWNER TO postgres;

-- title_aka_attribute; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.title_aka_attribute (
    tconst text NOT NULL,
    ordering integer NOT NULL,
    attribute text NOT NULL COLLATE pg_catalog."C"
);


ALTER TABLE movie.title_aka_attribute OWNER TO postgres;

-- title_aka_type; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.title_aka_type (
    tconst text NOT NULL,
    ordering integer NOT NULL,
    type text NOT NULL COLLATE pg_catalog."C"
);


ALTER TABLE movie.title_aka_type OWNER TO postgres;

-- title_crew_member; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.title_crew_member (
    tconst text NOT NULL,
    nconst text NOT NULL,
    role text NOT NULL,
    CONSTRAINT title_crew_member_role_check CHECK ((role = ANY (ARRAY['director'::text, 'writer'::text])))
);


ALTER TABLE movie.title_crew_member OWNER TO postgres;

-- title_episode; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.title_episode (
    tconst text NOT NULL,
    parent_tconst text NOT NULL,
    season_number integer,
    episode_number integer
);


ALTER TABLE movie.title_episode OWNER TO postgres;

-- title_genre; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.title_genre (
    tconst text NOT NULL,
    genre text NOT NULL
);


ALTER TABLE movie.title_genre OWNER TO postgres;

-- wi; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.wi (
    tconst text NOT NULL,
    word text NOT NULL COLLATE pg_catalog."C"
);


ALTER TABLE movie.wi OWNER TO postgres;

-- word; Type: TABLE; Schema: movie; Owner: postgres

CREATE TABLE movie.word (
    word text NOT NULL COLLATE pg_catalog."C"
);


ALTER TABLE movie.word OWNER TO postgres;

-- app_user app_user_email_key; Type: CONSTRAINT; Schema: framework; Owner: postgres

ALTER TABLE ONLY framework.app_user
    ADD CONSTRAINT app_user_email_key UNIQUE (email);


-- app_user app_user_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres

ALTER TABLE ONLY framework.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (user_id);


-- app_user app_user_username_key; Type: CONSTRAINT; Schema: framework; Owner: postgres

ALTER TABLE ONLY framework.app_user
    ADD CONSTRAINT app_user_username_key UNIQUE (username);


-- title_rating_history title_rating_history_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres

ALTER TABLE ONLY framework.title_rating_history
    ADD CONSTRAINT title_rating_history_pkey PRIMARY KEY (event_id);


-- user_bookmark_person user_bookmark_person_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres

ALTER TABLE ONLY framework.user_bookmark_person
    ADD CONSTRAINT user_bookmark_person_pkey PRIMARY KEY (user_id, nconst);


-- user_bookmark_title user_bookmark_title_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres

ALTER TABLE ONLY framework.user_bookmark_title
    ADD CONSTRAINT user_bookmark_title_pkey PRIMARY KEY (user_id, tconst);


-- user_search_history user_search_history_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres


ALTER TABLE ONLY framework.user_search_history
    ADD CONSTRAINT user_search_history_pkey PRIMARY KEY (search_id);


-- user_title_rating user_title_rating_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres

ALTER TABLE ONLY framework.user_title_rating
    ADD CONSTRAINT user_title_rating_pkey PRIMARY KEY (rating_id);


-- user_title_rating user_title_rating_user_id_tconst_key; Type: CONSTRAINT; Schema: framework; Owner: postgres

ALTER TABLE ONLY framework.user_title_rating
    ADD CONSTRAINT user_title_rating_user_id_tconst_key UNIQUE (user_id, tconst);


-- credit_character credit_character_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.credit_character
    ADD CONSTRAINT credit_character_pkey PRIMARY KEY (tconst, ordering, character_name);


-- credit credit_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.credit
    ADD CONSTRAINT credit_pkey PRIMARY KEY (tconst, ordering);


-- genre genre_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.genre
    ADD CONSTRAINT genre_pkey PRIMARY KEY (genre);


-- omdb_extra omdb_extra_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.omdb_extra
    ADD CONSTRAINT omdb_extra_pkey PRIMARY KEY (tconst);


-- person_known_for person_known_for_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.person_known_for
    ADD CONSTRAINT person_known_for_pkey PRIMARY KEY (nconst, tconst);


-- person person_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.person
    ADD CONSTRAINT person_pkey PRIMARY KEY (nconst);


-- person_profession person_profession_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres


ALTER TABLE ONLY movie.person_profession
    ADD CONSTRAINT person_profession_pkey PRIMARY KEY (nconst, profession);


-- profession profession_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.profession
    ADD CONSTRAINT profession_pkey PRIMARY KEY (profession);


-- title_aka_attribute title_aka_attribute_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.title_aka_attribute
    ADD CONSTRAINT title_aka_attribute_pkey PRIMARY KEY (tconst, ordering, attribute);


-- title_aka title_aka_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.title_aka
    ADD CONSTRAINT title_aka_pkey PRIMARY KEY (tconst, ordering);


-- title_aka_type title_aka_type_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.title_aka_type
    ADD CONSTRAINT title_aka_type_pkey PRIMARY KEY (tconst, ordering, type);


-- title_crew_member title_crew_member_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres
--

ALTER TABLE ONLY movie.title_crew_member
    ADD CONSTRAINT title_crew_member_pkey PRIMARY KEY (tconst, nconst, role);


-- title_episode title_episode_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres


ALTER TABLE ONLY movie.title_episode
    ADD CONSTRAINT title_episode_pkey PRIMARY KEY (tconst);


-- Name: title_genre title_genre_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.title_genre
    ADD CONSTRAINT title_genre_pkey PRIMARY KEY (tconst, genre);


-- title title_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.title
    ADD CONSTRAINT title_pkey PRIMARY KEY (tconst);


-- wi wi_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres
--

ALTER TABLE ONLY movie.wi
    ADD CONSTRAINT wi_pkey PRIMARY KEY (tconst, word);


-- word word_pkey; Type: CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.word
    ADD CONSTRAINT word_pkey PRIMARY KEY (word);


-- title_rating_history title_rating_history_tconst_fkey; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY framework.title_rating_history
    ADD CONSTRAINT title_rating_history_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);


-- title_rating_history title_rating_history_user_id_fkey; Type: FK CONSTRAINT; Schema: framework; Owner: postgres

ALTER TABLE ONLY framework.title_rating_history
    ADD CONSTRAINT title_rating_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES framework.app_user(user_id) ON DELETE CASCADE;


-- user_bookmark_person user_bookmark_person_nconst_fkey; Type: FK CONSTRAINT; Schema: framework; Owner: postgres

ALTER TABLE ONLY framework.user_bookmark_person
    ADD CONSTRAINT user_bookmark_person_nconst_fkey FOREIGN KEY (nconst) REFERENCES movie.person(nconst);


-- user_bookmark_person user_bookmark_person_user_id_fkey; Type: FK CONSTRAINT; Schema: framework; Owner: postgres


ALTER TABLE ONLY framework.user_bookmark_person
    ADD CONSTRAINT user_bookmark_person_user_id_fkey FOREIGN KEY (user_id) REFERENCES framework.app_user(user_id) ON DELETE CASCADE;


-- user_bookmark_title user_bookmark_title_tconst_fkey; Type: FK CONSTRAINT; Schema: framework; Owner: postgres

ALTER TABLE ONLY framework.user_bookmark_title
    ADD CONSTRAINT user_bookmark_title_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);


-- user_bookmark_title user_bookmark_title_user_id_fkey; Type: FK CONSTRAINT; Schema: framework; Owner: postgres


ALTER TABLE ONLY framework.user_bookmark_title
    ADD CONSTRAINT user_bookmark_title_user_id_fkey FOREIGN KEY (user_id) REFERENCES framework.app_user(user_id) ON DELETE CASCADE;


-- user_search_history user_search_history_user_id_fkey; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY framework.user_search_history
    ADD CONSTRAINT user_search_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES framework.app_user(user_id) ON DELETE CASCADE;


-- user_title_rating user_title_rating_tconst_fkey; Type: FK CONSTRAINT; Schema: framework; Owner: postgres

ALTER TABLE ONLY framework.user_title_rating
    ADD CONSTRAINT user_title_rating_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);


-- user_title_rating user_title_rating_user_id_fkey; Type: FK CONSTRAINT; Schema: framework; Owner: postgres

ALTER TABLE ONLY framework.user_title_rating
    ADD CONSTRAINT user_title_rating_user_id_fkey FOREIGN KEY (user_id) REFERENCES framework.app_user(user_id) ON DELETE CASCADE;


-- credit_character credit_character_tconst_ordering_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres


ALTER TABLE ONLY movie.credit_character
    ADD CONSTRAINT credit_character_tconst_ordering_fkey FOREIGN KEY (tconst, ordering) REFERENCES movie.credit(tconst, ordering);


-- credit credit_nconst_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres


ALTER TABLE ONLY movie.credit
    ADD CONSTRAINT credit_nconst_fkey FOREIGN KEY (nconst) REFERENCES movie.person(nconst);


-- credit credit_tconst_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres


ALTER TABLE ONLY movie.credit
    ADD CONSTRAINT credit_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);


-- omdb_extra omdb_extra_tconst_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.omdb_extra
    ADD CONSTRAINT omdb_extra_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);


-- person_known_for person_known_for_nconst_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.person_known_for
    ADD CONSTRAINT person_known_for_nconst_fkey FOREIGN KEY (nconst) REFERENCES movie.person(nconst);


-- person_known_for person_known_for_tconst_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres


ALTER TABLE ONLY movie.person_known_for
    ADD CONSTRAINT person_known_for_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);


-- person_profession person_profession_nconst_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.person_profession
    ADD CONSTRAINT person_profession_nconst_fkey FOREIGN KEY (nconst) REFERENCES movie.person(nconst);


-- person_profession person_profession_profession_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.person_profession
    ADD CONSTRAINT person_profession_profession_fkey FOREIGN KEY (profession) REFERENCES movie.profession(profession);


-- title_aka_attribute title_aka_attribute_tconst_ordering_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.title_aka_attribute
    ADD CONSTRAINT title_aka_attribute_tconst_ordering_fkey FOREIGN KEY (tconst, ordering) REFERENCES movie.title_aka(tconst, ordering);


-- title_aka title_aka_tconst_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres


ALTER TABLE ONLY movie.title_aka
    ADD CONSTRAINT title_aka_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);


-- title_aka_type title_aka_type_tconst_ordering_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.title_aka_type
    ADD CONSTRAINT title_aka_type_tconst_ordering_fkey FOREIGN KEY (tconst, ordering) REFERENCES movie.title_aka(tconst, ordering);


-- title_crew_member title_crew_member_nconst_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.title_crew_member
    ADD CONSTRAINT title_crew_member_nconst_fkey FOREIGN KEY (nconst) REFERENCES movie.person(nconst);


-- title_crew_member title_crew_member_tconst_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.title_crew_member
    ADD CONSTRAINT title_crew_member_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);


-- title_episode title_episode_parent_tconst_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.title_episode
    ADD CONSTRAINT title_episode_parent_tconst_fkey FOREIGN KEY (parent_tconst) REFERENCES movie.title(tconst);


-- title_episode title_episode_tconst_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.title_episode
    ADD CONSTRAINT title_episode_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);

-- title_genre title_genre_genre_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.title_genre
    ADD CONSTRAINT title_genre_genre_fkey FOREIGN KEY (genre) REFERENCES movie.genre(genre);


-- title_genre title_genre_tconst_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.title_genre
    ADD CONSTRAINT title_genre_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);


-- wi wi_tconst_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.wi
    ADD CONSTRAINT wi_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);


-- wi wi_word_fkey; Type: FK CONSTRAINT; Schema: movie; Owner: postgres

ALTER TABLE ONLY movie.wi
    ADD CONSTRAINT wi_word_fkey FOREIGN KEY (word) REFERENCES movie.word(word);
