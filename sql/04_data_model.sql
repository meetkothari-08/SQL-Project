-- 04_data_model.sql
-- A small star schema on top of the raw table:
--   dim_account  - one row per account
--   fact_posts   - one row per post, with derived columns used in analysis
-- These two views are also what gets exported for Power BI.
-- (The date dimension is built in Power BI with DAX - see powerbi/dax_measures.md.)


DROP VIEW IF EXISTS fact_posts;
DROP VIEW IF EXISTS dim_account;


-- follower_count is constant per account, so it belongs here rather than on every post.
-- account_type is NOT included: the same account shows up as both 'brand' and
-- 'creator' (see dq05), so it is not a real account attribute.
CREATE VIEW dim_account AS
SELECT
    account_id,
    'Account ' || LPAD(CAST(account_id AS VARCHAR), 2, '0') AS account_name,
    MAX(follower_count)                                      AS follower_count,
    CASE
        WHEN MAX(follower_count) < 5000  THEN 'Small (<5K)'
        WHEN MAX(follower_count) < 10000 THEN 'Mid (5K-10K)'
        ELSE 'Large (10K+)'
    END                                                      AS size_tier,
    COUNT(*)                                                 AS total_posts,
    MIN(post_date)                                           AS first_post_date,
    MAX(post_date)                                           AS last_post_date
FROM instagram_posts
GROUP BY account_id;


CREATE VIEW fact_posts AS
SELECT
    post_id,
    account_id,
    account_type,

    -- time
    post_datetime,
    post_date,
    CAST(DATE_TRUNC('month', post_date) AS DATE)         AS post_month,
    post_hour,
    day_of_week,
    CAST(EXTRACT(ISODOW FROM post_date) AS INTEGER)      AS day_of_week_num,   -- 1 = Monday
    CASE
        WHEN post_hour BETWEEN 0  AND 5  THEN 'Night (0-5)'
        WHEN post_hour BETWEEN 6  AND 11 THEN 'Morning (6-11)'
        WHEN post_hour BETWEEN 12 AND 17 THEN 'Afternoon (12-17)'
        ELSE 'Evening (18-23)'
    END                                                  AS daypart,

    -- content
    media_type,
    content_category,
    traffic_source,
    has_call_to_action,
    caption_length,
    CASE
        WHEN caption_length < 100 THEN 'Short (<100)'
        WHEN caption_length < 140 THEN 'Medium (100-139)'
        ELSE 'Long (140+)'
    END                                                  AS caption_band,
    hashtags_count,
    CASE
        WHEN hashtags_count <= 3  THEN '0-3'
        WHEN hashtags_count <= 8  THEN '4-8'
        WHEN hashtags_count <= 12 THEN '9-12'
        ELSE '13+'
    END                                                  AS hashtag_band,

    -- metrics
    likes,
    comments,
    shares,
    saves,
    likes + comments + shares + saves                    AS total_engagement,
    reach,
    impressions,
    ROUND((likes + comments + shares + saves) * 1.0 / NULLIF(impressions, 0), 4)
                                                         AS engagement_rate,
    followers_gained,

    -- performance tier, renamed and given a sort order
    UPPER(SUBSTRING(performance_bucket_label, 1, 1))
        || SUBSTRING(performance_bucket_label, 2)        AS performance_tier,
    CASE performance_bucket_label
        WHEN 'low'    THEN 1
        WHEN 'medium' THEN 2
        WHEN 'high'   THEN 3
        WHEN 'viral'  THEN 4
    END                                                  AS performance_tier_order
FROM instagram_posts;


-- @name: model_row_counts
SELECT
    (SELECT COUNT(*) FROM dim_account) AS dim_account_rows,
    (SELECT COUNT(*) FROM fact_posts)  AS fact_posts_rows;
