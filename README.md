# Instagram Engagement Analysis (SQL + Power BI)

An end-to-end analysis of 30,000 Instagram posts from 20 accounts (Nov 2024 - Nov 2025). I validated the data, modelled it in SQL, answered business questions about what drives engagement, and built a Power BI dashboard on top.

**Tools:** SQL (DuckDB, PostgreSQL-compatible) · Power BI (DAX, data modelling) · Python (only to run the SQL files)

## Business questions

1. How are the accounts performing overall, and is engagement growing?
2. Where does engagement come from: a few posts or all of them?
3. What separates a viral post from a low performer?
4. Do format, topic, posting time, CTAs or hashtags actually change engagement?
5. Which accounts are above or below the benchmark?

## Key findings

- **Engagement is concentrated:** the top 10% of posts generate **34%** of all engagement, and the top 20% generate over half.
- **Viral posts don't reach more people. They convert more of them.** Viral and Low posts both reach ~6,200 accounts, but Viral posts get **3.7x the engagement**.
- **Format and timing barely matter in this data.** The best vs worst media type, category, weekday or daypart differ by **0.17 percentage points or less** (around a 4.2% baseline), and the confidence intervals overlap. The gap between performance tiers is 5.07 points.
- **Small accounts punch above their weight:** accounts under 5K followers reach **1.6x** their follower count per post, while 10K+ accounts reach **0.39x**.
- **Data quality matters:** several fields failed logic checks (e.g. every account is labelled both "brand" and "creator", and follower growth is unrelated to reach), so I excluded them from conclusions.

Full write-up: [docs/insights.md](docs/insights.md) · Data checks: [docs/data_quality_report.md](docs/data_quality_report.md)

## Dashboard

Four pages: **Overview**, **What drives engagement**, **Content & timing**, **Account benchmarking**.

<!-- Add screenshots after building the report:
![Overview](images/overview.png)
![What drives engagement](images/drivers.png)
![Content & timing](images/content_timing.png)
![Account benchmarking](images/accounts.png)
-->

Build steps, visuals and DAX are in [powerbi/dashboard_guide.md](powerbi/dashboard_guide.md) and [powerbi/dax_measures.md](powerbi/dax_measures.md).

## Approach

```
data/instagram_posts.csv
        │
        ▼
01_create_table.sql      raw table, typed columns
02_load_data.sql         load CSV
03_data_quality_checks   8 checks: nulls, duplicates, formula, logic rules
04_data_model.sql        star schema: fact_posts + dim_account (+ dim_date in DAX)
05_analysis.sql          14 queries across 5 business questions
        │
        ├──► outputs/        query results as CSV
        └──► powerbi/data/   model tables for Power BI
```

SQL techniques used: CTEs, window functions (`NTILE`, `RANK`, `DENSE_RANK`, `ROW_NUMBER`, `LAG`, running `SUM() OVER`), conditional aggregation with `FILTER`, `CASE` bucketing, `UNION ALL`, joins to a dimension, and 95% confidence intervals with `STDDEV_SAMP`.

One choice worth calling out: group-level engagement rate is calculated as `SUM(engagement) / SUM(impressions)` (weighted), not as an average of each post's rate. The same logic is used in the DAX measures, so SQL and Power BI numbers match.

## Project structure

```
├── data/
│   └── instagram_posts.csv          raw data (29,999 rows)
├── sql/
│   ├── 01_create_table.sql
│   ├── 02_load_data.sql
│   ├── 03_data_quality_checks.sql
│   ├── 04_data_model.sql
│   └── 05_analysis.sql
├── outputs/
│   ├── data_quality/                results of each check
│   └── analysis/                    results of each analysis query
├── powerbi/
│   ├── dashboard_guide.md           page-by-page layout
│   ├── dax_measures.md              all measures and calculated tables
│   └── theme.json                   report theme
├── docs/
│   ├── data_dictionary.md
│   ├── data_quality_report.md
│   └── insights.md
├── scripts/
│   └── run_pipeline.py              runs every SQL file in order
└── requirements.txt
```

## How to run

```bash
git clone https://github.com/meetkothari-08/SQL-Project.git
cd SQL-Project
pip install -r requirements.txt
python scripts/run_pipeline.py
```

This creates `instagram.duckdb`, refreshes `outputs/`, and writes the Power BI tables to `powerbi/data/`.

**Using PostgreSQL instead:** the SQL is written to run on PostgreSQL too. Run the files in order in `psql`, replacing the `COPY` line in `02_load_data.sql` with the `\copy` command noted in that file.

## Limitations

The dataset is synthetic. Values are generated independently, which is why segments look so similar and why some fields fail logic checks. I kept the analysis honest about that instead of over-reading small differences. The workflow (validate, model, test whether differences are real, benchmark) is what I'd apply to real platform data.

## Data source

`Instagram_Analytics.csv`, a synthetic Instagram analytics dataset. <!-- TODO: add link to where the dataset was downloaded from -->

