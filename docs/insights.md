# Findings and Recommendations

All numbers come from [`sql/05_analysis.sql`](../sql/05_analysis.sql); the result tables are in [`outputs/analysis/`](../outputs/analysis/).

## Headline numbers (Nov 2024 - Nov 2025)

| Posts | Accounts | Total engagement | Total reach | Engagement rate |
|---|---|---|---|---|
| 29,999 | 20 | 10.6M | 188.2M | 4.17% |

Monthly engagement rate stayed in a narrow 4.07%-4.30% band across all full months, with no real upward or downward trend (A2).

## 1. Engagement is concentrated in a small share of posts

- The **top 10% of posts drive 34% of all engagement**; the top 20% drive 51.5% (B1).
- The bottom half of posts together produce only 18%.

**So what:** average-based reporting hides where results come from. It's more useful to track how many posts reach the top tier than to track the average post.

## 2. Viral posts don't get more reach. They get more interaction per view

| Tier | Avg reach | Avg engagement | Engagement rate | vs Low |
|---|---|---|---|---|
| Low | 6,222 | 147 | 1.72% | 1.0x |
| Medium | 6,295 | 286 | 3.32% | 1.9x |
| High | 6,334 | 432 | 4.99% | 2.9x |
| Viral | 6,239 | 548 | 6.79% | 3.7x |

- Reach is basically the same in every tier (~6,200). Viral posts actually have *fewer* impressions (B2).
- The interaction mix is the same in every tier: ~81% likes, 12% saves, 4% shares, 2% comments (B3). Viral posts get more of everything, not more of one type.

**So what:** better performance came from converting viewers, not from distribution. Strategy should focus on what makes a post worth interacting with (the creative itself), not just on boosting reach.

## 3. Format, topic and timing barely move engagement rate

| Lever | Best | Worst | Gap |
|---|---|---|---|
| Performance tier (reference) | Viral 6.79% | Low 1.72% | **5.07 pts** |
| Traffic source | Profile 4.27% | Home Feed 4.10% | 0.17 pts |
| Content category | Fitness 4.24% | Travel 4.08% | 0.16 pts |
| Day of week | Tuesday 4.25% | Wednesday 4.12% | 0.13 pts |
| Media type | Image 4.20% | Carousel 4.12% | 0.07 pts |
| Call to action | No 4.20% | Yes 4.12% | 0.07 pts |
| Daypart | Night 4.21% | Evening 4.15% | 0.06 pts |

(C5)

- The 95% confidence intervals for reel (4.17-4.28%), image (4.18-4.27%) and carousel (4.14-4.23%) all overlap, so no format is a statistically clear winner (C1).
- The category x format matrix (C2) and weekday x daypart heatmap (C3) stay within roughly 3.9%-4.4% everywhere.

**So what:** in this data, "post a reel at 6pm" style rules aren't supported. The gap between a Viral and a Low post is about 30x bigger than the gap created by any of the other levers.

## 4. Account benchmarking

- Account engagement rates range from **3.97% (Account 06) to 4.34% (Account 18)**, within about ±5% of the 4.17% benchmark (D1).
- Account 06 is the clear laggard: lowest viral share (21.8%) and one of the highest low-tier shares (27.3%).
- **Small accounts reach 1.6x their follower count per post; large accounts reach 0.39x** (D2). Average reach is ~6,250 regardless of size, so smaller accounts get much more exposure relative to their audience.

## 5. Follower growth isn't linked to engagement

- Low and Viral posts both bring ~500 new followers on average, and each tier accounts for ~25% of total follower growth (E1).
- Combined with the data quality findings, `followers_gained` shouldn't be used as a success metric here.

## Recommendations

1. **Track top-tier share, not averages.** Report "% of posts in High/Viral" alongside engagement rate, because 20% of posts drive half the results.
2. **Study the creative of Viral posts.** Since reach isn't the difference, the next step is a qualitative review (hook, visuals, topic angle) of top-decile posts. That needs data this file doesn't have.
3. **Don't build a posting schedule from this data.** Timing and format effects are within noise; A/B tests would be needed before committing to a rule.
4. **Review Account 06.** It underperforms the benchmark by 4.8%, the largest gap of any account.
5. **Fix tracking before using growth metrics.** Account type, traffic source and followers gained need to be validated at the source.

## Limitations

The dataset is synthetic (see the [data quality report](data_quality_report.md)). The methods (weighted rates, confidence intervals, concentration analysis, benchmarking) carry over to real data; the specific conclusions about this "platform" don't.
