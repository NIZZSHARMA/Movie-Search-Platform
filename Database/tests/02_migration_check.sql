-- Run locally against a database containing the populated movie schema
-- and the nine public source tables.
-- Requires movie_migration_check to be absent before starting.
-- This setup does not change the original movie or public data.

BEGIN;

SET LOCAL search_path = pg_catalog;

CREATE SCHEMA movie_migration_check;

-- Copy movie tables, primary keys, checks and indexes.
DO $$
DECLARE
    v_table TEXT;
BEGIN
    FOR v_table IN
        SELECT c.relname
        FROM pg_class AS c
        JOIN pg_namespace AS n
          ON n.oid = c.relnamespace
        WHERE n.nspname = 'movie'
          AND c.relkind = 'r'
        ORDER BY c.relname
    LOOP
        EXECUTE format(
            'CREATE TABLE movie_migration_check.%I
             (LIKE movie.%I INCLUDING ALL)',
            v_table, v_table
        );
    END LOOP;
END;
$$;

-- Copy foreign keys, pointing them to the test tables.
DO $$
DECLARE
    v_fk RECORD;
BEGIN
    FOR v_fk IN
        SELECT
            t.relname AS table_name,
            fk.conname AS constraint_name,
            pg_get_constraintdef(fk.oid) AS definition
        FROM pg_constraint AS fk
        JOIN pg_class AS t
          ON t.oid = fk.conrelid
        JOIN pg_namespace AS n
          ON n.oid = t.relnamespace
        WHERE n.nspname = 'movie'
          AND fk.contype = 'f'
        ORDER BY t.relname, fk.conname
    LOOP
        EXECUTE format(
            'ALTER TABLE movie_migration_check.%I
             ADD CONSTRAINT %I %s',
            v_fk.table_name,
            v_fk.constraint_name,
            replace(
                v_fk.definition,
                'movie.',
                'movie_migration_check.'
            )
        );
    END LOOP;
END;
$$;

COMMIT;

-- The test migration and comparison checks follow below.

-- Import the provided public source tables into the movie schema.
--
-- Prerequisites:
--   1. The nine public source tables must already contain data.
--   2. Run 01_schema.sql to create empty target tables.
--
-- Run this migration BEFORE 02_user_functions.sql so that
-- the initial person-rating refresh includes the imported data.
--
-- This script refuses to import into populated movie tables.
-- It does not delete or truncate source or target data.

BEGIN;

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
            'SELECT EXISTS (SELECT 1 FROM movie_migration_check.%I)',
            v_table
        ) INTO v_has_rows;

        IF v_has_rows THEN
            RAISE EXCEPTION
                'Migration stopped: movie_migration_check.% already contains data',
                v_table;
        END IF;
    END LOOP;
END;
$$;

-- 1. Titles and the original IMDb rating baseline.
INSERT INTO movie_migration_check.title (
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
INSERT INTO movie_migration_check.person (
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
JOIN movie_migration_check.title AS t
    ON t.tconst = btrim(b.tconst)
CROSS JOIN LATERAL unnest(
    string_to_array(replace(b.genres, chr(2), ','), ',')
) AS s(value)
WHERE btrim(s.value) NOT IN ('', '\N');

INSERT INTO movie_migration_check.genre (genre)
SELECT DISTINCT genre
FROM migration_genres;

INSERT INTO movie_migration_check.title_genre (tconst, genre)
SELECT tconst, genre
FROM migration_genres;

-- 4. Professions.
CREATE TEMP TABLE migration_professions ON COMMIT DROP AS
SELECT DISTINCT
    p.nconst,
    btrim(s.value) AS profession
FROM public.name_basics AS n
JOIN movie_migration_check.person AS p
    ON p.nconst = btrim(n.nconst)
CROSS JOIN LATERAL unnest(
    string_to_array(
        replace(n.primaryprofession, chr(2), ','),
        ','
    )
) AS s(value)
WHERE btrim(s.value) NOT IN ('', '\N');

INSERT INTO movie_migration_check.profession (profession)
SELECT DISTINCT profession
FROM migration_professions;

INSERT INTO movie_migration_check.person_profession (nconst, profession)
SELECT nconst, profession
FROM migration_professions;

-- 5. Known-for titles: import only existing title references.
INSERT INTO movie_migration_check.person_known_for (nconst, tconst)
SELECT DISTINCT
    p.nconst,
    t.tconst
FROM public.name_basics AS n
JOIN movie_migration_check.person AS p
    ON p.nconst = btrim(n.nconst)
CROSS JOIN LATERAL unnest(
    string_to_array(
        replace(n.knownfortitles, chr(2), ','),
        ','
    )
) AS s(value)
JOIN movie_migration_check.title AS t
    ON t.tconst = btrim(s.value)
WHERE btrim(s.value) NOT IN ('', '\N');

-- 6. Principal credits.
-- Preserve the original characters text in movie_migration_check.credit.
INSERT INTO movie_migration_check.credit (
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
JOIN movie_migration_check.title AS t
    ON t.tconst = btrim(c.tconst)
JOIN movie_migration_check.person AS p
    ON p.nconst = btrim(c.nconst);

-- 7. Character labels.
-- Reproduce the conservative wrapper removal used in the model.
-- Remove only the surrounding [' and '].
-- Preserve apostrophes inside names and the original credit text.
--
-- This is not a general parser for Python-style character lists.
-- Multiple characters inside one wrapper remain one label here.
INSERT INTO movie_migration_check.credit_character (
    tconst, ordering, character_name
)
SELECT
    c.tconst,
    c.ordering,
    x.character_name COLLATE "C"
FROM movie_migration_check.credit AS c
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
INSERT INTO movie_migration_check.title_crew_member (tconst, nconst, role)
SELECT DISTINCT
    t.tconst,
    p.nconst,
    v.role
FROM public.title_crew AS c
JOIN movie_migration_check.title AS t
    ON t.tconst = btrim(c.tconst)
CROSS JOIN LATERAL (
    VALUES
        ('director'::TEXT, c.directors),
        ('writer'::TEXT, c.writers)
) AS v(role, names)
CROSS JOIN LATERAL unnest(
    string_to_array(replace(v.names, chr(2), ','), ',')
) AS s(value)
JOIN movie_migration_check.person AS p
    ON p.nconst = btrim(s.value)
WHERE btrim(s.value) NOT IN ('', '\N');

-- 9. Episodes: both episode and parent must exist.
INSERT INTO movie_migration_check.title_episode (
    tconst, parent_tconst, season_number, episode_number
)
SELECT
    child.tconst,
    parent.tconst,
    e.seasonnumber,
    e.episodenumber
FROM public.title_episode AS e
JOIN movie_migration_check.title AS child
    ON child.tconst = btrim(e.tconst)
JOIN movie_migration_check.title AS parent
    ON parent.tconst = btrim(e.parenttconst);

-- 10. Alternative titles.
INSERT INTO movie_migration_check.title_aka (
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
JOIN movie_migration_check.title AS t
    ON t.tconst = btrim(a.titleid);

-- AKA types and attributes use the chr(2) separator.
INSERT INTO movie_migration_check.title_aka_type (tconst, ordering, type)
SELECT DISTINCT
    k.tconst,
    k.ordering,
    btrim(s.value) COLLATE "C"
FROM public.title_akas AS a
JOIN movie_migration_check.title_aka AS k
    ON k.tconst = btrim(a.titleid)
   AND k.ordering = a.ordering
CROSS JOIN LATERAL unnest(
    string_to_array(a.types, chr(2))
) AS s(value)
WHERE btrim(s.value) NOT IN ('', '\N');

INSERT INTO movie_migration_check.title_aka_attribute (
    tconst, ordering, attribute
)
SELECT DISTINCT
    k.tconst,
    k.ordering,
    btrim(s.value) COLLATE "C"
FROM public.title_akas AS a
JOIN movie_migration_check.title_aka AS k
    ON k.tconst = btrim(a.titleid)
   AND k.ordering = a.ordering
CROSS JOIN LATERAL unnest(
    string_to_array(a.attributes, chr(2))
) AS s(value)
WHERE btrim(s.value) NOT IN ('', '\N');

-- 11. OMDb plot and poster.
INSERT INTO movie_migration_check.omdb_extra (tconst, plot, poster)
SELECT
    t.tconst,
    NULLIF(NULLIF(o.plot, 'N/A'), '\N'),
    NULLIF(NULLIF(o.poster, 'N/A'), '\N')
FROM public.omdb_data AS o
JOIN movie_migration_check.title AS t
    ON t.tconst = btrim(o.tconst);

-- 12. Word dictionary and distinct title-word links.
-- field and lexeme remain available in public.wi.
-- The model stores one occurrence of each word per title.
CREATE TEMP TABLE migration_wi ON COMMIT DROP AS
SELECT DISTINCT
    t.tconst,
    btrim(w.word) COLLATE "C" AS word
FROM public.wi AS w
JOIN movie_migration_check.title AS t
    ON t.tconst = btrim(w.tconst)
WHERE w.word IS NOT NULL
  AND btrim(w.word) NOT IN ('', '\N');

INSERT INTO movie_migration_check.word (word)
SELECT DISTINCT word
FROM migration_wi;

INSERT INTO movie_migration_check.wi (tconst, word)
SELECT tconst, word
FROM migration_wi;

COMMIT;
----
-- Verification result:
-- All 17 movie tables matched the existing movie schema.
-- Row counts matched.
-- Full comparison: missing=0, extra=0, changed=0 for every table.