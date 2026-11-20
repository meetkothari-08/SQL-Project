-- 05_analysis.sql
-- Business questions answered on top of fact_posts / dim_account.
--
-- Note on engagement rate: I use SUM(engagement) / SUM(impressions) for groups
-- instead of AVG(engagement_rate). Averaging row-level rates gives a post with
-- 500 impressions the same weight as one with 50,000.


------------------------------------------------------------------------------
-- A. OVERALL PERFORMANCE
------------------------------------------------------------------------------

-- A1. Headline KPIs for the whole period
-- @name: a1_headline_kpis
SELECT
    COUNT(*)                                                         AS total_posts,
    COUNT(DISTINCT account_id)                                       AS accounts,
    SUM(total_engagement)                                            AS total_engagement,
    SUM(reach)                                                       AS total_reach,
    SUM(impressions)                                                 AS total_impressions,
    ROUND(100.0 * SUM(total_engagement) / SUM(impressions), 2)       AS engagement_rate_pct,
    ROUND(AVG(total_engagement), 1)                                  AS avg_engagement_per_post,
    ROUND(AVG(reach), 0)                                             AS avg_reach_per_post,
    SUM(followers_gained)                                            AS total_followers_gained
FROM fact_posts;


-- A2. Monthly trend with month-over-month change
-- Nov 2024 and Nov 2025 are partial months, so I flag them rather than drop them.
-- @name: a2_monthly_trend
WITH monthly AS (
    SELECT
        post_month,
        COUNT(*)                                                     AS posts,
        SUM(total_engagement)                                        AS engagement,
        ROUND(100.0 * SUM(total_engagement) / SUM(impressions), 2)   AS engagement_rate_pct,
        ROUND(AVG(reach), 0)                                         AS avg_reach
    FROM fact_posts
    GROUP BY post_month
)
SELECT
    post_month,
    posts,
    engagement,
    engagement_rate_pct,
    avg_reach,
    ROUND(100.0 * (engagement - LAG(engagement) OVER (ORDER BY post_month))
          / LAG(engagement) OVER (ORDER BY post_month), 1)          AS engagement_mom_pct,
    CASE WHEN post_month IN (MIN(post_month) OVER (), MAX(post_month) OVER ())
         THEN 'partial' ELSE 'full' END                              AS month_status
FROM monthly
ORDER BY post_month;


------------------------------------------------------------------------------
-- B. WHERE DOES ENGAGEMENT ACTUALLY COME FROM?
------------------------------------------------------------------------------

-- B1. Engagement concentration: what share of engagement do the top posts drive?
-- @name: b1_engagement_concentration
WITH ranked AS (
    SELECT
        total_engagement,
        NTILE(10) OVER (ORDER BY total_engagement DESC) AS decile
    FROM fact_posts
),
by_decile AS (
    SELECT
        decile,
        COUNT(*)              AS posts,
        SUM(total_engagement) AS engagement
    FROM ranked
    GROUP BY decile
)
SELECT
    CASE WHEN decile = 1 THEN 'Top 10%'
         ELSE ((decile - 1) * 10) || '-' || (decile * 10) || '%' END       AS post_group,
    posts,
    engagement,
    ROUND(100.0 * engagement / SUM(engagement) OVER (), 1)                 AS pct_of_engagement,
    ROUND(100.0 * SUM(engagement) OVER (ORDER BY decile)
          / SUM(engagement) OVER (), 1)                                    AS cumulative_pct
FROM by_decile
ORDER BY decile;


-- B2. What separates Viral posts from Low posts?
-- Compare how many people saw them (reach) vs what those people did.
-- @name: b2_performance_tier_profile
WITH tiers AS (
    SELECT
        performance_tier,
        performance_tier_order,
        COUNT(*)                                                    AS posts,
        ROUND(AVG(reach), 0)                                        AS avg_reach,
        ROUND(AVG(impressions), 0)                                  AS avg_impressions,
        ROUND(AVG(total_engagement), 0)                             AS avg_engagement,
        ROUND(100.0 * SUM(total_engagement) / SUM(impressions), 2)  AS engagement_rate_pct,
        ROUND(100.0 * SUM(saves)    / SUM(impressions), 3)          AS save_rate_pct,
        ROUND(100.0 * SUM(shares)   / SUM(impressions), 3)          AS share_rate_pct,
        ROUND(100.0 * SUM(comments) / SUM(impressions), 3)          AS comment_rate_pct
    FROM fact_posts
    GROUP BY performance_tier, performance_tier_order
)
SELECT
    performance_tier,
    posts,
    avg_reach,
    avg_impressions,
    avg_engagement,
    engagement_rate_pct,
    save_rate_pct,
    share_rate_pct,
    comment_rate_pct,
    ROUND(avg_engagement * 1.0
          / MIN(avg_engagement) OVER (), 2)                         AS engagement_vs_low_tier
FROM tiers
ORDER BY performance_tier_order;


-- B3. Engagement mix: does the type of interaction change across tiers?
-- @name: b3_engagement_mix_by_tier
SELECT
    performance_tier,
    ROUND(100.0 * SUM(likes)    / SUM(total_engagement), 1) AS pct_likes,
    ROUND(100.0 * SUM(comments) / SUM(total_engagement), 1) AS pct_comments,
    ROUND(100.0 * SUM(shares)   / SUM(total_engagement), 1) AS pct_shares,
    ROUND(100.0 * SUM(saves)    / SUM(total_engagement), 1) AS pct_saves
FROM fact_posts
GROUP BY performance_tier, performance_tier_order
ORDER BY performance_tier_order;


------------------------------------------------------------------------------
-- C. DO FORMAT, TOPIC AND TIMING MATTER?
------------------------------------------------------------------------------

-- C1. Media type, with a 95% confidence interval on the average post engagement rate.
-- If the intervals overlap, the "winner" could just be noise.
-- @name: c1_media_type_confidence
SELECT
    media_type,
    COUNT(*)                                                        AS posts,
    ROUND(100.0 * AVG(engagement_rate), 3)                          AS avg_engagement_rate_pct,
    ROUND(100.0 * (AVG(engagement_rate)
          - 1.96 * STDDEV_SAMP(engagement_rate) / SQRT(COUNT(*)::numeric)), 3) AS ci_low_pct,
    ROUND(100.0 * (AVG(engagement_rate)
          + 1.96 * STDDEV_SAMP(engagement_rate) / SQRT(COUNT(*)::numeric)), 3) AS ci_high_pct,
    ROUND(AVG(reach), 0)                                            AS avg_reach,
    ROUND(AVG(followers_gained), 0)                                 AS avg_followers_gained
FROM fact_posts
GROUP BY media_type
ORDER BY avg_engagement_rate_pct DESC;


-- C2. Category x media type matrix (engagement rate %)
-- @name: c2_category_media_matrix
SELECT
    content_category,
    ROUND(100.0 * SUM(total_engagement) FILTER (WHERE media_type = 'image')
          / SUM(impressions) FILTER (WHERE media_type = 'image'), 2)    AS image_er_pct,
    ROUND(100.0 * SUM(total_engagement) FILTER (WHERE media_type = 'carousel')
          / SUM(impressions) FILTER (WHERE media_type = 'carousel'), 2) AS carousel_er_pct,
    ROUND(100.0 * SUM(total_engagement) FILTER (WHERE media_type = 'reel')
          / SUM(impressions) FILTER (WHERE media_type = 'reel'), 2)     AS reel_er_pct,
    ROUND(100.0 * SUM(total_engagement) / SUM(impressions), 2)          AS overall_er_pct,
    COUNT(*)                                                            AS posts
FROM fact_posts
GROUP BY content_category
ORDER BY overall_er_pct DESC;


-- C3. Posting time: weekday x daypart (engagement rate %)
-- @name: c3_weekday_daypart_heatmap
SELECT
    day_of_week,
    ROUND(100.0 * SUM(total_engagement) FILTER (WHERE daypart = 'Night (0-5)')
          / SUM(impressions) FILTER (WHERE daypart = 'Night (0-5)'), 2)       AS night_er_pct,
    ROUND(100.0 * SUM(total_engagement) FILTER (WHERE daypart = 'Morning (6-11)')
          / SUM(impressions) FILTER (WHERE daypart = 'Morning (6-11)'), 2)    AS morning_er_pct,
    ROUND(100.0 * SUM(total_engagement) FILTER (WHERE daypart = 'Afternoon (12-17)')
          / SUM(impressions) FILTER (WHERE daypart = 'Afternoon (12-17)'), 2) AS afternoon_er_pct,
    ROUND(100.0 * SUM(total_engagement) FILTER (WHERE daypart = 'Evening (18-23)')
          / SUM(impressions) FILTER (WHERE daypart = 'Evening (18-23)'), 2)   AS evening_er_pct,
    COUNT(*)                                                                  AS posts
FROM fact_posts
GROUP BY day_of_week, day_of_week_num
ORDER BY day_of_week_num;


-- C4. Caption features: call-to-action and hashtag count
-- @name: c4_caption_features
SELECT
    'Call to action'                                              AS feature,
    CASE WHEN has_call_to_action THEN 'Yes' ELSE 'No' END         AS segment,
    COUNT(*)                                                      AS posts,
    ROUND(100.0 * SUM(total_engagement) / SUM(impressions), 2)    AS engagement_rate_pct
FROM fact_posts
GROUP BY has_call_to_action

UNION ALL

SELECT
    'Hashtags',
    hashtag_band,
    COUNT(*),
    ROUND(100.0 * SUM(total_engagement) / SUM(impressions), 2)
FROM fact_posts
GROUP BY hashtag_band

UNION ALL

SELECT
    'Caption length',
    caption_band,
    COUNT(*),
    ROUND(100.0 * SUM(total_engagement) / SUM(impressions), 2)
FROM fact_posts
GROUP BY caption_band

ORDER BY feature, segment;


-- C5. Summary: how much does each lever move engagement rate?
-- For every dimension, find the best and worst segment and the gap between them.
-- @name: c5_lever_impact_summary
WITH segment_rates AS (
    SELECT 'Media type' AS dimension, media_type AS segment,
           SUM(total_engagement) * 1.0 / SUM(impressions) AS er
    FROM fact_posts GROUP BY media_type
    UNION ALL
    SELECT 'Content category', content_category,
           SUM(total_engagement) * 1.0 / SUM(impressions)
    FROM fact_posts GROUP BY content_category
    UNION ALL
    SELECT 'Day of week', day_of_week,
           SUM(total_engagement) * 1.0 / SUM(impressions)
    FROM fact_posts GROUP BY day_of_week
    UNION ALL
    SELECT 'Daypart', daypart,
           SUM(total_engagement) * 1.0 / SUM(impressions)
    FROM fact_posts GROUP BY daypart
    UNION ALL
    SELECT 'Traffic source', traffic_source,
           SUM(total_engagement) * 1.0 / SUM(impressions)
    FROM fact_posts GROUP BY traffic_source
    UNION ALL
    SELECT 'Call to action', CASE WHEN has_call_to_action THEN 'Yes' ELSE 'No' END,
           SUM(total_engagement) * 1.0 / SUM(impressions)
    FROM fact_posts GROUP BY has_call_to_action
    UNION ALL
    SELECT 'Performance tier', performance_tier,
           SUM(total_engagement) * 1.0 / SUM(impressions)
    FROM fact_posts GROUP BY performance_tier
),
ranked AS (
    SELECT
        dimension,
        segment,
        er,
        ROW_NUMBER() OVER (PARTITION BY dimension ORDER BY er DESC) AS best_rank,
        ROW_NUMBER() OVER (PARTITION BY dimension ORDER BY er ASC)  AS worst_rank
    FROM segment_rates
)
SELECT
    dimension,
    MAX(CASE WHEN best_rank  = 1 THEN segment END)               AS best_segment,
    ROUND(100.0 * MAX(er), 2)                                    AS best_er_pct,
    MAX(CASE WHEN worst_rank = 1 THEN segment END)               AS worst_segment,
    ROUND(100.0 * MIN(er), 2)                                    AS worst_er_pct,
    ROUND(100.0 * (MAX(er) - MIN(er)), 2)                        AS gap_pct_points,
    ROUND(100.0 * (MAX(er) - MIN(er)) / MIN(er), 1)              AS relative_gap_pct
FROM ranked
GROUP BY dimension
ORDER BY gap_pct_points DESC;


------------------------------------------------------------------------------
-- D. ACCOUNT BENCHMARKING
------------------------------------------------------------------------------

-- D1. Account scorecard compared with the overall benchmark
-- @name: d1_account_scorecard
WITH account_stats AS (
    SELECT
        f.account_id,
        COUNT(*)                                                       AS posts,
        SUM(f.total_engagement) * 1.0 / SUM(f.impressions)             AS er,
        AVG(f.reach)                                                   AS avg_reach,
        AVG(CASE WHEN f.performance_tier = 'Viral' THEN 1.0 ELSE 0 END) AS viral_share,
        AVG(CASE WHEN f.performance_tier = 'Low'   THEN 1.0 ELSE 0 END) AS low_share
    FROM fact_posts f
    GROUP BY f.account_id
),
benchmark AS (
    SELECT SUM(total_engagement) * 1.0 / SUM(impressions) AS overall_er
    FROM fact_posts
)
SELECT
    a.account_name,
    a.size_tier,
    a.follower_count,
    s.posts,
    ROUND(100.0 * s.er, 2)                                      AS engagement_rate_pct,
    ROUND(100.0 * (s.er - b.overall_er) / b.overall_er, 1)      AS vs_benchmark_pct,
    ROUND(s.avg_reach, 0)                                       AS avg_reach,
    ROUND(s.avg_reach / a.follower_count, 2)                    AS reach_per_follower,
    ROUND(100.0 * s.viral_share, 1)                             AS viral_post_pct,
    ROUND(100.0 * s.low_share, 1)                               AS low_post_pct,
    RANK() OVER (ORDER BY s.er DESC)                            AS er_rank
FROM account_stats s
JOIN dim_account a ON a.account_id = s.account_id
CROSS JOIN benchmark b
ORDER BY er_rank;


-- D2. Small vs large accounts: reach relative to audience size
-- @name: d2_size_tier_comparison
SELECT
    a.size_tier,
    COUNT(DISTINCT a.account_id)                                  AS accounts,
    COUNT(*)                                                      AS posts,
    ROUND(AVG(a.follower_count), 0)                               AS avg_followers,
    ROUND(AVG(f.reach), 0)                                        AS avg_reach,
    ROUND(SUM(f.reach) * 1.0 / SUM(a.follower_count), 2)          AS reach_per_follower,
    ROUND(100.0 * SUM(f.total_engagement) / SUM(f.impressions), 2) AS engagement_rate_pct
FROM fact_posts f
JOIN dim_account a ON a.account_id = f.account_id
GROUP BY a.size_tier
ORDER BY avg_followers;


-- D3. Monthly leaderboard: the top 3 accounts by engagement rate each month
-- @name: d3_monthly_top_accounts
WITH monthly_account AS (
    SELECT
        post_month,
        account_id,
        COUNT(*)                                                     AS posts,
        ROUND(100.0 * SUM(total_engagement) / SUM(impressions), 2)   AS engagement_rate_pct
    FROM fact_posts
    GROUP BY post_month, account_id
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (PARTITION BY post_month ORDER BY engagement_rate_pct DESC) AS month_rank
    FROM monthly_account
)
SELECT
    r.post_month,
    r.month_rank,
    a.account_name,
    r.posts,
    r.engagement_rate_pct
FROM ranked r
JOIN dim_account a ON a.account_id = r.account_id
WHERE r.month_rank <= 3
ORDER BY r.post_month, r.month_rank;


------------------------------------------------------------------------------
-- E. FOLLOWER GROWTH
------------------------------------------------------------------------------

-- E1. Does better engagement lead to more followers?
-- @name: e1_followers_gained_by_tier
SELECT
    performance_tier,
    COUNT(*)                                       AS posts,
    ROUND(AVG(total_engagement), 0)                AS avg_engagement,
    ROUND(AVG(followers_gained), 0)                AS avg_followers_gained,
    ROUND(100.0 * SUM(followers_gained)
          / SUM(SUM(followers_gained)) OVER (), 1) AS pct_of_all_followers_gained
FROM fact_posts
GROUP BY performance_tier, performance_tier_order
ORDER BY performance_tier_order;
