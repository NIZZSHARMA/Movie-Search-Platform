-- Run before and after applying 04_indexes.sql.
EXPLAIN (ANALYZE, BUFFERS)
SELECT w.tconst
FROM movie.wi AS w
WHERE w.word = 'love';

-- Observed locally on 2026-10-05:
-- Before: Parallel Seq Scan, 413.778 ms, 6184 rows.
-- After: Index Only Scan using wi_word_tconst_idx,
--        0.834 ms, 6184 rows.
-- Timings depend on cache and system load.
---
-- Person-based credit lookup.
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.tconst, c.category
FROM movie.credit AS c
WHERE c.nconst = 'nm0000138';

-- Observed locally on 2026-10-05:
-- Before: Parallel Seq Scan, 172.750 ms, 22 rows.
-- After: Index Only Scan using credit_nconst_tconst_idx,
--        0.183 ms, 22 rows.
-- Timings depend on cache and system load.