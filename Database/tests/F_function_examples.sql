-- Section F: runnable examples for all 18 project functions.
-- Prerequisites: B2, C2, 02_user_functions.sql and 04_indexes.sql.
-- Run in the LOCAL movie_build_test database, not the RUC database.
-- Run the whole file. Export the final Data Output as CSV before closing it.
-- The before/after values below are captured by actual SELECT queries.
-- ROLLBACK removes fixtures, user changes and materialized-view refresh changes.
-- Identity sequences can advance despite ROLLBACK.
BEGIN;
CREATE TEMP TABLE f_output (
    step INTEGER GENERATED ALWAYS AS IDENTITY,
    example TEXT, phase TEXT, result JSONB
) ON COMMIT DROP;
CREATE TEMP TABLE f_context (user_id BIGINT);
CREATE FUNCTION pg_temp.f_snapshot(label TEXT, stage TEXT, query_text TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE payload JSONB;
BEGIN
    EXECUTE 'SELECT COALESCE(jsonb_agg(to_jsonb(q)), ''[]''::jsonb) FROM ('
        || query_text || ') AS q' INTO payload;
    INSERT INTO f_output(example, phase, result) VALUES(label, stage, payload);
END;
$$;
-- Dedicated fixtures; duplicate IDs stop the script rather than overwrite data.
INSERT INTO movie.title(tconst, primary_title, original_title,
    base_average_rating, base_num_votes)
VALUES ('section_f_title_a', 'Section F Adventure', 'Section F Adventure', 8, 2),
       ('section_f_title_b', 'Section F Companion', 'Section F Companion', 6, 2);
INSERT INTO movie.person(nconst, primary_name)
VALUES ('section_f_actor_a', 'Section F Unique Actor A'),
       ('section_f_actor_b', 'Section F Unique Actor B');
INSERT INTO movie.credit(tconst, ordering, nconst, category)
VALUES ('section_f_title_a', 1, 'section_f_actor_a', 'actor'),
       ('section_f_title_a', 2, 'section_f_actor_b', 'actress'),
       ('section_f_title_b', 1, 'section_f_actor_a', 'actor');
INSERT INTO movie.credit_character(tconst, ordering, character_name)
VALUES ('section_f_title_a', 1, 'Section F Hero');
INSERT INTO movie.omdb_extra(tconst, plot)
VALUES ('section_f_title_a', 'Section F space adventure');
INSERT INTO movie.genre(genre) VALUES ('Section F Genre') ON CONFLICT DO NOTHING;
INSERT INTO movie.title_genre(tconst, genre)
VALUES ('section_f_title_a', 'Section F Genre'),
       ('section_f_title_b', 'Section F Genre');
INSERT INTO movie.word(word) VALUES ('sectionf'), ('adventure'), ('companion')
ON CONFLICT DO NOTHING;
INSERT INTO movie.wi(tconst, word)
VALUES ('section_f_title_a', 'sectionf'), ('section_f_title_a', 'adventure'),
       ('section_f_title_b', 'sectionf'), ('section_f_title_b', 'companion');

SELECT pg_temp.f_snapshot('create_user', 'before', $query$SELECT user_id,username,email,password_hash FROM framework.app_user WHERE username IN ('section_f_user','section_f_user_updated') ORDER BY user_id$query$);

INSERT INTO f_context SELECT framework.create_user('  section_f_user  ','section_f@example.com','TEST_HASH_ONLY');

SELECT pg_temp.f_snapshot('create_user', 'after', $query$SELECT user_id,username,email,password_hash FROM framework.app_user WHERE username IN ('section_f_user','section_f_user_updated') ORDER BY user_id$query$);

SELECT pg_temp.f_snapshot('update_user', 'before', $query$SELECT user_id,username,email,password_hash FROM framework.app_user WHERE username IN ('section_f_user','section_f_user_updated') ORDER BY user_id$query$);

INSERT INTO f_output(example,phase,result) SELECT 'update_user','call',to_jsonb(q) FROM (SELECT framework.update_user((SELECT user_id FROM f_context),'  section_f_user_updated  ','section_f_updated@example.com','TEST_HASH_UPDATED') AS returned_user_id) q;

SELECT pg_temp.f_snapshot('update_user', 'after', $query$SELECT user_id,username,email,password_hash FROM framework.app_user WHERE username IN ('section_f_user','section_f_user_updated') ORDER BY user_id$query$);

SELECT pg_temp.f_snapshot('add_title_bookmark', 'before', $query$SELECT * FROM framework.user_bookmark_title WHERE user_id=(SELECT user_id FROM f_context) ORDER BY tconst$query$);

INSERT INTO f_output(example,phase,result) SELECT 'add_title_bookmark','call',to_jsonb(q) FROM (SELECT framework.add_title_bookmark((SELECT user_id FROM f_context),'  section_f_title_a  ') AS changed) q;

SELECT pg_temp.f_snapshot('add_title_bookmark', 'after', $query$SELECT * FROM framework.user_bookmark_title WHERE user_id=(SELECT user_id FROM f_context) ORDER BY tconst$query$);

SELECT pg_temp.f_snapshot('remove_title_bookmark', 'before', $query$SELECT * FROM framework.user_bookmark_title WHERE user_id=(SELECT user_id FROM f_context) ORDER BY tconst$query$);

INSERT INTO f_output(example,phase,result) SELECT 'remove_title_bookmark','call',to_jsonb(q) FROM (SELECT framework.remove_title_bookmark((SELECT user_id FROM f_context),'  section_f_title_a  ') AS changed) q;

SELECT pg_temp.f_snapshot('remove_title_bookmark', 'after', $query$SELECT * FROM framework.user_bookmark_title WHERE user_id=(SELECT user_id FROM f_context) ORDER BY tconst$query$);

SELECT pg_temp.f_snapshot('add_person_bookmark', 'before', $query$SELECT * FROM framework.user_bookmark_person WHERE user_id=(SELECT user_id FROM f_context) ORDER BY nconst$query$);

INSERT INTO f_output(example,phase,result) SELECT 'add_person_bookmark','call',to_jsonb(q) FROM (SELECT framework.add_person_bookmark((SELECT user_id FROM f_context),'  section_f_actor_a  ') AS changed) q;

SELECT pg_temp.f_snapshot('add_person_bookmark', 'after', $query$SELECT * FROM framework.user_bookmark_person WHERE user_id=(SELECT user_id FROM f_context) ORDER BY nconst$query$);

SELECT pg_temp.f_snapshot('remove_person_bookmark', 'before', $query$SELECT * FROM framework.user_bookmark_person WHERE user_id=(SELECT user_id FROM f_context) ORDER BY nconst$query$);

INSERT INTO f_output(example,phase,result) SELECT 'remove_person_bookmark','call',to_jsonb(q) FROM (SELECT framework.remove_person_bookmark((SELECT user_id FROM f_context),'  section_f_actor_a  ') AS changed) q;

SELECT pg_temp.f_snapshot('remove_person_bookmark', 'after', $query$SELECT * FROM framework.user_bookmark_person WHERE user_id=(SELECT user_id FROM f_context) ORDER BY nconst$query$);

SELECT pg_temp.f_snapshot('string_search', 'history before', $query$SELECT * FROM framework.user_search_history WHERE user_id=(SELECT user_id FROM f_context) ORDER BY search_id$query$);

SELECT pg_temp.f_snapshot('string_search', 'returned rows', $query$SELECT * FROM movie.string_search((SELECT user_id FROM f_context),'Section F Adventure')$query$);

SELECT pg_temp.f_snapshot('string_search', 'history after', $query$SELECT * FROM framework.user_search_history WHERE user_id=(SELECT user_id FROM f_context) ORDER BY search_id$query$);

SELECT pg_temp.f_snapshot('structured_string_search', 'history before', $query$SELECT * FROM framework.user_search_history WHERE user_id=(SELECT user_id FROM f_context) ORDER BY search_id$query$);

SELECT pg_temp.f_snapshot('structured_string_search', 'returned rows', $query$SELECT * FROM movie.structured_string_search((SELECT user_id FROM f_context),'Section F Adventure','space','Section F Hero','Section F Unique Actor A')$query$);

SELECT pg_temp.f_snapshot('structured_string_search', 'history after', $query$SELECT * FROM framework.user_search_history WHERE user_id=(SELECT user_id FROM f_context) ORDER BY search_id$query$);

SELECT pg_temp.f_snapshot('name_search', 'history before', $query$SELECT * FROM framework.user_search_history WHERE user_id=(SELECT user_id FROM f_context) ORDER BY search_id$query$);

SELECT pg_temp.f_snapshot('name_search', 'returned rows', $query$SELECT * FROM movie.name_search((SELECT user_id FROM f_context),'Section F Unique Actor')$query$);

SELECT pg_temp.f_snapshot('name_search', 'history after', $query$SELECT * FROM framework.user_search_history WHERE user_id=(SELECT user_id FROM f_context) ORDER BY search_id$query$);

SELECT pg_temp.f_snapshot('rate(10)', 'average before', $query$SELECT r.*,t.base_average_rating,t.base_num_votes FROM movie.title_rating r JOIN movie.title t USING(tconst) WHERE r.tconst='section_f_title_a'$query$);

SELECT pg_temp.f_snapshot('rate(10)', 'current rating before', $query$SELECT * FROM framework.user_title_rating WHERE user_id=(SELECT user_id FROM f_context) ORDER BY tconst$query$);

SELECT pg_temp.f_snapshot('rate(10)', 'history before', $query$SELECT * FROM framework.title_rating_history WHERE user_id=(SELECT user_id FROM f_context) ORDER BY rated_at,rating$query$);

INSERT INTO f_output(example,phase,result) SELECT 'rate(10)','call',to_jsonb(q) FROM (SELECT movie.rate((SELECT user_id FROM f_context),'section_f_title_a',10) AS returned_average) q;

SELECT pg_temp.f_snapshot('rate(10)', 'average after', $query$SELECT r.*,t.base_average_rating,t.base_num_votes FROM movie.title_rating r JOIN movie.title t USING(tconst) WHERE r.tconst='section_f_title_a'$query$);

SELECT pg_temp.f_snapshot('rate(10)', 'current rating after', $query$SELECT * FROM framework.user_title_rating WHERE user_id=(SELECT user_id FROM f_context) ORDER BY tconst$query$);

SELECT pg_temp.f_snapshot('rate(10)', 'history after', $query$SELECT * FROM framework.title_rating_history WHERE user_id=(SELECT user_id FROM f_context) ORDER BY rated_at,rating$query$);

SELECT pg_temp.f_snapshot('rate(4)', 'average before', $query$SELECT r.*,t.base_average_rating,t.base_num_votes FROM movie.title_rating r JOIN movie.title t USING(tconst) WHERE r.tconst='section_f_title_a'$query$);

SELECT pg_temp.f_snapshot('rate(4)', 'current rating before', $query$SELECT * FROM framework.user_title_rating WHERE user_id=(SELECT user_id FROM f_context) ORDER BY tconst$query$);

SELECT pg_temp.f_snapshot('rate(4)', 'history before', $query$SELECT * FROM framework.title_rating_history WHERE user_id=(SELECT user_id FROM f_context) ORDER BY rated_at,rating$query$);

INSERT INTO f_output(example,phase,result) SELECT 'rate(4)','call',to_jsonb(q) FROM (SELECT movie.rate((SELECT user_id FROM f_context),'section_f_title_a',4) AS returned_average) q;

SELECT pg_temp.f_snapshot('rate(4)', 'average after', $query$SELECT r.*,t.base_average_rating,t.base_num_votes FROM movie.title_rating r JOIN movie.title t USING(tconst) WHERE r.tconst='section_f_title_a'$query$);

SELECT pg_temp.f_snapshot('rate(4)', 'current rating after', $query$SELECT * FROM framework.user_title_rating WHERE user_id=(SELECT user_id FROM f_context) ORDER BY tconst$query$);

SELECT pg_temp.f_snapshot('rate(4)', 'history after', $query$SELECT * FROM framework.title_rating_history WHERE user_id=(SELECT user_id FROM f_context) ORDER BY rated_at,rating$query$);

SELECT pg_temp.f_snapshot('refresh_person_ratings', 'before', $query$SELECT * FROM movie.person_rating WHERE nconst IN ('section_f_actor_a','section_f_actor_b') ORDER BY nconst$query$);

SELECT movie.refresh_person_ratings();

SELECT pg_temp.f_snapshot('refresh_person_ratings', 'after', $query$SELECT * FROM movie.person_rating WHERE nconst IN ('section_f_actor_a','section_f_actor_b') ORDER BY nconst$query$);

SELECT pg_temp.f_snapshot('find_coplayers', 'returned rows', $query$SELECT * FROM movie.find_coplayers('Section F Unique Actor A')$query$);

SELECT pg_temp.f_snapshot('popular_actors', 'returned rows', $query$SELECT * FROM movie.popular_actors('section_f_title_a')$query$);

SELECT pg_temp.f_snapshot('similar_by_genre', 'returned rows', $query$SELECT * FROM movie.similar_by_genre('section_f_title_a',3)$query$);

SELECT pg_temp.f_snapshot('person_words', 'returned rows', $query$SELECT * FROM movie.person_words('Section F Unique Actor A',10)$query$);

SELECT pg_temp.f_snapshot('exact_match', 'returned rows', $query$SELECT * FROM movie.exact_match(ARRAY['sectionf','adventure'])$query$);

SELECT pg_temp.f_snapshot('best_match', 'returned rows', $query$SELECT * FROM movie.best_match(ARRAY['sectionf','adventure'])$query$);

SELECT pg_temp.f_snapshot('word_to_words', 'returned rows', $query$SELECT * FROM movie.word_to_words(ARRAY['sectionf'],10)$query$);

-- One result set contains every captured before/after and returned result.
SELECT step, example, phase, jsonb_pretty(result) AS result
FROM f_output ORDER BY step;
ROLLBACK;
