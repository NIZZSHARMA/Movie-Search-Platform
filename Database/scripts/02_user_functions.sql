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