# DAX for the Power BI Report

Tables in the model:

- `fact_posts` (from `powerbi/data/fact_posts.csv`)
- `dim_account` (from `powerbi/data/dim_account.csv`)
- `dim_date` (calculated table, below)
- `lever_impact` (from `outputs/analysis/c5_lever_impact_summary.csv`, used on page 3)

Relationships (both single direction, many-to-one):

- `fact_posts[account_id]` -> `dim_account[account_id]`
- `fact_posts[post_date]` -> `dim_date[Date]`

Tip: put all measures in an empty table called `_Measures` (Home > Enter data > load an empty table) so they're easy to find.

---

## Date table

```DAX
dim_date =
ADDCOLUMNS (
    CALENDAR ( DATE ( 2024, 11, 1 ), DATE ( 2025, 11, 30 ) ),
    "Year", YEAR ( [Date] ),
    "Month Num", MONTH ( [Date] ),
    "Month", FORMAT ( [Date], "mmm yyyy" ),
    "Month Start", DATE ( YEAR ( [Date] ), MONTH ( [Date] ), 1 ),
    "Weekday", FORMAT ( [Date], "dddd" ),
    "Weekday Num", WEEKDAY ( [Date], 2 )
)
```

After creating it: Table tools > **Mark as date table** (column `Date`). Sort `Month` by `Month Start` and `Weekday` by `Weekday Num`.

---

## Calculated columns (in `fact_posts`)

Engagement decile (1 = top 10% of posts), used for the concentration chart:

```DAX
Engagement Decile =
VAR PostRank =
    RANKX ( ALL ( fact_posts ), fact_posts[total_engagement], , DESC, SKIP )
RETURN
    ROUNDUP ( DIVIDE ( PostRank, COUNTROWS ( ALL ( fact_posts ) ) ) * 10, 0 )
```

```DAX
Decile Label =
IF (
    fact_posts[Engagement Decile] = 1,
    "Top 10%",
    ( fact_posts[Engagement Decile] - 1 ) * 10 & "-" & fact_posts[Engagement Decile] * 10 & "%"
)
```

Sort `Decile Label` by `Engagement Decile`, `performance_tier` by `performance_tier_order`, and `day_of_week` by `day_of_week_num`.

---

## Core measures

```DAX
Total Posts = COUNTROWS ( fact_posts )
```

```DAX
Total Engagement = SUM ( fact_posts[total_engagement] )
```

```DAX
Total Reach = SUM ( fact_posts[reach] )
```

```DAX
Total Impressions = SUM ( fact_posts[impressions] )
```

```DAX
Engagement Rate = DIVIDE ( [Total Engagement], [Total Impressions] )
```
Format as percentage, 2 decimals. Note this is the *weighted* rate, the same as the SQL. `AVERAGE(fact_posts[engagement_rate])` would give every post equal weight.

```DAX
Avg Engagement per Post = DIVIDE ( [Total Engagement], [Total Posts] )
```

```DAX
Avg Reach per Post = DIVIDE ( [Total Reach], [Total Posts] )
```

```DAX
Save Rate = DIVIDE ( SUM ( fact_posts[saves] ), [Total Impressions] )
```

```DAX
Share Rate = DIVIDE ( SUM ( fact_posts[shares] ), [Total Impressions] )
```

---

## Performance tier measures

```DAX
Viral Posts % =
DIVIDE (
    CALCULATE ( [Total Posts], fact_posts[performance_tier] = "Viral" ),
    [Total Posts]
)
```

```DAX
Top Tier Posts % =
DIVIDE (
    CALCULATE ( [Total Posts], fact_posts[performance_tier] IN { "High", "Viral" } ),
    [Total Posts]
)
```

```DAX
Engagement Share =
DIVIDE (
    [Total Engagement],
    CALCULATE ( [Total Engagement], ALL ( fact_posts[Decile Label], fact_posts[Engagement Decile] ) )
)
```

```DAX
Cumulative Engagement % =
VAR CurrentDecile = MAX ( fact_posts[Engagement Decile] )
RETURN
    DIVIDE (
        CALCULATE (
            [Total Engagement],
            ALL ( fact_posts[Decile Label], fact_posts[Engagement Decile] ),
            fact_posts[Engagement Decile] <= CurrentDecile
        ),
        CALCULATE ( [Total Engagement], ALL ( fact_posts[Decile Label], fact_posts[Engagement Decile] ) )
    )
```

---

## Benchmark measures (account page)

Benchmark = engagement rate across all accounts currently selected, so it respects the date/format slicers:

```DAX
Benchmark ER =
CALCULATE ( [Engagement Rate], ALLSELECTED ( dim_account ) )
```

```DAX
ER vs Benchmark = DIVIDE ( [Engagement Rate] - [Benchmark ER], [Benchmark ER] )
```

```DAX
Reach per Follower =
DIVIDE (
    [Total Reach],
    SUMX ( fact_posts, RELATED ( dim_account[follower_count] ) )
)
```

```DAX
Account ER Rank =
RANKX ( ALLSELECTED ( dim_account[account_name] ), [Engagement Rate], , DESC, DENSE )
```

---

## Time intelligence

```DAX
Engagement Prev Month =
CALCULATE ( [Total Engagement], DATEADD ( dim_date[Date], -1, MONTH ) )
```

```DAX
Engagement MoM % =
DIVIDE ( [Total Engagement] - [Engagement Prev Month], [Engagement Prev Month] )
```

---

## Dynamic title (optional)

```DAX
Selection Title =
"Showing " & FORMAT ( [Total Posts], "#,0" ) & " posts | "
    & FORMAT ( MIN ( dim_date[Date] ), "mmm yyyy" ) & " - "
    & FORMAT ( MAX ( dim_date[Date] ), "mmm yyyy" )
```
