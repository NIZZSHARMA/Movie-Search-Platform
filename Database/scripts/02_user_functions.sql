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