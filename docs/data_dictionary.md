# Data Dictionary

## Raw table: `instagram_posts`

One row per post. 29,999 rows, 23 columns, no missing values.

| Column | Type | Description |
|---|---|---|
| `post_id` | varchar | Unique post ID (primary key) |
| `account_id` | integer | Account that published the post (20 accounts) |
| `account_type` | varchar | `creator` or `brand`. **Not consistent per account**, see data quality report |
| `follower_count` | integer | Followers of the account (constant per account) |
| `media_type` | varchar | `image`, `carousel`, `reel` |
| `content_category` | varchar | 10 topics: Beauty, Comedy, Fashion, Fitness, Food, Lifestyle, Music, Photography, Technology, Travel |
| `traffic_source` | varchar | Where viewers found the post: Home Feed, Explore, Hashtags, Reels Feed, Profile, External |
| `has_call_to_action` | boolean | Whether the caption had a CTA (stored as 0/1 in the CSV) |
| `post_datetime` | timestamp | Publish time (hourly precision) |
| `post_date`, `post_hour`, `day_of_week` | date / int / varchar | Pre-split parts of `post_datetime` (verified correct) |
| `likes`, `comments`, `shares`, `saves` | integer | Interaction counts |
| `reach` | integer | Unique accounts that saw the post |
| `impressions` | integer | Total times the post was shown (always >= reach) |
| `engagement_rate` | numeric | `(likes + comments + shares + saves) / impressions`, rounded to 4 dp |
| `followers_gained` | integer | Followers gained from the post (0 to 1,000) |
| `caption_length` | integer | Caption length in characters (70 to 166) |
| `hashtags_count` | integer | Hashtags used (0 to 21) |
| `performance_bucket_label` | varchar | Pre-assigned tier: `low`, `medium`, `high`, `viral` (exactly 25% each) |

## Model views (built in `sql/04_data_model.sql`)

### `dim_account`

| Column | Description |
|---|---|
| `account_id` | Key |
| `account_name` | Display name, e.g. "Account 07" |
| `follower_count` | Followers |
| `size_tier` | Small (<5K), Mid (5K-10K), Large (10K+) |
| `total_posts`, `first_post_date`, `last_post_date` | Activity summary |

### `fact_posts`

All raw columns (except `follower_count`, which lives in `dim_account`) plus:

| Column | Logic |
|---|---|
| `total_engagement` | likes + comments + shares + saves |
| `engagement_rate` | Recalculated from the parts at full precision |
| `post_month` | First day of the month |
| `day_of_week_num` | 1 = Monday ... 7 = Sunday (for sorting) |
| `daypart` | Night (0-5), Morning (6-11), Afternoon (12-17), Evening (18-23) |
| `caption_band` | Short (<100), Medium (100-139), Long (140+) |
| `hashtag_band` | 0-3, 4-8, 9-12, 13+ |
| `performance_tier` / `performance_tier_order` | Capitalised label with sort order 1-4 |

## Metric definitions

| Metric | Formula | Why |
|---|---|---|
| Engagement rate | SUM(total_engagement) / SUM(impressions) | Weighted, so high-volume posts count more than in an average of row rates |
| Save rate / Share rate | SUM(saves or shares) / SUM(impressions) | Interaction depth |
| Reach per follower | SUM(reach) / SUM(follower_count) | How far a post travels relative to audience size |
| vs benchmark | (account ER - overall ER) / overall ER | Relative over/under performance |
