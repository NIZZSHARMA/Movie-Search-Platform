-- Support exact_match, best_match and word_to_words
-- keyword lookups by word.
CREATE INDEX IF NOT EXISTS wi_word_tconst_idx
ON movie.wi (word, tconst);

ANALYZE movie.wi;
------
-- Support person-based credit lookups.
CREATE INDEX IF NOT EXISTS credit_nconst_tconst_idx
ON movie.credit (nconst, tconst)
INCLUDE (category);

ANALYZE movie.credit;