# Data Quality Report

Queries: [`sql/03_data_quality_checks.sql`](../sql/03_data_quality_checks.sql) · Results: [`outputs/data_quality/`](../outputs/data_quality/)

## Summary

The file is technically clean: no nulls, no duplicates, and the derived columns are correct. But a few business-logic checks failed. Taken together, they show this is a **synthetic dataset**, so some fields can't be used the way their names suggest.

| # | Check | Result | Status |
|---|---|---|---|
| 1 | Nulls / duplicate `post_id` | 0 / 0 across 29,999 rows | Pass |
| 2 | `post_date`, `post_hour`, `day_of_week` match `post_datetime` | 0 mismatches | Pass |
| 3 | `engagement_rate` = interactions / impressions | Max difference 0.00005 (rounding only) | Pass |
| 4 | Reach <= impressions, no negatives | 0 violations | Pass |
| 4b | Followers gained <= reach | 55 posts gained more followers than people reached | Fail |
| 5 | One `account_type` per account | **All 20 accounts** appear as both `brand` and `creator` | Fail |
| 6 | Reels Feed traffic only for reels | 16-17% of images and carousels come "from the Reels Feed" | Fail |
| 7 | Followers gained related to reach / engagement | Correlation -0.005 with both; uniform 0-1,000 | Fail |
| 8 | Performance label is a cut-off on engagement | Ranges overlap almost completely | Info |

## What I did about it

- **account_type**: left on the post row but kept out of `dim_account` and out of account-level analysis. It behaves like a random post attribute, not an account property.
- **followers_gained**: kept, but not used as a success metric. Query E1 shows Low and Viral posts both average ~500 new followers, so it can't measure ROI here.
- **traffic_source**: reported as-is, with a note that the source/format combinations aren't fully realistic.
- **performance tier**: treated as a given label (like an external rating), not something I can rebuild from the metrics.
- **engagement_rate**: recalculated from the parts and aggregated as a weighted rate.

## Why it matters

Without these checks it's easy to "find" things like "Reels at 6pm on Sunday are the best strategy", because some segment will always come out on top by a hair. The checks, plus the confidence intervals in query C1, are what stopped me from reporting noise as insight.
