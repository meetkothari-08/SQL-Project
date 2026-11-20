# Power BI Dashboard: Build Guide

Four pages, each answering one question. Building it takes about 2-3 hours.

## 0. Setup

1. Run `python scripts/run_pipeline.py` so `powerbi/data/` exists.
2. Power BI Desktop > **Get data > Text/CSV**:
   - `powerbi/data/fact_posts.csv`
   - `powerbi/data/dim_account.csv`
   - `outputs/analysis/c5_lever_impact_summary.csv` (rename the table to `lever_impact`)
3. In Power Query check the types: `post_date` = Date, `post_datetime` = Date/Time, `has_call_to_action` = True/False, `engagement_rate` = Decimal. Close & Apply.
4. **View > Themes > Browse for themes** > `powerbi/theme.json`.
5. Create `dim_date`, the calculated columns and the measures from [dax_measures.md](dax_measures.md).
6. Model view: create the two relationships listed at the top of that file.
7. Save as `powerbi/Instagram_Engagement_Dashboard.pbix`.

**Slicer panel** (copy it onto every page and sync it via View > Sync slicers): Month (`dim_date[Month]`), `media_type`, `content_category`, `dim_account[size_tier]`.

---

## Page 1: Overview ("How did we do?")

| Visual | Fields |
|---|---|
| 5 KPI cards | Total Posts, Total Engagement, Engagement Rate, Total Reach, Top Tier Posts % |
| Line + clustered column chart | X: `dim_date[Month]`. Columns: Total Engagement. Line: Engagement Rate |
| Clustered bar | Y: `performance_tier`. X: Avg Engagement per Post |
| Donut | Legend: `media_type`. Values: Total Posts |
| Text box | 2-3 sentence summary of the page |

Title the line chart "Engagement rate held at ~4.2% all year": a title that states the finding is better than "Monthly trend".

---

## Page 2: What drives engagement ("Where do results come from?")

| Visual | Fields |
|---|---|
| Line + clustered column (Pareto) | X: `Decile Label`. Columns: Engagement Share. Line: Cumulative Engagement % |
| Card | "Top 10% of posts = 34% of engagement" (measure: Cumulative Engagement % filtered to decile 1, or a text box) |
| Clustered column | X: `performance_tier`. Values: Avg Reach per Post and Avg Engagement per Post. **Key visual**: reach stays flat while engagement climbs |
| 100% stacked bar | Y: `performance_tier`. Values: sum of likes, comments, shares, saves |
| Table | `performance_tier`, Engagement Rate, Save Rate, Share Rate |

---

## Page 3: Content & timing ("Does format or timing matter?")

| Visual | Fields |
|---|---|
| Bar chart | `lever_impact`: Y = `dimension`, X = `gap_pct_points`. Sort descending. Shows the tier gap dwarfs everything else |
| Matrix (heatmap) | Rows: `content_category`. Columns: `media_type`. Values: Engagement Rate. Conditional formatting > Background color > gradient |
| Matrix (heatmap) | Rows: `day_of_week`. Columns: `daypart`. Values: Engagement Rate. Same formatting |
| Clustered bar | Y: `media_type`. X: Engagement Rate. Add a constant line at 0.0417 (overall) from the Analytics pane |
| Clustered bar | Y: `hashtag_band`. X: Engagement Rate |

Tip for the heatmaps: set the gradient min/max to fixed values (e.g. 3.8% and 4.6%). Otherwise Power BI stretches tiny differences into dramatic colours.

---

## Page 4: Account benchmarking ("Which accounts over/under perform?")

| Visual | Fields |
|---|---|
| Table | `account_name`, `size_tier`, `follower_count`, Total Posts, Engagement Rate, ER vs Benchmark, Viral Posts %, Account ER Rank. Conditional formatting: data bars on ER vs Benchmark (green positive, pink negative) |
| Clustered bar | Y: `account_name`. X: ER vs Benchmark. Sort by value |
| Scatter | X: `dim_account[follower_count]`. Y: Reach per Follower. Details: `account_name`. Legend: `size_tier` |
| Clustered column | X: `size_tier`. Y: Reach per Follower |

---

## Optional Page 5: About the data

A text-only page listing the data quality checks from `docs/data_quality_report.md` (pass/fail table) and the main limitation (synthetic data). Recruiters like seeing that the data was validated.

---

## Finishing

- Keep a consistent layout: title top-left, slicers in a left or top strip, KPI cards first.
- Add page navigation buttons (Insert > Buttons > Navigator > Page navigator).
- Export screenshots of each page to `images/` (`overview.png`, `drivers.png`, `content_timing.png`, `accounts.png`) and add them to the README.
- Optionally **File > Export > PDF** to `powerbi/Instagram_Engagement_Dashboard.pdf`, so people without Power BI can see it.
