CREATE OR REPLACE FUNCTION framework.create_user(
    p_username TEXT,
    p_email TEXT,
    p_password_hash TEXT
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id BIGINT;
BEGIN
    IF p_username IS NULL OR btrim(p_username) = '' THEN
        RAISE EXCEPTION 'Username is required';
    END IF;

    IF p_email IS NULL OR btrim(p_email) = '' THEN
        RAISE EXCEPTION 'Email is required';
    END IF;

    IF p_password_hash IS NULL OR btrim(p_password_hash) = '' THEN
        RAISE EXCEPTION 'Password hash is required';
    END IF;

    INSERT INTO framework.app_user (
        username, email, password_hash
    )
    VALUES (
        btrim(p_username),
        btrim(p_email),
        p_password_hash
    )
    RETURNING user_id INTO v_user_id;

    RETURN v_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION framework.update_user(
    p_user_id BIGINT,
    p_username TEXT,
    p_email TEXT,
    p_password_hash TEXT
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id BIGINT;
BEGIN
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID is required';
    END IF;

    IF p_username IS NULL OR btrim(p_username) = '' THEN
        RAISE EXCEPTION 'Username is required';
    END IF;

    IF p_email IS NULL OR btrim(p_email) = '' THEN
        RAISE EXCEPTION 'Email is required';
    END IF;

    IF p_password_hash IS NULL OR btrim(p_password_hash) = '' THEN
        RAISE EXCEPTION 'Password hash is required';
    END IF;

    UPDATE framework.app_user
    SET
        username = btrim(p_username),
        email = btrim(p_email),
        password_hash = p_password_hash
    WHERE user_id = p_user_id
    RETURNING user_id INTO v_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found: %', p_user_id;
    END IF;

    RETURN v_user_id;
END;
$$;
-------------------
CREATE OR REPLACE FUNCTION framework.add_title_bookmark(
    p_user_id BIGINT,
    p_tconst TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows INTEGER;
BEGIN
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID is required';
    END IF;

    IF p_tconst IS NULL OR btrim(p_tconst) = '' THEN
        RAISE EXCEPTION 'Title ID is required';
    END IF;

    INSERT INTO framework.user_bookmark_title (user_id, tconst)
    VALUES (p_user_id, btrim(p_tconst))
    ON CONFLICT (user_id, tconst) DO NOTHING;

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RETURN v_rows = 1;
END;
$$;


CREATE OR REPLACE FUNCTION framework.remove_title_bookmark(
    p_user_id BIGINT,
    p_tconst TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows INTEGER;
BEGIN
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID is required';
    END IF;

    IF p_tconst IS NULL OR btrim(p_tconst) = '' THEN
        RAISE EXCEPTION 'Title ID is required';
    END IF;

    DELETE FROM framework.user_bookmark_title
    WHERE user_id = p_user_id
      AND tconst = btrim(p_tconst);

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RETURN v_rows = 1;
END;
$$;
--------------
CREATE OR REPLACE FUNCTION movie.string_search(
    p_user_id BIGINT,
    p_query TEXT
)
RETURNS TABLE (
    tconst TEXT,
    primary_title TEXT,
    plot TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_query TEXT;
BEGIN
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID is required';
    END IF;

    IF p_query IS NULL OR btrim(p_query) = '' THEN
        RAISE EXCEPTION 'Search text is required';
    END IF;

    v_query := btrim(p_query);

    -- Record one history entry for each search call
    INSERT INTO framework.user_search_history (
        user_id, query_text
    )
    VALUES (p_user_id, v_query);

    -- Match literal text, ignoring letter case
    RETURN QUERY
    SELECT
        t.tconst,
        t.primary_title,
        o.plot
    FROM movie.title AS t
    LEFT JOIN movie.omdb_extra AS o
        ON o.tconst = t.tconst
    WHERE strpos(lower(t.primary_title), lower(v_query)) > 0
       OR strpos(lower(t.original_title), lower(v_query)) > 0
       OR strpos(lower(o.plot), lower(v_query)) > 0
    ORDER BY t.tconst;
END;
$$; 
   -----------------------

BEGIN;

CREATE OR REPLACE VIEW movie.title_rating AS
SELECT
    t.tconst,
    CASE
        WHEN b.base_votes + u.user_votes > 0 THEN
            (
                b.base_total + u.user_total
            ) / (b.base_votes + u.user_votes)
        ELSE NULL
    END AS average_rating,
    b.base_votes + u.user_votes AS num_votes
FROM movie.title AS t
CROSS JOIN LATERAL (
    SELECT
        CASE
            WHEN t.base_average_rating IS NOT NULL
                 AND t.base_num_votes > 0
            THEN t.base_num_votes::BIGINT
            ELSE 0::BIGINT
        END AS base_votes,
        CASE
            WHEN t.base_average_rating IS NOT NULL
                 AND t.base_num_votes > 0
            THEN t.base_average_rating
                 * t.base_num_votes::NUMERIC
            ELSE 0::NUMERIC
        END AS base_total
) AS b
CROSS JOIN LATERAL (
    SELECT
        COUNT(*) AS user_votes,
        COALESCE(SUM(r.rating), 0)::NUMERIC AS user_total
    FROM framework.user_title_rating AS r
    WHERE r.tconst = t.tconst
) AS u;

CREATE OR REPLACE FUNCTION movie.rate(
    p_user_id BIGINT,
    p_tconst TEXT,
    p_rating INTEGER
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_tconst TEXT;
    v_average NUMERIC;
    v_rated_at TIMESTAMPTZ;
BEGIN
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID is required';
    END IF;

    IF p_tconst IS NULL OR btrim(p_tconst) = '' THEN
        RAISE EXCEPTION 'Title ID is required';
    END IF;

    IF p_rating IS NULL
       OR p_rating < 1
       OR p_rating > 10 THEN
        RAISE EXCEPTION
            'Rating must be an integer between 1 and 10';
    END IF;

    v_tconst := btrim(p_tconst);

    -- Serialize rating changes for the same title
    PERFORM 1
    FROM movie.title AS t
    WHERE t.tconst = v_tconst
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Title not found: %', v_tconst;
    END IF;

    v_rated_at := clock_timestamp();

    INSERT INTO framework.user_title_rating (
        user_id, tconst, rating, rated_at
    )
    VALUES (
        p_user_id, v_tconst, p_rating, v_rated_at
    )
    ON CONFLICT (user_id, tconst)
    DO UPDATE SET
        rating = EXCLUDED.rating,
        rated_at = EXCLUDED.rated_at;

    INSERT INTO framework.title_rating_history (
        user_id, tconst, rating, rated_at
    )
    VALUES (
        p_user_id, v_tconst, p_rating, v_rated_at
    );

    SELECT r.average_rating
    INTO v_average
    FROM movie.title_rating AS r
    WHERE r.tconst = v_tconst;

    RETURN v_average;
END;
$$;

COMMIT;
----------
CREATE OR REPLACE FUNCTION movie.structured_string_search(
    p_user_id BIGINT,
    p_title TEXT,
    p_plot TEXT,
    p_character TEXT,
    p_person_name TEXT
)
RETURNS TABLE (
    tconst TEXT,
    primary_title TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_title TEXT;
    v_plot TEXT;
    v_character TEXT;
    v_person_name TEXT;
BEGIN
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID is required';
    END IF;

    v_title := NULLIF(btrim(p_title), '');
    v_plot := NULLIF(btrim(p_plot), '');
    v_character := NULLIF(btrim(p_character), '');
    v_person_name := NULLIF(btrim(p_person_name), '');

    IF v_title IS NULL
       AND v_plot IS NULL
       AND v_character IS NULL
       AND v_person_name IS NULL THEN
        RAISE EXCEPTION
            'At least one search field is required';
    END IF;

    INSERT INTO framework.user_search_history (
        user_id, query_text
    )
    VALUES (
        p_user_id,
        jsonb_build_object(
            'search_type', 'structured',
            'title', v_title,
            'plot', v_plot,
            'character', v_character,
            'person_name', v_person_name
        )::TEXT
    );

    RETURN QUERY
    SELECT t.tconst, t.primary_title
    FROM movie.title AS t
    WHERE (
        v_title IS NULL
        OR strpos(lower(t.primary_title), lower(v_title)) > 0
        OR strpos(lower(t.original_title), lower(v_title)) > 0
    )
    AND (
        v_plot IS NULL
        OR EXISTS (
            SELECT 1
            FROM movie.omdb_extra AS o
            WHERE o.tconst = t.tconst
              AND strpos(lower(o.plot), lower(v_plot)) > 0
        )
    )
    AND (
        v_character IS NULL
        OR EXISTS (
            SELECT 1
            FROM movie.credit_character AS ch
            WHERE ch.tconst = t.tconst
              AND strpos(
                  lower(ch.character_name),
                  lower(v_character)
              ) > 0
        )
    )
    AND (
        v_person_name IS NULL
        OR EXISTS (
            SELECT 1
            FROM movie.credit AS c
            JOIN movie.person AS p
                ON p.nconst = c.nconst
            WHERE c.tconst = t.tconst
              AND strpos(
                  lower(p.primary_name),
                  lower(v_person_name)
              ) > 0
        )
    )
    ORDER BY t.tconst;
END;
$$;