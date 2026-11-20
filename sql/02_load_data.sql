-- 02_load_data.sql
-- Path is relative to the repo root (run_pipeline.py runs from there).
-- In PostgreSQL, use psql's client-side version instead:
--   \copy instagram_posts FROM 'data/instagram_posts.csv' WITH (FORMAT csv, HEADER true)

COPY instagram_posts FROM 'data/instagram_posts.csv' (FORMAT csv, HEADER true);

-- @name: load_row_count
SELECT COUNT(*) AS rows_loaded FROM instagram_posts;
