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