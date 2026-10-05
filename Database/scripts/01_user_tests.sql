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