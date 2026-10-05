BEGIN;

SELECT framework.create_user(
    '  portfolio_test_user  ',
    '  portfolio_test@example.com  ',
    'TEST_HASH_ONLY_NOT_FOR_LOGIN'
) AS new_user_id;

SELECT
    user_id,
    username,
    email,
    username = 'portfolio_test_user' AS username_trim_ok,
    email = 'portfolio_test@example.com' AS email_trim_ok,
    password_hash = 'TEST_HASH_ONLY_NOT_FOR_LOGIN' AS hash_saved_ok
FROM framework.app_user
WHERE username = 'portfolio_test_user';

ROLLBACK;
-- Test: Duplicate email must be rejected
BEGIN;

DO $$
BEGIN
    PERFORM framework.create_user(
        'portfolio_email_test_1',
        'portfolio_email_test@example.com',
        'TEST_HASH_ONLY_NOT_FOR_LOGIN'
    );

    BEGIN
        PERFORM framework.create_user(
            'portfolio_email_test_2',
            'portfolio_email_test@example.com',
            'TEST_HASH_ONLY_NOT_FOR_LOGIN'
        );

        RAISE EXCEPTION 'FAIL: Duplicate email was accepted';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'PASS: Duplicate email was rejected';
    END;
END;
$$;

ROLLBACK;


-- Test: Blank username must be rejected
BEGIN;

DO $$
BEGIN
    BEGIN
        PERFORM framework.create_user(
            '   ',
            'portfolio_blank_test@example.com',
            'TEST_HASH_ONLY_NOT_FOR_LOGIN'
        );

        RAISE EXCEPTION 'FAIL: Blank username was accepted';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM = 'Username is required' THEN
                RAISE NOTICE 'PASS: Blank username was rejected';
            ELSE
                RAISE;
            END IF;
    END;
END;
$$;

ROLLBACK;


-- Tests: Blank email and blank password hash must be rejected
BEGIN;

DO $$
BEGIN
    BEGIN
        PERFORM framework.create_user(
            'portfolio_blank_email_test',
            '   ',
            'TEST_HASH_ONLY_NOT_FOR_LOGIN'
        );

        RAISE EXCEPTION 'FAIL: Blank email was accepted';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM = 'Email is required' THEN
                RAISE NOTICE 'PASS: Blank email was rejected';
            ELSE
                RAISE;
            END IF;
    END;

    BEGIN
        PERFORM framework.create_user(
            'portfolio_blank_hash_test',
            'portfolio_blank_hash@example.com',
            '   '
        );

        RAISE EXCEPTION 'FAIL: Blank password hash was accepted';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM = 'Password hash is required' THEN
                RAISE NOTICE 'PASS: Blank password hash was rejected';
            ELSE
                RAISE;
            END IF;
    END;
END;
$$;

ROLLBACK;
--
BEGIN;

DO $$
DECLARE
    v_user_id BIGINT;
    v_returned_id BIGINT;
BEGIN
    -- Create a temporary test user
    v_user_id := framework.create_user(
        'portfolio_update_test_before',
        'portfolio_update_before@example.com',
        'TEST_HASH_BEFORE'
    );

    -- Update the same user
    v_returned_id := framework.update_user(
        v_user_id,
        '  portfolio_update_test_after  ',
        '  portfolio_update_after@example.com  ',
        'TEST_HASH_AFTER'
    );

    -- Verify returned ID and saved values
    IF v_returned_id IS DISTINCT FROM v_user_id THEN
        RAISE EXCEPTION 'FAIL: Returned user ID is incorrect';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM framework.app_user
        WHERE user_id = v_user_id
          AND username = 'portfolio_update_test_after'
          AND email = 'portfolio_update_after@example.com'
          AND password_hash = 'TEST_HASH_AFTER'
    ) THEN
        RAISE EXCEPTION 'FAIL: User details were not updated correctly';
    END IF;

    RAISE NOTICE 'PASS: User ID stayed the same';
    RAISE NOTICE 'PASS: Username and email updated and trimmed';
    RAISE NOTICE 'PASS: Password hash updated';
END;
$$;

ROLLBACK;
----
BEGIN;

DO $$
DECLARE
    v_user_a BIGINT;
    v_user_b BIGINT;
    v_constraint TEXT;
BEGIN
    v_user_a := framework.create_user(
        'portfolio_update_a',
        'portfolio_update_a@example.com',
        'TEST_HASH_A'
    );

    v_user_b := framework.create_user(
        'portfolio_update_b',
        'portfolio_update_b@example.com',
        'TEST_HASH_B'
    );

    -- Reject another user's username
    BEGIN
        PERFORM framework.update_user(
            v_user_b,
            'portfolio_update_a',
            'portfolio_update_b@example.com',
            'TEST_HASH_CHANGED'
        );

        RAISE EXCEPTION 'FAIL: Duplicate username was accepted';
    EXCEPTION
        WHEN unique_violation THEN
            GET STACKED DIAGNOSTICS
                v_constraint = CONSTRAINT_NAME;

            IF v_constraint <> 'app_user_username_key' THEN
                RAISE;
            END IF;

            RAISE NOTICE 'PASS: Duplicate username was rejected';
    END;

    -- Reject another user's email
    BEGIN
        PERFORM framework.update_user(
            v_user_b,
            'portfolio_update_b',
            'portfolio_update_a@example.com',
            'TEST_HASH_CHANGED'
        );

        RAISE EXCEPTION 'FAIL: Duplicate email was accepted';
    EXCEPTION
        WHEN unique_violation THEN
            GET STACKED DIAGNOSTICS
                v_constraint = CONSTRAINT_NAME;

            IF v_constraint <> 'app_user_email_key' THEN
                RAISE;
            END IF;

            RAISE NOTICE 'PASS: Duplicate email was rejected';
    END;

    -- Failed updates must leave the original values intact
    IF NOT EXISTS (
        SELECT 1
        FROM framework.app_user
        WHERE user_id = v_user_b
          AND username = 'portfolio_update_b'
          AND email = 'portfolio_update_b@example.com'
          AND password_hash = 'TEST_HASH_B'
    ) THEN
        RAISE EXCEPTION 'FAIL: Rejected update changed user details';
    END IF;

    RAISE NOTICE 'PASS: Rejected updates preserved original details';
END;
$$;

ROLLBACK;
----
BEGIN;

DO $$
DECLARE
    v_user_id BIGINT;
    v_case RECORD;
BEGIN
    v_user_id := framework.create_user(
        'portfolio_update_validation',
        'portfolio_update_validation@example.com',
        'TEST_HASH_ORIGINAL'
    );

    FOR v_case IN
        SELECT *
        FROM (
            VALUES
                ('NULL user ID',
                 NULL::BIGINT, 'valid_name', 'valid@example.com',
                 'TEST_HASH', 'User ID is required'),

                ('NULL username',
                 v_user_id, NULL, 'valid@example.com',
                 'TEST_HASH', 'Username is required'),

                ('Blank username',
                 v_user_id, '   ', 'valid@example.com',
                 'TEST_HASH', 'Username is required'),

                ('NULL email',
                 v_user_id, 'valid_name', NULL,
                 'TEST_HASH', 'Email is required'),

                ('Blank email',
                 v_user_id, 'valid_name', '   ',
                 'TEST_HASH', 'Email is required'),

                ('NULL password hash',
                 v_user_id, 'valid_name', 'valid@example.com',
                 NULL, 'Password hash is required'),

                ('Blank password hash',
                 v_user_id, 'valid_name', 'valid@example.com',
                 '   ', 'Password hash is required')
        ) AS cases(label, user_id, username, email, hash, expected)
    LOOP
        BEGIN
            PERFORM framework.update_user(
                v_case.user_id,
                v_case.username,
                v_case.email,
                v_case.hash
            );

            RAISE EXCEPTION 'FAIL: % was accepted', v_case.label;
        EXCEPTION
            WHEN raise_exception THEN
                IF SQLERRM = v_case.expected THEN
                    RAISE NOTICE 'PASS: % was rejected', v_case.label;
                ELSE
                    RAISE;
                END IF;
        END;
    END LOOP;

    -- Remove only this temporary user to test a missing user ID
    DELETE FROM framework.app_user
    WHERE user_id = v_user_id;

    BEGIN
        PERFORM framework.update_user(
            v_user_id,
            'valid_name',
            'valid@example.com',
            'TEST_HASH'
        );

        RAISE EXCEPTION 'FAIL: Missing user was accepted';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM = format('User not found: %s', v_user_id) THEN
                RAISE NOTICE 'PASS: Missing user was rejected';
            ELSE
                RAISE;
            END IF;
    END;
END;
$$;

ROLLBACK;
------------
BEGIN;

DO $$
DECLARE
    v_user_id BIGINT;
    v_tconst TEXT;
BEGIN
    SELECT tconst INTO v_tconst
    FROM movie.title
    ORDER BY tconst
    LIMIT 1;

    IF v_tconst IS NULL THEN
        RAISE EXCEPTION 'FAIL: No title available for testing';
    END IF;

    v_user_id := framework.create_user(
        'portfolio_bookmark_test',
        'portfolio_bookmark_test@example.com',
        'TEST_HASH_ONLY_NOT_FOR_LOGIN'
    );

    -- Add bookmark, including spaces around the title ID
    IF framework.add_title_bookmark(
        v_user_id, '  ' || v_tconst || '  '
    ) IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'FAIL: Bookmark was not added';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM framework.user_bookmark_title
        WHERE user_id = v_user_id AND tconst = v_tconst
    ) THEN
        RAISE EXCEPTION 'FAIL: Bookmark row is missing';
    END IF;

    RAISE NOTICE 'PASS: Bookmark added and title ID trimmed';

    -- Adding again must not create a duplicate
    IF framework.add_title_bookmark(
        v_user_id, v_tconst
    ) IS DISTINCT FROM FALSE THEN
        RAISE EXCEPTION 'FAIL: Duplicate add returned an incorrect result';
    END IF;

    IF (
        SELECT COUNT(*)
        FROM framework.user_bookmark_title
        WHERE user_id = v_user_id AND tconst = v_tconst
    ) <> 1 THEN
        RAISE EXCEPTION 'FAIL: Bookmark count is incorrect';
    END IF;

    RAISE NOTICE 'PASS: Duplicate bookmark was not created';

    -- Remove bookmark
    IF framework.remove_title_bookmark(
        v_user_id, '  ' || v_tconst || '  '
    ) IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'FAIL: Bookmark was not removed';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM framework.user_bookmark_title
        WHERE user_id = v_user_id AND tconst = v_tconst
    ) THEN
        RAISE EXCEPTION 'FAIL: Bookmark still exists';
    END IF;

    RAISE NOTICE 'PASS: Bookmark removed';

 -- Removing again must return false
    IF framework.remove_title_bookmark(
        v_user_id, v_tconst
    ) IS DISTINCT FROM FALSE THEN
        RAISE EXCEPTION 'FAIL: Repeated removal returned an incorrect result';
    END IF;

    RAISE NOTICE 'PASS: Missing bookmark removal returned false';
END;
$$;

ROLLBACK;
-------------
CREATE OR REPLACE FUNCTION framework.add_person_bookmark(
    p_user_id BIGINT,
    p_nconst TEXT
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

    IF p_nconst IS NULL OR btrim(p_nconst) = '' THEN
        RAISE EXCEPTION 'Person ID is required';
    END IF;

    INSERT INTO framework.user_bookmark_person (user_id, nconst)
    VALUES (p_user_id, btrim(p_nconst))
    ON CONFLICT (user_id, nconst) DO NOTHING;

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RETURN v_rows = 1;
END;
$$;


CREATE OR REPLACE FUNCTION framework.remove_person_bookmark(
    p_user_id BIGINT,
    p_nconst TEXT
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

    IF p_nconst IS NULL OR btrim(p_nconst) = '' THEN
        RAISE EXCEPTION 'Person ID is required';
    END IF;

    DELETE FROM framework.user_bookmark_person
    WHERE user_id = p_user_id
      AND nconst = btrim(p_nconst);

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RETURN v_rows = 1;
END;
$$;
--------------------
BEGIN;

DO $$
DECLARE
    v_user_id BIGINT;
    v_nconst TEXT;
BEGIN
    SELECT nconst INTO v_nconst
    FROM movie.person
    ORDER BY nconst
    LIMIT 1;

    IF v_nconst IS NULL THEN
        RAISE EXCEPTION 'FAIL: No person available for testing';
    END IF;

    v_user_id := framework.create_user(
        'portfolio_person_bookmark_test',
        'portfolio_person_bookmark_test@example.com',
        'TEST_HASH_ONLY_NOT_FOR_LOGIN'
    );

    -- Add bookmark and check trimming
    IF framework.add_person_bookmark(
        v_user_id, '  ' || v_nconst || '  '
    ) IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'FAIL: Person bookmark was not added';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM framework.user_bookmark_person
        WHERE user_id = v_user_id AND nconst = v_nconst
    ) THEN
        RAISE EXCEPTION 'FAIL: Person bookmark row is missing';
    END IF;

    RAISE NOTICE 'PASS: Person bookmark added and ID trimmed';

    -- Repeated addition must not create a duplicate
    IF framework.add_person_bookmark(
        v_user_id, v_nconst
    ) IS DISTINCT FROM FALSE THEN
        RAISE EXCEPTION 'FAIL: Duplicate add returned an incorrect result';
    END IF;

    IF (
        SELECT COUNT(*)
        FROM framework.user_bookmark_person
        WHERE user_id = v_user_id AND nconst = v_nconst
    ) <> 1 THEN
        RAISE EXCEPTION 'FAIL: Person bookmark count is incorrect';
    END IF;

    RAISE NOTICE 'PASS: Duplicate person bookmark was not created';

    -- Remove bookmark and check the row is gone
    IF framework.remove_person_bookmark(
        v_user_id, '  ' || v_nconst || '  '
    ) IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'FAIL: Person bookmark was not removed';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM framework.user_bookmark_person
        WHERE user_id = v_user_id AND nconst = v_nconst
    ) THEN
        RAISE EXCEPTION 'FAIL: Person bookmark still exists';
    END IF;

    RAISE NOTICE 'PASS: Person bookmark removed';

    -- Repeated removal must return false
    IF framework.remove_person_bookmark(
        v_user_id, v_nconst
    ) IS DISTINCT FROM FALSE THEN
        RAISE EXCEPTION 'FAIL: Repeated removal returned an incorrect result';
    END IF;

    RAISE NOTICE 'PASS: Missing person bookmark removal returned false';
END;
$$;

ROLLBACK;