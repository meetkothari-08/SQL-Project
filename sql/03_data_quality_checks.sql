-- 03_data_quality_checks.sql
-- Before analysing anything I wanted to know how far this data can be trusted.
-- Each check returns a small result; the findings are written up in
-- docs/data_quality_report.md.


-- 1. Completeness and uniqueness
-- @name: dq01_completeness
SELECT
    COUNT(*)                                   AS total_rows,
    COUNT(DISTINCT post_id)                    AS distinct_post_ids,
    COUNT(*) - COUNT(DISTINCT post_id)         AS duplicate_post_ids,
    COUNT(DISTINCT account_id)                 AS accounts,
    MIN(post_date)                             AS first_post,
    MAX(post_date)                             AS last_post,
    SUM(CASE WHEN likes IS NULL OR reach IS NULL OR impressions IS NULL
             THEN 1 ELSE 0 END)                AS rows_missing_core_metrics
FROM instagram_posts;


-- 2. Do the pre-calculated date columns agree with post_datetime?
-- @name: dq02_derived_date_columns
SELECT
    SUM(CASE WHEN post_date <> CAST(post_datetime AS DATE) THEN 1 ELSE 0 END)     AS bad_post_date,
    SUM(CASE WHEN post_hour <> EXTRACT(HOUR FROM post_datetime) THEN 1 ELSE 0 END) AS bad_post_hour,
    SUM(CASE WHEN day_of_week <> CASE EXTRACT(ISODOW FROM post_datetime)
                                    WHEN 1 THEN 'Monday'   WHEN 2 THEN 'Tuesday'
                                    WHEN 3 THEN 'Wednesday' WHEN 4 THEN 'Thursday'
                                    WHEN 5 THEN 'Friday'   WHEN 6 THEN 'Saturday'
                                    ELSE 'Sunday' END
             THEN 1 ELSE 0 END)                                                    AS bad_day_of_week
FROM instagram_posts;


-- 3. Can engagement_rate be rebuilt from its parts?
-- If yes, I can recalculate it myself and aggregate it properly (weighted).
-- @name: dq03_engagement_rate_formula
SELECT
    ROUND(MAX(ABS(engagement_rate
          - (likes + comments + shares + saves) * 1.0 / impressions)), 5) AS max_abs_difference,
    SUM(CASE WHEN ABS(engagement_rate
          - (likes + comments + shares + saves) * 1.0 / impressions) > 0.0001
             THEN 1 ELSE 0 END)                                          AS rows_off_by_more_than_rounding
FROM instagram_posts;


-- 4. Basic logical rules for the metrics
-- @name: dq04_metric_sanity
SELECT
    SUM(CASE WHEN reach > impressions THEN 1 ELSE 0 END)              AS reach_above_impressions,
    SUM(CASE WHEN likes < 0 OR comments < 0 OR shares < 0
              OR saves < 0 OR reach < 0 THEN 1 ELSE 0 END)            AS negative_values,
    SUM(CASE WHEN impressions = 0 THEN 1 ELSE 0 END)                  AS zero_impressions,
    SUM(CASE WHEN followers_gained > reach THEN 1 ELSE 0 END)         AS gained_more_followers_than_reach
FROM instagram_posts;


-- 5. Is account_type a stable attribute of an account? (It should be.)
-- @name: dq05_account_type_consistency
SELECT
    account_id,
    COUNT(DISTINCT account_type)                                  AS distinct_account_types,
    SUM(CASE WHEN account_type = 'creator' THEN 1 ELSE 0 END)     AS creator_posts,
    SUM(CASE WHEN account_type = 'brand'   THEN 1 ELSE 0 END)     AS brand_posts,
    COUNT(DISTINCT follower_count)                                AS distinct_follower_counts
FROM instagram_posts
GROUP BY account_id
ORDER BY account_id;


-- 6. Does traffic_source make sense for the media type?
-- An image or carousel should not be discovered through the Reels feed.
-- @name: dq06_traffic_source_vs_media
SELECT
    media_type,
    COUNT(*)                                                                AS posts,
    SUM(CASE WHEN traffic_source = 'Reels Feed' THEN 1 ELSE 0 END)          AS from_reels_feed,
    ROUND(100.0 * SUM(CASE WHEN traffic_source = 'Reels Feed' THEN 1 ELSE 0 END)
          / COUNT(*), 1)                                                    AS pct_from_reels_feed
FROM instagram_posts
GROUP BY media_type
ORDER BY media_type;


-- 7. Is followers_gained plausible?
-- A small account gaining 1,000 followers from one average post would be unusual,
-- and gains should rise with reach. Correlations near 0 mean they don't.
-- @name: dq07_followers_gained_plausibility
SELECT
    MIN(followers_gained)                                         AS min_gained,
    MAX(followers_gained)                                         AS max_gained,
    ROUND(AVG(followers_gained), 1)                               AS avg_gained,
    SUM(CASE WHEN followers_gained > 0.10 * follower_count
             THEN 1 ELSE 0 END)                                   AS posts_gaining_over_10pct_of_followers,
    ROUND(CORR(followers_gained, reach)::numeric, 3)              AS corr_with_reach,
    ROUND(CORR(followers_gained, likes + comments + shares + saves)::numeric, 3)
                                                                  AS corr_with_engagement
FROM instagram_posts;


-- 8. How is performance_bucket_label assigned?
-- If it were a cut-off on engagement, the ranges would not overlap.
-- @name: dq08_performance_label_ranges
SELECT
    performance_bucket_label,
    COUNT(*)                                          AS posts,
    MIN(engagement_rate)                              AS min_engagement_rate,
    MAX(engagement_rate)                              AS max_engagement_rate,
    MIN(likes + comments + shares + saves)            AS min_engagement,
    MAX(likes + comments + shares + saves)            AS max_engagement
FROM instagram_posts
GROUP BY performance_bucket_label
ORDER BY MIN(engagement_rate);
