-- B2: Build the movie model from the nine supplied public source tables.
-- Run on a NEW database containing those source tables, before C2 and functions.
-- Existing movie schemas are left unchanged; repeating this script is a no-op.
-- For a complete rebuild, use a fresh database and reload the source backups.
-- Required OMDb columns: plot and poster. WI field/lexeme are optional.
-- Dangling references are excluded, as allowed by the source-data instructions.
-- After a successful import, the nine original source tables are removed.
-- DROP uses RESTRICT: unexpected dependencies abort the entire transaction.
-- This file does not rebuild or clean up an already deployed movie schema.

BEGIN;
SET LOCAL standard_conforming_strings = on;
SET LOCAL statement_timeout = 0;
DO $build_movie$
DECLARE
    v_table TEXT;
BEGIN
    IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'movie') THEN
        RAISE NOTICE 'movie schema already exists; build skipped. Existing source tables are not removed.';
        RETURN;
    END IF;
    FOREACH v_table IN ARRAY ARRAY['title_basics','title_ratings','name_basics','title_principals','title_crew','title_episode','title_akas','omdb_data','wi'] LOOP
        IF to_regclass(format('public.%I', v_table)) IS NULL THEN
            RAISE EXCEPTION 'Required source table public.% is missing', v_table;
        END IF;
    END LOOP;
    EXECUTE $movie_sql$
CREATE SCHEMA movie;

CREATE TABLE movie.credit (
    tconst text NOT NULL,
    ordering integer NOT NULL,
    nconst text NOT NULL,
    category text,
    job text,
    characters text
);

CREATE TABLE movie.credit_character (
    tconst text NOT NULL,
    ordering integer NOT NULL,
    character_name text NOT NULL COLLATE pg_catalog."C",
    CONSTRAINT credit_character_character_name_check CHECK ((btrim(character_name) <> ''::text))
);

CREATE TABLE movie.genre (
    genre text NOT NULL
);

CREATE TABLE movie.omdb_extra (
    tconst text NOT NULL,
    plot text,
    poster text
);

CREATE TABLE movie.person (
    nconst text NOT NULL,
    primary_name text,
    birth_year integer,
    death_year integer
);

CREATE TABLE movie.person_known_for (
    nconst text NOT NULL,
    tconst text NOT NULL
);

CREATE TABLE movie.person_profession (
    nconst text NOT NULL,
    profession text NOT NULL
);

CREATE TABLE movie.profession (
    profession text NOT NULL
);

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

CREATE TABLE movie.title_aka (
    tconst text NOT NULL,
    ordering integer NOT NULL,
    title text,
    region text,
    language text,
    is_original_title boolean
);

CREATE TABLE movie.title_aka_attribute (
    tconst text NOT NULL,
    ordering integer NOT NULL,
    attribute text NOT NULL COLLATE pg_catalog."C"
);

CREATE TABLE movie.title_aka_type (
    tconst text NOT NULL,
    ordering integer NOT NULL,
    type text NOT NULL COLLATE pg_catalog."C"
);

CREATE TABLE movie.title_crew_member (
    tconst text NOT NULL,
    nconst text NOT NULL,
    role text NOT NULL,
    CONSTRAINT title_crew_member_role_check CHECK ((role = ANY (ARRAY['director'::text, 'writer'::text])))
);

CREATE TABLE movie.title_episode (
    tconst text NOT NULL,
    parent_tconst text NOT NULL,
    season_number integer,
    episode_number integer
);

CREATE TABLE movie.title_genre (
    tconst text NOT NULL,
    genre text NOT NULL
);

CREATE TABLE movie.wi (
    tconst text NOT NULL,
    word text NOT NULL COLLATE pg_catalog."C"
);

CREATE TABLE movie.word (
    word text NOT NULL COLLATE pg_catalog."C"
);

ALTER TABLE ONLY movie.credit_character
    ADD CONSTRAINT credit_character_pkey PRIMARY KEY (tconst, ordering, character_name);

ALTER TABLE ONLY movie.credit
    ADD CONSTRAINT credit_pkey PRIMARY KEY (tconst, ordering);

ALTER TABLE ONLY movie.genre
    ADD CONSTRAINT genre_pkey PRIMARY KEY (genre);

ALTER TABLE ONLY movie.omdb_extra
    ADD CONSTRAINT omdb_extra_pkey PRIMARY KEY (tconst);

ALTER TABLE ONLY movie.person_known_for
    ADD CONSTRAINT person_known_for_pkey PRIMARY KEY (nconst, tconst);

ALTER TABLE ONLY movie.person
    ADD CONSTRAINT person_pkey PRIMARY KEY (nconst);

ALTER TABLE ONLY movie.person_profession
    ADD CONSTRAINT person_profession_pkey PRIMARY KEY (nconst, profession);

ALTER TABLE ONLY movie.profession
    ADD CONSTRAINT profession_pkey PRIMARY KEY (profession);

ALTER TABLE ONLY movie.title_aka_attribute
    ADD CONSTRAINT title_aka_attribute_pkey PRIMARY KEY (tconst, ordering, attribute);

ALTER TABLE ONLY movie.title_aka
    ADD CONSTRAINT title_aka_pkey PRIMARY KEY (tconst, ordering);

ALTER TABLE ONLY movie.title_aka_type
    ADD CONSTRAINT title_aka_type_pkey PRIMARY KEY (tconst, ordering, type);

ALTER TABLE ONLY movie.title_crew_member
    ADD CONSTRAINT title_crew_member_pkey PRIMARY KEY (tconst, nconst, role);

ALTER TABLE ONLY movie.title_episode
    ADD CONSTRAINT title_episode_pkey PRIMARY KEY (tconst);

ALTER TABLE ONLY movie.title_genre
    ADD CONSTRAINT title_genre_pkey PRIMARY KEY (tconst, genre);

ALTER TABLE ONLY movie.title
    ADD CONSTRAINT title_pkey PRIMARY KEY (tconst);

ALTER TABLE ONLY movie.wi
    ADD CONSTRAINT wi_pkey PRIMARY KEY (tconst, word);

ALTER TABLE ONLY movie.word
    ADD CONSTRAINT word_pkey PRIMARY KEY (word);

ALTER TABLE ONLY movie.credit_character
    ADD CONSTRAINT credit_character_tconst_ordering_fkey FOREIGN KEY (tconst, ordering) REFERENCES movie.credit(tconst, ordering);

ALTER TABLE ONLY movie.credit
    ADD CONSTRAINT credit_nconst_fkey FOREIGN KEY (nconst) REFERENCES movie.person(nconst);

ALTER TABLE ONLY movie.credit
    ADD CONSTRAINT credit_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);

ALTER TABLE ONLY movie.omdb_extra
    ADD CONSTRAINT omdb_extra_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);

ALTER TABLE ONLY movie.person_known_for
    ADD CONSTRAINT person_known_for_nconst_fkey FOREIGN KEY (nconst) REFERENCES movie.person(nconst);

ALTER TABLE ONLY movie.person_known_for
    ADD CONSTRAINT person_known_for_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);

ALTER TABLE ONLY movie.person_profession
    ADD CONSTRAINT person_profession_nconst_fkey FOREIGN KEY (nconst) REFERENCES movie.person(nconst);

ALTER TABLE ONLY movie.person_profession
    ADD CONSTRAINT person_profession_profession_fkey FOREIGN KEY (profession) REFERENCES movie.profession(profession);

ALTER TABLE ONLY movie.title_aka_attribute
    ADD CONSTRAINT title_aka_attribute_tconst_ordering_fkey FOREIGN KEY (tconst, ordering) REFERENCES movie.title_aka(tconst, ordering);

ALTER TABLE ONLY movie.title_aka
    ADD CONSTRAINT title_aka_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);

ALTER TABLE ONLY movie.title_aka_type
    ADD CONSTRAINT title_aka_type_tconst_ordering_fkey FOREIGN KEY (tconst, ordering) REFERENCES movie.title_aka(tconst, ordering);

ALTER TABLE ONLY movie.title_crew_member
    ADD CONSTRAINT title_crew_member_nconst_fkey FOREIGN KEY (nconst) REFERENCES movie.person(nconst);

ALTER TABLE ONLY movie.title_crew_member
    ADD CONSTRAINT title_crew_member_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);

ALTER TABLE ONLY movie.title_episode
    ADD CONSTRAINT title_episode_parent_tconst_fkey FOREIGN KEY (parent_tconst) REFERENCES movie.title(tconst);

ALTER TABLE ONLY movie.title_episode
    ADD CONSTRAINT title_episode_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);

ALTER TABLE ONLY movie.title_genre
    ADD CONSTRAINT title_genre_genre_fkey FOREIGN KEY (genre) REFERENCES movie.genre(genre);

ALTER TABLE ONLY movie.title_genre
    ADD CONSTRAINT title_genre_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);

ALTER TABLE ONLY movie.wi
    ADD CONSTRAINT wi_tconst_fkey FOREIGN KEY (tconst) REFERENCES movie.title(tconst);

ALTER TABLE ONLY movie.wi
    ADD CONSTRAINT wi_word_fkey FOREIGN KEY (word) REFERENCES movie.word(word);

SET LOCAL standard_conforming_strings = on;

-- Stop accidental imports into an existing populated model.
DO $$
DECLARE
    v_table TEXT;
    v_has_rows BOOLEAN;
BEGIN
    FOREACH v_table IN ARRAY ARRAY[
        'title', 'person', 'genre', 'profession',
        'title_genre', 'person_profession', 'person_known_for',
        'credit', 'credit_character', 'title_crew_member',
        'title_episode', 'title_aka', 'title_aka_type',
        'title_aka_attribute', 'omdb_extra', 'word', 'wi'
    ]
    LOOP
        EXECUTE format(
            'SELECT EXISTS (SELECT 1 FROM movie.%I)',
            v_table
        ) INTO v_has_rows;

        IF v_has_rows THEN
            RAISE EXCEPTION
                'Migration stopped: movie.% already contains data',
                v_table;
        END IF;
    END LOOP;
END;
$$;

-- 1. Titles and the original IMDb rating baseline.
INSERT INTO movie.title (
    tconst, title_type, primary_title, original_title,
    is_adult, start_year, end_year, runtime_minutes,
    base_average_rating, base_num_votes
)
SELECT
    btrim(b.tconst),
    NULLIF(b.titletype, '\N'),
    NULLIF(b.primarytitle, '\N'),
    NULLIF(b.originaltitle, '\N'),
    b.isadult,
    NULLIF(NULLIF(btrim(b.startyear), '\N'), '')::INTEGER,
    NULLIF(NULLIF(btrim(b.endyear), '\N'), '')::INTEGER,
    b.runtimeminutes,
    r.averagerating,
    r.numvotes
FROM public.title_basics AS b
LEFT JOIN public.title_ratings AS r
    ON btrim(r.tconst) = btrim(b.tconst);

-- 2. Persons.
INSERT INTO movie.person (
    nconst, primary_name, birth_year, death_year
)
SELECT
    btrim(n.nconst),
    NULLIF(n.primaryname, '\N'),
    NULLIF(NULLIF(btrim(n.birthyear), '\N'), '')::INTEGER,
    NULLIF(NULLIF(btrim(n.deathyear), '\N'), '')::INTEGER
FROM public.name_basics AS n;

-- 3. Genres.
-- Accept comma-separated lists and the source control separator.
CREATE TEMP TABLE migration_genres ON COMMIT DROP AS
SELECT DISTINCT
    t.tconst,
    btrim(s.value) AS genre
FROM public.title_basics AS b
JOIN movie.title AS t
    ON t.tconst = btrim(b.tconst)
CROSS JOIN LATERAL unnest(
    string_to_array(replace(b.genres, chr(2), ','), ',')
) AS s(value)
WHERE btrim(s.value) NOT IN ('', '\N');

INSERT INTO movie.genre (genre)
SELECT DISTINCT genre
FROM migration_genres;

INSERT INTO movie.title_genre (tconst, genre)
SELECT tconst, genre
FROM migration_genres;

-- 4. Professions.
CREATE TEMP TABLE migration_professions ON COMMIT DROP AS
SELECT DISTINCT
    p.nconst,
    btrim(s.value) AS profession
FROM public.name_basics AS n
JOIN movie.person AS p
    ON p.nconst = btrim(n.nconst)
CROSS JOIN LATERAL unnest(
    string_to_array(
        replace(n.primaryprofession, chr(2), ','),
        ','
    )
) AS s(value)
WHERE btrim(s.value) NOT IN ('', '\N');

INSERT INTO movie.profession (profession)
SELECT DISTINCT profession
FROM migration_professions;

INSERT INTO movie.person_profession (nconst, profession)
SELECT nconst, profession
FROM migration_professions;

-- 5. Known-for titles: import only existing title references.
INSERT INTO movie.person_known_for (nconst, tconst)
SELECT DISTINCT
    p.nconst,
    t.tconst
FROM public.name_basics AS n
JOIN movie.person AS p
    ON p.nconst = btrim(n.nconst)
CROSS JOIN LATERAL unnest(
    string_to_array(
        replace(n.knownfortitles, chr(2), ','),
        ','
    )
) AS s(value)
JOIN movie.title AS t
    ON t.tconst = btrim(s.value)
WHERE btrim(s.value) NOT IN ('', '\N');

-- 6. Principal credits.
-- Preserve the original characters text in movie.credit.
INSERT INTO movie.credit (
    tconst, ordering, nconst, category, job, characters
)
SELECT
    t.tconst,
    c.ordering,
    p.nconst,
    NULLIF(c.category, '\N'),
    NULLIF(c.job, '\N'),
    NULLIF(c.characters, '\N')
FROM public.title_principals AS c
JOIN movie.title AS t
    ON t.tconst = btrim(c.tconst)
JOIN movie.person AS p
    ON p.nconst = btrim(c.nconst);

-- 7. Character labels.
-- Reproduce the conservative wrapper removal used in the model.
-- Remove only the surrounding [' and '].
-- Preserve apostrophes inside names and the original credit text.
--
-- This is not a general parser for Python-style character lists.
-- Multiple characters inside one wrapper remain one label here.
INSERT INTO movie.credit_character (
    tconst, ordering, character_name
)
SELECT
    c.tconst,
    c.ordering,
    x.character_name COLLATE "C"
FROM movie.credit AS c
CROSS JOIN LATERAL (
    SELECT btrim(
        CASE
            WHEN left(btrim(c.characters), 2)
                     = '[' || chr(39)
             AND right(btrim(c.characters), 2)
                     = chr(39) || ']'
            THEN substring(
                btrim(c.characters)
                FROM 3
                FOR length(btrim(c.characters)) - 4
            )
            ELSE c.characters
        END
    ) AS character_name
) AS x
WHERE c.characters IS NOT NULL
  AND btrim(c.characters) NOT IN ('', '\N', '[]')
  AND x.character_name NOT IN ('', '\N');

-- 8. Directors and writers.
INSERT INTO movie.title_crew_member (tconst, nconst, role)
SELECT DISTINCT
    t.tconst,
    p.nconst,
    v.role
FROM public.title_crew AS c
JOIN movie.title AS t
    ON t.tconst = btrim(c.tconst)
CROSS JOIN LATERAL (
    VALUES
        ('director'::TEXT, c.directors),
        ('writer'::TEXT, c.writers)
) AS v(role, names)
CROSS JOIN LATERAL unnest(
    string_to_array(replace(v.names, chr(2), ','), ',')
) AS s(value)
JOIN movie.person AS p
    ON p.nconst = btrim(s.value)
WHERE btrim(s.value) NOT IN ('', '\N');

-- 9. Episodes: both episode and parent must exist.
INSERT INTO movie.title_episode (
    tconst, parent_tconst, season_number, episode_number
)
SELECT
    child.tconst,
    parent.tconst,
    e.seasonnumber,
    e.episodenumber
FROM public.title_episode AS e
JOIN movie.title AS child
    ON child.tconst = btrim(e.tconst)
JOIN movie.title AS parent
    ON parent.tconst = btrim(e.parenttconst);

-- 10. Alternative titles.
INSERT INTO movie.title_aka (
    tconst, ordering, title, region,
    language, is_original_title
)
SELECT
    t.tconst,
    a.ordering,
    NULLIF(a.title, '\N'),
    NULLIF(NULLIF(btrim(a.region), '\N'), ''),
    NULLIF(NULLIF(btrim(a.language), '\N'), ''),
    a.isoriginaltitle
FROM public.title_akas AS a
JOIN movie.title AS t
    ON t.tconst = btrim(a.titleid);

-- AKA types and attributes use the chr(2) separator.
INSERT INTO movie.title_aka_type (tconst, ordering, type)
SELECT DISTINCT
    k.tconst,
    k.ordering,
    btrim(s.value) COLLATE "C"
FROM public.title_akas AS a
JOIN movie.title_aka AS k
    ON k.tconst = btrim(a.titleid)
   AND k.ordering = a.ordering
CROSS JOIN LATERAL unnest(
    string_to_array(a.types, chr(2))
) AS s(value)
WHERE btrim(s.value) NOT IN ('', '\N');

INSERT INTO movie.title_aka_attribute (
    tconst, ordering, attribute
)
SELECT DISTINCT
    k.tconst,
    k.ordering,
    btrim(s.value) COLLATE "C"
FROM public.title_akas AS a
JOIN movie.title_aka AS k
    ON k.tconst = btrim(a.titleid)
   AND k.ordering = a.ordering
CROSS JOIN LATERAL unnest(
    string_to_array(a.attributes, chr(2))
) AS s(value)
WHERE btrim(s.value) NOT IN ('', '\N');

-- 11. OMDb plot and poster.
INSERT INTO movie.omdb_extra (tconst, plot, poster)
SELECT
    t.tconst,
    NULLIF(NULLIF(o.plot, 'N/A'), '\N'),
    NULLIF(NULLIF(o.poster, 'N/A'), '\N')
FROM public.omdb_data AS o
JOIN movie.title AS t
    ON t.tconst = btrim(o.tconst);

-- 12. Word dictionary and distinct title-word links.
-- field and lexeme are optional according to the source-data instructions.
-- The model stores one occurrence of each word per title.
CREATE TEMP TABLE migration_wi ON COMMIT DROP AS
SELECT DISTINCT
    t.tconst,
    btrim(w.word) COLLATE "C" AS word
FROM public.wi AS w
JOIN movie.title AS t
    ON t.tconst = btrim(w.tconst)
WHERE w.word IS NOT NULL
  AND btrim(w.word) NOT IN ('', '\N');

INSERT INTO movie.word (word)
SELECT DISTINCT word
FROM migration_wi;

INSERT INTO movie.wi (tconst, word)
SELECT tconst, word
FROM migration_wi;


DROP TABLE public.title_basics,
    public.title_ratings,
    public.name_basics,
    public.title_principals,
    public.title_crew,
    public.title_episode,
    public.title_akas,
    public.omdb_data,
    public.wi RESTRICT;
$movie_sql$;
END;
$build_movie$;
COMMIT;
