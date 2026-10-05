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
-----
BEGIN;

DO $$
DECLARE
    v_user_id BIGINT;
    v_missing_user_id BIGINT;
    v_tconst TEXT;
    v_nconst TEXT;
    v_missing_title TEXT := 'portfolio_missing_title';
    v_missing_person TEXT := 'portfolio_missing_person';
BEGIN
    SELECT tconst INTO v_tconst
    FROM movie.title
    LIMIT 1;

    SELECT nconst INTO v_nconst
    FROM movie.person
    LIMIT 1;

    IF v_tconst IS NULL OR v_nconst IS NULL THEN
        RAISE EXCEPTION 'FAIL: Test requires a title and person';
    END IF;

    -- Ensure test IDs do not exist
    WHILE EXISTS (
        SELECT 1 FROM movie.title WHERE tconst = v_missing_title
    ) LOOP
        v_missing_title := v_missing_title || '_x';
    END LOOP;

    WHILE EXISTS (
        SELECT 1 FROM movie.person WHERE nconst = v_missing_person
    ) LOOP
        v_missing_person := v_missing_person || '_x';
    END LOOP;

    v_user_id := framework.create_user(
        'portfolio_bookmark_fk_test',
        'portfolio_bookmark_fk_test@example.com',
        'TEST_HASH_ONLY_NOT_FOR_LOGIN'
    );

    v_missing_user_id := framework.create_user(
        'portfolio_bookmark_missing_user',
        'portfolio_bookmark_missing_user@example.com',
        'TEST_HASH_ONLY_NOT_FOR_LOGIN'
    );

    DELETE FROM framework.app_user
    WHERE user_id = v_missing_user_id;

    BEGIN
        PERFORM framework.add_title_bookmark(
            v_missing_user_id, v_tconst
        );
        RAISE EXCEPTION 'FAIL: Missing user accepted for title bookmark';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'PASS: Title bookmark rejected missing user';
    END;

    BEGIN
        PERFORM framework.add_title_bookmark(
            v_user_id, v_missing_title
        );
        RAISE EXCEPTION 'FAIL: Missing title was accepted';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'PASS: Missing title was rejected';
    END;

    BEGIN
        PERFORM framework.add_person_bookmark(
            v_missing_user_id, v_nconst
        );
        RAISE EXCEPTION 'FAIL: Missing user accepted for person bookmark';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'PASS: Person bookmark rejected missing user';
    END;

    BEGIN
        PERFORM framework.add_person_bookmark(
            v_user_id, v_missing_person
        );
        RAISE EXCEPTION 'FAIL: Missing person was accepted';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'PASS: Missing person was rejected';
    END;

    IF EXISTS (
        SELECT 1 FROM framework.user_bookmark_title
        WHERE user_id IN (v_user_id, v_missing_user_id)
    ) OR EXISTS (
        SELECT 1 FROM framework.user_bookmark_person
        WHERE user_id IN (v_user_id, v_missing_user_id)
    ) THEN
        RAISE EXCEPTION 'FAIL: Rejected additions saved a bookmark';
    END IF;

    RAISE NOTICE 'PASS: Rejected additions saved no bookmarks';
END;
$$;

ROLLBACK;
------------
BEGIN;

DO $$
DECLARE
    v_function TEXT;
    v_case RECORD;
    v_expected TEXT;
BEGIN
    FOREACH v_function IN ARRAY ARRAY[
        'add_title_bookmark',
        'remove_title_bookmark',
        'add_person_bookmark',
        'remove_person_bookmark'
    ]
    LOOP
        FOR v_case IN
            SELECT *
            FROM (
                VALUES
                    ('NULL user ID', NULL::BIGINT, 'test_id'),
                    ('NULL item ID', 1::BIGINT, NULL::TEXT),
                    ('Empty item ID', 1::BIGINT, ''),
                    ('Blank item ID', 1::BIGINT, '   ')
            ) AS cases(label, user_id, item_id)
        LOOP
            IF v_case.user_id IS NULL THEN
                v_expected := 'User ID is required';
            ELSIF v_function IN (
                'add_title_bookmark', 'remove_title_bookmark'
            ) THEN
                v_expected := 'Title ID is required';
            ELSE
                v_expected := 'Person ID is required';
            END IF;

            BEGIN
                EXECUTE format(
                    'SELECT framework.%I($1, $2)',
                    v_function
                )
                USING v_case.user_id, v_case.item_id;

                RAISE EXCEPTION 'FAIL: % accepted %',
                    v_function, v_case.label;
            EXCEPTION
                WHEN raise_exception THEN
                    IF SQLERRM = v_expected THEN
                        RAISE NOTICE 'PASS: % rejected %',
                            v_function, v_case.label;
                    ELSE
                        RAISE;
                    END IF;
            END;
        END LOOP;
    END LOOP;
END;
$$;

ROLLBACK;
-----------------
BEGIN;

DO $$
DECLARE
    v_user_id BIGINT;
    v_count BIGINT;
BEGIN
    v_user_id := framework.create_user(
        'portfolio_search_test',
        'portfolio_search_test@example.com',
        'TEST_HASH_ONLY_NOT_FOR_LOGIN'
    );

    -- Temporary examples for each searchable field
    INSERT INTO movie.title (
        tconst, primary_title, original_title
    )
    VALUES
        ('portfolio_search_title', 'PortfolioSearchMarkerXYZ', NULL),
        ('portfolio_search_original', 'Original title test',
         'PortfolioSearchMarkerXYZ'),
        ('portfolio_search_plot', 'Plot test', NULL);

    INSERT INTO movie.omdb_extra (tconst, plot)
    VALUES (
        'portfolio_search_plot',
        'A story about PortfolioSearchMarkerXYZ.'
    );

    -- Check matching, letter case and spaces
    SELECT COUNT(*) INTO v_count
    FROM movie.string_search(
        v_user_id, '  PORTFOLIOSEARCHMARKERXYZ  '
    )
    WHERE tconst IN (
        'portfolio_search_title',
        'portfolio_search_original',
        'portfolio_search_plot'
    );

    IF v_count <> 3 THEN
        RAISE EXCEPTION 'FAIL: Expected all 3 test titles, got %',
            v_count;
    END IF;

    RAISE NOTICE 'PASS: Primary title, original title and plot matched';
    RAISE NOTICE 'PASS: Search ignored letter case and trimmed spaces';

    IF (
        SELECT COUNT(*)
        FROM framework.user_search_history
        WHERE user_id = v_user_id
          AND query_text = 'PORTFOLIOSEARCHMARKERXYZ'
          AND performed_at IS NOT NULL
    ) <> 1 THEN
        RAISE EXCEPTION 'FAIL: Search history is incorrect';
    END IF;

    RAISE NOTICE 'PASS: One history entry saved with text and timestamp';

    -- Search for text that is absent from all title/plot fields
    SELECT COUNT(*) INTO v_count
    FROM movie.string_search(
        v_user_id,
        'PortfolioSearchMarkerXYZ_NoResult_987654321'
    );

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL: Expected zero results, got %', v_count;
    END IF;

    IF (
        SELECT COUNT(*)
        FROM framework.user_search_history
        WHERE user_id = v_user_id
    ) <> 2 THEN
        RAISE EXCEPTION 'FAIL: No-result search was not recorded';
    END IF;

    RAISE NOTICE 'PASS: No-result search returned zero rows and saved history';
END;
$$;

ROLLBACK;
-----
BEGIN;

DO $$
DECLARE
    v_user_id BIGINT;
    v_missing_user_id BIGINT;
    v_case RECORD;
BEGIN
    v_user_id := framework.create_user(
        'portfolio_search_validation',
        'portfolio_search_validation@example.com',
        'TEST_HASH_ONLY_NOT_FOR_LOGIN'
    );

    FOR v_case IN
        SELECT *
        FROM (VALUES
            (NULL::BIGINT, 'test'::TEXT,
             'User ID is required'::TEXT),

            (v_user_id, NULL::TEXT,
             'Search text is required'),

            (v_user_id, '',
             'Search text is required'),

            (v_user_id, '   ',
             'Search text is required')
        ) AS cases(user_id, query_text, expected_error)
    LOOP
        BEGIN
            PERFORM *
            FROM movie.string_search(
                v_case.user_id,
                v_case.query_text
            );

            RAISE EXCEPTION 'FAIL: Expected error: %',
                v_case.expected_error;

        EXCEPTION
            WHEN raise_exception THEN
                IF SQLERRM IS DISTINCT FROM
                   v_case.expected_error THEN
                    RAISE;
                END IF;

                RAISE NOTICE 'PASS: %',
                    v_case.expected_error;
        END;
    END LOOP;

    -- Create and delete our own user to obtain a missing ID
    v_missing_user_id := framework.create_user(
        'portfolio_search_missing_user',
        'portfolio_search_missing_user@example.com',
        'TEST_HASH_ONLY_NOT_FOR_LOGIN'
    );

    DELETE FROM framework.app_user
    WHERE user_id = v_missing_user_id;

    BEGIN
        PERFORM *
        FROM movie.string_search(
            v_missing_user_id,
            'test'
        );

        RAISE EXCEPTION
            'FAIL: Missing user was accepted';

    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE
                'PASS: Missing user was rejected';
    END;

    IF EXISTS (
        SELECT 1
        FROM framework.user_search_history
        WHERE user_id IN (
            v_user_id,
            v_missing_user_id
        )
    ) THEN
        RAISE EXCEPTION
            'FAIL: Invalid search created history';
    END IF;

    RAISE NOTICE
        'PASS: Invalid searches did not create history';
END;
$$;

ROLLBACK;
---------
BEGIN;

DO $$
DECLARE
    v_user_a BIGINT;
    v_user_b BIGINT;
    v_average NUMERIC;
    v_votes BIGINT;
    v_title TEXT := 'portfolio_rating_test_title';
BEGIN
    -- Create temporary test users
    v_user_a := framework.create_user(
        'portfolio_rating_user_a',
        'portfolio_rating_a@example.com',
        'TEST_HASH_A'
    );

    v_user_b := framework.create_user(
        'portfolio_rating_user_b',
        'portfolio_rating_b@example.com',
        'TEST_HASH_B'
    );

    -- IMDb baseline: average 8 from 2 votes
    INSERT INTO movie.title (
        tconst, primary_title,
        base_average_rating, base_num_votes
    )
    VALUES (
        v_title, 'Temporary rating test', 8, 2
    );

    -- First user rates 10: (16 + 10) / 3
    v_average := movie.rate(
        v_user_a, '  ' || v_title || '  ', 10
    );

    SELECT num_votes INTO v_votes
    FROM movie.title_rating
    WHERE tconst = v_title;

    IF v_average IS NULL
       OR abs(v_average - 26::NUMERIC / 3) > 0.000001
       OR v_votes IS DISTINCT FROM 3::BIGINT THEN
        RAISE EXCEPTION
            'FAIL: First rating average or vote count is incorrect';
    END IF;

    RAISE NOTICE
        'PASS: First rating updated average and vote count';

    -- Same user changes rating to 4: (16 + 4) / 3
    v_average := movie.rate(v_user_a, v_title, 4);

    SELECT num_votes INTO v_votes
    FROM movie.title_rating
    WHERE tconst = v_title;

    IF v_average IS NULL
       OR abs(v_average - 20::NUMERIC / 3) > 0.000001
       OR v_votes IS DISTINCT FROM 3::BIGINT
       OR (
           SELECT COUNT(*)
           FROM framework.user_title_rating
           WHERE user_id = v_user_a
             AND tconst = v_title
             AND rating = 4
       ) <> 1 THEN
        RAISE EXCEPTION
            'FAIL: Re-rating did not correctly replace the previous vote';
    END IF;

    RAISE NOTICE
        'PASS: Re-rating replaced the rating without increasing votes';

    -- Second user rates 8: (16 + 4 + 8) / 4 = 7
    v_average := movie.rate(v_user_b, v_title, 8);

    SELECT average_rating, num_votes
    INTO v_average, v_votes
    FROM movie.title_rating
    WHERE tconst = v_title;

    IF v_average IS DISTINCT FROM 7::NUMERIC
       OR v_votes IS DISTINCT FROM 4::BIGINT
       OR (
           SELECT COUNT(*)
           FROM framework.user_title_rating
           WHERE tconst = v_title
       ) <> 2 THEN
        RAISE EXCEPTION
            'FAIL: Second user rating or combined average is incorrect';
    END IF;

    RAISE NOTICE
        'PASS: Two users have separate ratings and correct combined average';

    -- All three successful calls must appear in history
    IF (
        SELECT COUNT(*)
        FROM framework.title_rating_history
        WHERE tconst = v_title
    ) <> 3
    OR (
        SELECT COUNT(*)
        FROM framework.title_rating_history
        WHERE tconst = v_title
          AND user_id = v_user_a
          AND rating IN (10, 4)
          AND rated_at IS NOT NULL
    ) <> 2
    OR NOT EXISTS (
        SELECT 1
        FROM framework.title_rating_history
        WHERE tconst = v_title
          AND user_id = v_user_b
          AND rating = 8
          AND rated_at IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'FAIL: Rating history is incorrect';
    END IF;

    RAISE NOTICE
        'PASS: All three rating calls saved in history';

    IF NOT EXISTS (
        SELECT 1 FROM movie.title
        WHERE tconst = v_title
          AND base_average_rating = 8
          AND base_num_votes = 2
    ) THEN
        RAISE EXCEPTION 'FAIL: IMDb baseline was changed';
    END IF;

    RAISE NOTICE
        'PASS: Original IMDb rating and votes preserved';
END;
$$;

ROLLBACK;
--------------
BEGIN;

DO $$
DECLARE
    v_user_id BIGINT;
    v_missing_user_id BIGINT;
    v_title TEXT := 'portfolio_rating_validation_title';
    v_missing_title TEXT := 'portfolio_rating_missing_title';
    v_case RECORD;
    v_average NUMERIC;
    v_votes BIGINT;
BEGIN
    v_user_id := framework.create_user(
        'portfolio_rating_validation',
        'portfolio_rating_validation@example.com',
        'TEST_HASH_ONLY_NOT_FOR_LOGIN'
    );

    -- Title with no IMDb rating or votes
    INSERT INTO movie.title (tconst, primary_title)
    VALUES (v_title, 'Rating validation test');

    -- Check NULL, blank and out-of-range inputs
    FOR v_case IN
        SELECT *
        FROM (VALUES
            (NULL::BIGINT, v_title, 5,
             'User ID is required'::TEXT),
            (v_user_id, NULL::TEXT, 5,
             'Title ID is required'),
            (v_user_id, '', 5,
             'Title ID is required'),
            (v_user_id, '   ', 5,
             'Title ID is required'),
            (v_user_id, v_title, NULL::INTEGER,
             'Rating must be an integer between 1 and 10'),
            (v_user_id, v_title, 0,
             'Rating must be an integer between 1 and 10'),
            (v_user_id, v_title, 11,
             'Rating must be an integer between 1 and 10')
        ) AS cases(user_id, title_id, rating, expected_error)
    LOOP
        BEGIN
            PERFORM movie.rate(
                v_case.user_id,
                v_case.title_id,
                v_case.rating
            );

            RAISE EXCEPTION 'FAIL: Expected error: %',
                v_case.expected_error;
        EXCEPTION
            WHEN raise_exception THEN
                IF SQLERRM IS DISTINCT FROM
                   v_case.expected_error THEN
                    RAISE;
                END IF;

                RAISE NOTICE 'PASS: %', v_case.expected_error;
        END;
    END LOOP;

    -- Obtain an ID belonging to a deleted test user
    v_missing_user_id := framework.create_user(
        'portfolio_rating_missing_user',
        'portfolio_rating_missing@example.com',
        'TEST_HASH_ONLY_NOT_FOR_LOGIN'
    );

    DELETE FROM framework.app_user
    WHERE user_id = v_missing_user_id;

    BEGIN
        PERFORM movie.rate(v_missing_user_id, v_title, 5);
        RAISE EXCEPTION 'FAIL: Missing user was accepted';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'PASS: Missing user was rejected';
    END;

    -- Ensure the missing title ID does not exist
    WHILE EXISTS (
        SELECT 1 FROM movie.title
        WHERE tconst = v_missing_title
    ) LOOP
        v_missing_title := v_missing_title || '_x';
    END LOOP;

    BEGIN
        PERFORM movie.rate(v_user_id, v_missing_title, 5);
        RAISE EXCEPTION 'FAIL: Missing title was accepted';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM IS DISTINCT FROM
               format('Title not found: %s', v_missing_title) THEN
                RAISE;
            END IF;

            RAISE NOTICE 'PASS: Missing title was rejected';
    END;

    IF EXISTS (
        SELECT 1 FROM framework.user_title_rating
        WHERE tconst = v_title
    ) OR EXISTS (
        SELECT 1 FROM framework.title_rating_history
        WHERE tconst = v_title
    ) THEN
        RAISE EXCEPTION
            'FAIL: Invalid calls saved a rating or history';
    END IF;

    RAISE NOTICE
        'PASS: Invalid calls saved no rating or history';

    SELECT average_rating, num_votes
    INTO v_average, v_votes
    FROM movie.title_rating
    WHERE tconst = v_title;

    IF v_average IS NOT NULL
       OR v_votes IS DISTINCT FROM 0::BIGINT THEN
        RAISE EXCEPTION
            'FAIL: Unrated title should have NULL average and zero votes';
    END IF;

    RAISE NOTICE
        'PASS: Unrated title has NULL average and zero votes';

    -- Lower boundary: first local rating
    v_average := movie.rate(v_user_id, v_title, 1);

    SELECT num_votes INTO v_votes
    FROM movie.title_rating
    WHERE tconst = v_title;

    IF v_average IS DISTINCT FROM 1::NUMERIC
       OR v_votes IS DISTINCT FROM 1::BIGINT THEN
        RAISE EXCEPTION 'FAIL: Rating 1 was not handled correctly';
    END IF;

    RAISE NOTICE
        'PASS: Rating 1 accepted without IMDb baseline';

    -- Upper boundary: replace the same user's rating
    v_average := movie.rate(v_user_id, v_title, 10);

    SELECT num_votes INTO v_votes
    FROM movie.title_rating
    WHERE tconst = v_title;

    IF v_average IS DISTINCT FROM 10::NUMERIC
       OR v_votes IS DISTINCT FROM 1::BIGINT
       OR (
           SELECT COUNT(*)
           FROM framework.title_rating_history
           WHERE tconst = v_title
       ) <> 2 THEN
        RAISE EXCEPTION
            'FAIL: Rating 10, vote count or history is incorrect';
    END IF;

    RAISE NOTICE
        'PASS: Rating 10 accepted, one vote and two history entries';
END;
$$;

ROLLBACK;
--------
BEGIN;

DO $$
DECLARE
    v_user_id BIGINT;
    v_ids TEXT[];
    v_count BIGINT;
    v_title TEXT := 'portfolio_structured_test_title';
BEGIN
    v_user_id := framework.create_user(
        'portfolio_structured_test',
        'portfolio_structured_test@example.com',
        'TEST_HASH_ONLY_NOT_FOR_LOGIN'
    );

    INSERT INTO movie.title (tconst, primary_title)
    VALUES
        (v_title, 'Adventure StructTitleMarkerXYZ'),
        ('portfolio_structured_other_title',
         'Adventure StructTitleMarkerXYZ');

    INSERT INTO movie.omdb_extra (tconst, plot)
    VALUES (
        v_title,
        'A story about StructPlotMarkerXYZ in space.'
    );

    INSERT INTO movie.person (nconst, primary_name)
    VALUES
        ('portfolio_structured_person_a',
         'Actor StructPersonMarkerXYZ'),
        ('portfolio_structured_person_b',
         'Actor StructPersonMarkerXYZ Two');

    INSERT INTO movie.credit (
        tconst, ordering, nconst, category
    )
    VALUES
        (v_title, 1, 'portfolio_structured_person_a', 'actor'),
        (v_title, 2, 'portfolio_structured_person_b', 'actor');

    INSERT INTO movie.credit_character (
        tconst, ordering, character_name
    )
    VALUES
        (v_title, 1, 'Captain StructCharacterMarkerXYZ'),
        (v_title, 2, 'Doctor StructCharacterMarkerXYZ');

    -- All four fields: mixed case, spaces and substrings
    SELECT array_agg(s.tconst ORDER BY s.tconst)
    INTO v_ids
    FROM movie.structured_string_search(
        v_user_id,
        '  STRUCTTITLEMARKERXYZ  ',
        'structplotmarkerxyz',
        'STRUCTCHARACTERMARKERXYZ',
        'structpersonmarkerxyz'
    ) AS s;

    IF v_ids IS DISTINCT FROM ARRAY[v_title] THEN
        RAISE EXCEPTION
            'FAIL: Expected exactly one matching title, got %',
            v_ids;
    END IF;

    RAISE NOTICE
        'PASS: Four fields matched with case-insensitive substrings';
    RAISE NOTICE
        'PASS: Multiple matching credits produced no duplicate titles';

    -- Only title supplied: other fields ignored
    SELECT array_agg(s.tconst ORDER BY s.tconst)
    INTO v_ids
    FROM movie.structured_string_search(
        v_user_id,
        'StructTitleMarkerXYZ',
        NULL,
        '',
        '   '
    ) AS s;

    IF v_ids IS DISTINCT FROM ARRAY[
        'portfolio_structured_other_title',
        v_title
    ] THEN
        RAISE EXCEPTION
            'FAIL: Optional fields were not ignored correctly: %',
            v_ids;
    END IF;

    RAISE NOTICE
        'PASS: NULL and blank fields ignored correctly';

    -- A mismatching supplied field must exclude the title
    SELECT COUNT(*) INTO v_count
    FROM movie.structured_string_search(
        v_user_id,
        'StructTitleMarkerXYZ',
        'StructPlotNoMatchXYZ',
        'StructCharacterMarkerXYZ',
        'StructPersonMarkerXYZ'
    );

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'FAIL: Search returned a title despite plot mismatch';
    END IF;

    RAISE NOTICE
        'PASS: All supplied fields must match';

    IF (
        SELECT COUNT(*)
        FROM framework.user_search_history
        WHERE user_id = v_user_id
    ) <> 3 THEN
        RAISE EXCEPTION
            'FAIL: Expected three search history entries';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM framework.user_search_history
        WHERE user_id = v_user_id
          AND query_text::JSONB @> jsonb_build_object(
              'search_type', 'structured',
              'title', 'STRUCTTITLEMARKERXYZ',
              'plot', 'structplotmarkerxyz',
              'character', 'STRUCTCHARACTERMARKERXYZ',
              'person_name', 'structpersonmarkerxyz'
          )
          AND performed_at IS NOT NULL
    ) THEN
        RAISE EXCEPTION
            'FAIL: Search fields or timestamp missing from history';
    END IF;

    RAISE NOTICE
        'PASS: Search fields and timestamp saved in history';
    RAISE NOTICE
        'PASS: No-result search also saved in history';
END;
$$;

ROLLBACK;
------------------
BEGIN;

DO $$
DECLARE
    v_user_id BIGINT;
    v_missing_user_id BIGINT;
    v_case RECORD;
BEGIN
    v_user_id := framework.create_user(
        'portfolio_structured_validation',
        'portfolio_structured_validation@example.com',
        'TEST_HASH_ONLY_NOT_FOR_LOGIN'
    );

    FOR v_case IN
        SELECT *
        FROM (VALUES
            (NULL::BIGINT, 'test'::TEXT, NULL::TEXT,
             NULL::TEXT, NULL::TEXT,
             'User ID is required'::TEXT),

            (v_user_id, NULL, NULL, NULL, NULL,
             'At least one search field is required'),

            (v_user_id, '', '', '', '',
             'At least one search field is required'),

            (v_user_id, '   ', '   ', '   ', '   ',
             'At least one search field is required'),

            (v_user_id, NULL, '', '   ', NULL,
             'At least one search field is required')
        ) AS cases(
            user_id, title_text, plot_text,
            character_text, person_text, expected_error
        )
    LOOP
        BEGIN
            PERFORM *
            FROM movie.structured_string_search(
                v_case.user_id,
                v_case.title_text,
                v_case.plot_text,
                v_case.character_text,
                v_case.person_text
            );

            RAISE EXCEPTION 'FAIL: Expected error: %',
                v_case.expected_error;
        EXCEPTION
            WHEN raise_exception THEN
                IF SQLERRM IS DISTINCT FROM
                   v_case.expected_error THEN
                    RAISE;
                END IF;

                RAISE NOTICE 'PASS: %', v_case.expected_error;
        END;
    END LOOP;

    v_missing_user_id := framework.create_user(
        'portfolio_structured_missing_user',
        'portfolio_structured_missing@example.com',
        'TEST_HASH_ONLY_NOT_FOR_LOGIN'
    );

    DELETE FROM framework.app_user
    WHERE user_id = v_missing_user_id;

    BEGIN
        PERFORM *
        FROM movie.structured_string_search(
            v_missing_user_id, 'test', NULL, NULL, NULL
        );

        RAISE EXCEPTION 'FAIL: Missing user was accepted';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'PASS: Missing user was rejected';
    END;

    IF EXISTS (
        SELECT 1
        FROM framework.user_search_history
        WHERE user_id IN (v_user_id, v_missing_user_id)
    ) THEN
        RAISE EXCEPTION
            'FAIL: Invalid search created history';
    END IF;

    RAISE NOTICE
        'PASS: Invalid searches did not create history';
END;
$$;

ROLLBACK;
-------------------
BEGIN;

DO $$
DECLARE
    v_result JSONB;
    v_count BIGINT;
    v_input TEXT;
    v_missing TEXT := 'portfolio_coplayer_missing';
BEGIN
    INSERT INTO movie.person (nconst, primary_name)
    VALUES
        ('portfolio_cp_main', 'Test Main Actor'),
        ('portfolio_cp_b', 'Test Actor B'),
        ('portfolio_cp_c', 'Test Actress C'),
        ('portfolio_cp_director', 'Test Director'),
        ('portfolio_cp_alone', 'Test Actor Without Credits');

    INSERT INTO movie.title (tconst, primary_title)
    VALUES
        ('portfolio_cp_title_1', 'Coplayer Test One'),
        ('portfolio_cp_title_2', 'Coplayer Test Two');

    INSERT INTO movie.credit (
        tconst, ordering, nconst, category
    )
    VALUES
        ('portfolio_cp_title_1', 1, 'portfolio_cp_main', 'actor'),
        ('portfolio_cp_title_1', 2, 'portfolio_cp_b', 'actor'),
        ('portfolio_cp_title_1', 3, 'portfolio_cp_c', 'actress'),
        ('portfolio_cp_title_1', 4, 'portfolio_cp_director', 'director'),
        ('portfolio_cp_title_1', 5, 'portfolio_cp_b', 'actor'),
        ('portfolio_cp_title_1', 6, 'portfolio_cp_main', 'actor'),
        ('portfolio_cp_title_2', 1, 'portfolio_cp_main', 'actor'),
        ('portfolio_cp_title_2', 2, 'portfolio_cp_b', 'actor');

    -- WITH ORDINALITY checks the function's returned order
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', s.nconst,
            'name', s.primary_name,
            'count', s.shared_title_count
        )
        ORDER BY s.position
    )
    INTO v_result
    FROM movie.find_coplayers(
        '  portfolio_cp_main  '
    ) WITH ORDINALITY AS s(
        nconst, primary_name, shared_title_count, position
    );

    IF v_result IS DISTINCT FROM
       '[{"id":"portfolio_cp_b",
          "name":"Test Actor B","count":2},
         {"id":"portfolio_cp_c",
          "name":"Test Actress C","count":1}]'::JSONB THEN
        RAISE EXCEPTION
            'FAIL: Incorrect coplayers, counts or order: %',
            v_result;
    END IF;

    RAISE NOTICE
        'PASS: Correct actors and actresses returned';
    RAISE NOTICE
        'PASS: Shared titles counted once despite duplicate credits';
    RAISE NOTICE
        'PASS: Main actor and director excluded';
    RAISE NOTICE
        'PASS: Results ordered by shared title count and input trimmed';

    SELECT COUNT(*) INTO v_count
    FROM movie.find_coplayers('portfolio_cp_alone');

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'FAIL: Person without credits should return zero rows';
    END IF;

    RAISE NOTICE
        'PASS: Person without acting credits returned zero rows';

    FOREACH v_input IN ARRAY ARRAY[NULL::TEXT, '', '   ']
    LOOP
        BEGIN
            PERFORM *
            FROM movie.find_coplayers(v_input);

            RAISE EXCEPTION
                'FAIL: NULL or blank person ID was accepted';
        EXCEPTION
            WHEN raise_exception THEN
                IF SQLERRM IS DISTINCT FROM
                   'Person ID is required' THEN
                    RAISE;
                END IF;

                RAISE NOTICE
                    'PASS: NULL or blank person ID rejected';
        END;
    END LOOP;

    WHILE EXISTS (
        SELECT 1 FROM movie.person
        WHERE nconst = v_missing
    ) LOOP
        v_missing := v_missing || '_x';
    END LOOP;

    BEGIN
        PERFORM *
        FROM movie.find_coplayers(v_missing);

        RAISE EXCEPTION 'FAIL: Missing person was accepted';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM IS DISTINCT FROM
               format('Person not found: %s', v_missing) THEN
                RAISE;
            END IF;

            RAISE NOTICE 'PASS: Missing person rejected';
    END;
END;
$$;

ROLLBACK;
---------------
BEGIN;

DO $$
DECLARE
    v_rating NUMERIC;
    v_votes NUMERIC;
    v_titles BIGINT;
BEGIN
    INSERT INTO movie.person (nconst, primary_name)
    VALUES (
        'test_person_weighted_rating',
        'Temporary actor rating test'
    );

    INSERT INTO movie.title (
        tconst, primary_title,
        base_average_rating, base_num_votes
    )
    VALUES
        ('test_actor_rating_title_a', 'Test movie A', 8, 100),
        ('test_actor_rating_title_b', 'Test movie B', 6, 300);

    INSERT INTO movie.credit (
        tconst, ordering, nconst, category
    )
    VALUES
        (
            'test_actor_rating_title_a', 1,
            'test_person_weighted_rating', 'actor'
        ),
        (
            'test_actor_rating_title_a', 2,
            'test_person_weighted_rating', 'actor'
        ),
        (
            'test_actor_rating_title_b', 1,
            'test_person_weighted_rating', 'actor'
        );

    PERFORM movie.refresh_person_ratings();

    SELECT weighted_rating, total_votes, rated_title_count
    INTO v_rating, v_votes, v_titles
    FROM movie.person_rating
    WHERE nconst = 'test_person_weighted_rating';

    -- (8 × 100 + 6 × 300) / 400 = 6.5
    IF v_rating IS DISTINCT FROM 6.5::NUMERIC THEN
        RAISE EXCEPTION
            'FAIL: Expected weighted rating 6.5, got %',
            v_rating;
    END IF;

    RAISE NOTICE 'PASS: Vote-weighted actor rating is 6.5';

    IF v_votes IS DISTINCT FROM 400::NUMERIC THEN
        RAISE EXCEPTION
            'FAIL: Expected 400 votes, got %', v_votes;
    END IF;

    RAISE NOTICE 'PASS: Total votes are 400';

    IF v_titles IS DISTINCT FROM 2::BIGINT THEN
        RAISE EXCEPTION
            'FAIL: Expected 2 distinct titles, got %',
            v_titles;
    END IF;

    RAISE NOTICE
        'PASS: Duplicate credit did not count the movie twice';
END;
$$;

ROLLBACK;

-- Check the restored actor ratings after the test
SELECT
    COUNT(*) AS actors_with_rating,
    MIN(weighted_rating) AS lowest_rating,
    MAX(weighted_rating) AS highest_rating,
    COUNT(*) FILTER (
        WHERE weighted_rating IS NULL
           OR weighted_rating < 1
           OR weighted_rating > 10
           OR total_votes <= 0
           OR rated_title_count <= 0
    ) AS invalid_rows
FROM movie.person_rating;