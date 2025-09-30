# 🍊 Case Study #8 – Fresh Segments
<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/hero_images/hero_fresh_segments.png" width=60% height=60%>

## 💎 Business Context 
Danny founded Fresh Segments, a digital marketing agency that aggregates client customer data to analyze online ad click behavior and interest trends. See the original case study [here](https://8weeksqlchallenge.com/case-study-8/).

## ⚡️Problem Statement
Danny needs help to analyze aggregated interest metrics for a client and generate high-level insights about customer behavior and preferences. He prepared these 2 datasets. See the original schema [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/b84caab5db93cc00dea9500f779837babaa8283e/case08_fresh_segments/schema.sql).

<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/ERDs/ERD_fresh_segments_preview.png" width=80% height=80% >


## ❓Case Study Questions
### Section A: Data Exploration and Cleansing
1. [Update the `interest_metrics` table by modifying the `month_year` column to be a date data type with the start of the month](#a1)
2. [What is count of records in the `interest_metrics` for each `month_year` value sorted in chronological order (earliest to latest) with the null values appearing first?](#a2)
3. [What do you think we should do with these null values in the `interest_metrics`](#a3)
4. [How many `interest_id` values exist in the `interest_metrics` table but not in the `interest_map` table? What about the other way around?](#a4)
5. [Summarise the `id` values in the `interest_map` by its total record count in this table](#a5)
6. [What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where ` interest_id = 21246` in your joined output and include all columns from `interest_metrics` and all columns from `interest_map` except from the `id` column.](#a6)
7. [Are there any records in your joined table where the `month_year` value is before the `created_at` value from the `interest_map` table? Do you think these values are valid and why?](#a7)

### Section B: Interest Analysis
1. [Which interests have been present in all `month_year` dates in our dataset?](#b1)
2. [Using this same `total_months` measure - calculate the cumulative percentage of all records starting at 14 months - which `total_months` value passes the 90% cumulative percentage value?](#b2)
3. [If we were to remove all `interest_id` values which are lower than the `total_months` value we found in the previous question - how many total data points would we be removing?](#b3)
4. [Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed `interest` example for your arguments - think about what it means to have less months present from a segment perspective.](#b4)
5. [After removing these interests - how many unique interests are there for each month?](#b5)

### Section C: Segment Analysis
1. [Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any `month_year`? Only use the maximum composition value for each interest but you must keep the corresponding `month_year`.](#c1)
2. [Which 5 interests had the lowest average `ranking` value?](#c2)
3. [Which 5 interests had the largest standard deviation in their `percentile_ranking` value?](#c3)
4. [For the 5 interests found in the previous question - what was minimum and maximum `percentile_ranking` values for each interest and its corresponding `year_month` value? Can you describe what is happening for these 5 interests?](#c4)
5. [How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?](#c5)

### Section D: Index Analysis
1. [What is the top 10 interests by the average composition for each month?](#d1)
2. [For all of these top 10 interests - which interest appears the most often?](#d2)
3. [What is the average of the average composition for the top 10 interests for each month?](#d3)
4. [What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.](#d4)
5. [Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?](#d5)



## 🎯 My Solution
*View the complete syntax [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/b84caab5db93cc00dea9500f779837babaa8283e/case08_fresh_segments/solution.sql).*

### Section A: Data Exploration and Cleansing
<a id="a1"></a>
#### A1: Update the `interest_metrics` table by modifying the `month_year` column to be a date data type with the start of the month.


```sql
UPDATE interest_metrics
SET _year = NULL
WHERE _year::text ILIKE 'NULL';

UPDATE interest_metrics
SET _month = NULL
WHERE _month::text ILIKE 'NULL';

ALTER TABLE interest_metrics
    ALTER COLUMN month_year TYPE date
        USING make_date(_year::int, _month::int, 1);
```

| \_month | \_year | month\_year | interest\_id | composition | index\_value | ranking | percentile\_ranking |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 7 | 2018 | 2018-07-01 | 32486 | 11.89 | 6.19 | 1 | 99.86 |
| 7 | 2018 | 2018-07-01 | 6106 | 9.93 | 5.31 | 2 | 99.73 |
| 7 | 2018 | 2018-07-01 | 18923 | 10.85 | 5.29 | 3 | 99.59 |
| 7 | 2018 | 2018-07-01 | 6344 | 10.32 | 5.1 | 4 | 99.45 |
| 7 | 2018 | 2018-07-01 | 100 | 10.77 | 5.04 | 5 | 99.31 |
| … | … | … | … | … | … | … | …|


<a id="a2"></a>
#### A2: What is count of records in the `interest_metrics` for each `month_year` value sorted in chronological order (earliest to latest) with the null values appearing first?


```sql
SELECT month_year,
       COUNT(*) AS records
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year NULLS FIRST;
```

| month\_year | records |
| :--- | :--- |
| 2018-07-01 | 729 |
| 2018-08-01 | 767 |
| 2018-09-01 | 780 |
| 2018-10-01 | 857 |
| 2018-11-01 | 928 |
| 2018-12-01 | 995 |
| 2019-01-01 | 973 |
| 2019-02-01 | 1121 |
| 2019-03-01 | 1136 |
| 2019-04-01 | 1099 |
| 2019-05-01 | 857 |
| 2019-06-01 | 824 |
| 2019-07-01 | 864 |
| 2019-08-01 | 1149 |


<a id="a3"></a>
#### A3: What do you think we should do with these null values in the `interest_metrics`?


```sql
DELETE
FROM interest_metrics
WHERE month_year IS NULL;
```


<a id="a4"></a>
#### A4: How many `interest_id` values exist in the `interest_metrics` table but not in the `interest_map` table? What about the other way around?

> 💬 **Note**
> - *‌Converted `interest_id` to `INTEGER` to simplify future joins with `interest_map.id`; not required by the case, but verified to be safe for all questions.*

```sql
ALTER TABLE interest_metrics
    ALTER COLUMN interest_id TYPE integer
        USING interest_id::int;

SELECT COUNT(DISTINCT me.interest_id) AS misssing_in_map
FROM interest_metrics me
         LEFT JOIN interest_map ma ON me.interest_id = ma.id
WHERE ma.id IS NULL;

SELECT COUNT(DISTINCT ma.id) AS misssing_in_metrics
FROM interest_map ma
         LEFT JOIN interest_metrics me ON me.interest_id = ma.id
WHERE me.interest_id IS NULL;
```

| misssing\_in\_map |
| :--- |
| 0 |

| misssing\_in\_metrics |
| :--- |
| 7 |


<a id="a5"></a>
#### A5: Summarise the `id` values in the `interest_map` by its total record count in this table.

```sql
SELECT COUNT(id) AS total_ids
FROM interest_map;
```

| total\_ids |
| :--- |
| 1209 |

<a id="a6"></a>
#### A6: What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where ` interest_id = 21246` in your joined output and include all columns from `interest_metrics` and all columns from `interest_map` except from the `id` column.

> 💬 **Note**
> - *Use `INNER JOIN` to keep only metrics with a valid interest in `interest_map`, ensuring a consistent analysis dataset and excluding orphan IDs.*

```sql
SELECT me.*,
       ma.interest_name,
       ma.interest_summary,
       ma.created_at,
       ma.last_modified
FROM interest_metrics me
         INNER JOIN interest_map ma ON ma.id = me.interest_id
WHERE me.interest_id = 21246;
```

| \_month | \_year | month\_year | interest\_id | composition | index\_value | ranking | percentile\_ranking | interest\_name | interest\_summary | created\_at | last\_modified |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 7 | 2018 | 2018-07-01 | 21246 | 2.26 | 0.65 | 722 | 0.96 | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.000000 | 2018-06-11 17:50:04.000000 |
| 8 | 2018 | 2018-08-01 | 21246 | 2.13 | 0.59 | 765 | 0.26 | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.000000 | 2018-06-11 17:50:04.000000 |
| 9 | 2018 | 2018-09-01 | 21246 | 2.06 | 0.61 | 774 | 0.77 | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.000000 | 2018-06-11 17:50:04.000000 |
| 10 | 2018 | 2018-10-01 | 21246 | 1.74 | 0.58 | 855 | 0.23 | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.000000 | 2018-06-11 17:50:04.000000 |
| 11 | 2018 | 2018-11-01 | 21246 | 2.25 | 0.78 | 908 | 2.16 | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.000000 | 2018-06-11 17:50:04.000000 |
| 12 | 2018 | 2018-12-01 | 21246 | 1.97 | 0.7 | 983 | 1.21 | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.000000 | 2018-06-11 17:50:04.000000 |
| 1 | 2019 | 2019-01-01 | 21246 | 2.05 | 0.76 | 954 | 1.95 | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.000000 | 2018-06-11 17:50:04.000000 |
| 2 | 2019 | 2019-02-01 | 21246 | 1.84 | 0.68 | 1109 | 1.07 | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.000000 | 2018-06-11 17:50:04.000000 |
| 3 | 2019 | 2019-03-01 | 21246 | 1.75 | 0.67 | 1123 | 1.14 | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.000000 | 2018-06-11 17:50:04.000000 |
| 4 | 2019 | 2019-04-01 | 21246 | 1.58 | 0.63 | 1092 | 0.64 | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.000000 | 2018-06-11 17:50:04.000000 |


<a id="a7"></a>
#### A7: Are there any records in your joined table where the `month_year` value is before the `created_at` value from the `interest_map` table? Do you think these values are valid and why?

> 💬 **Note**
> - *`month_year` stores the month bucket (first day of month), so it can precede `created_at` without being invalid.‌* 

```sql
SELECT COUNT(me.interest_id) AS rows_before_created_at
FROM interest_metrics me
         JOIN interest_map ma ON ma.id = me.interest_id
WHERE me.month_year < ma.created_at;
```

| rows\_before\_created\_at |
| :--- |
| 188 |

---
### Section B: Interest Analysis
<a id="b1"></a>
#### B1: Which interests have been present in all `month_year` dates in our dataset?


```sql
WITH total_months AS (SELECT COUNT(DISTINCT month_year) AS n_total_months
                      FROM interest_metrics)
SELECT ma.interest_name,
       ma.id,
       COUNT(DISTINCT me.month_year)
FROM interest_metrics me
         JOIN interest_map ma ON ma.id = me.interest_id
GROUP BY ma.interest_name, ma.id
HAVING COUNT(DISTINCT me.month_year) = (SELECT n_total_months FROM total_months);
```

| interest\_name | id | count |
| :--- | :--- | :--- |
| Accounting & CPA Continuing Education Researchers | 6183 | 14 |
| Affordable Hotel Bookers | 18347 | 14 |
| Aftermarket Accessories Shoppers | 129 | 14 |
| Alabama Trip Planners | 7541 | 14 |
| Alaskan Cruise Planners | 10284 | 14 |
| … | … | … |
| Zoo Visitors | 22091 | 14 |



<a id="b2"></a>
#### B2: Using this same `total_months` measure - calculate the cumulative percentage of all records starting at 14 months - which `total_months` value passes the 90% cumulative percentage value?


```sql
WITH total_months_distribution AS (SELECT DISTINCT interest_id,
                                                   COUNT(month_year) AS total_months
                                   FROM interest_metrics
                                   WHERE interest_id IS NOT NULL
                                   GROUP BY interest_id),

     cumulative_distribution AS (SELECT total_months,
                                        COUNT(DISTINCT interest_id)                    AS qty_interests,
                                        SUM(COUNT(DISTINCT interest_id)) OVER (ORDER BY total_months DESC)::numeric /
                                        SUM(COUNT(DISTINCT interest_id)) OVER () * 100 AS cumulative_percentage
                                 FROM total_months_distribution
                                 GROUP BY total_months)

SELECT total_months, qty_interests, ROUND(cumulative_percentage, 2) AS cumulative_percentage
FROM cumulative_distribution
WHERE cumulative_percentage >= 90
ORDER BY cumulative_percentage DESC;
```

| total\_months | qty\_interests | cumulative\_percentage |
| :--- | :--- | :--- |
| 1 | 13 | 100 |
| 2 | 12 | 98.92 |
| 3 | 15 | 97.92 |
| 4 | 32 | 96.67 |
| 5 | 38 | 94.01 |
| 6 | 33 | 90.85 |


<a id="b3"></a>
#### B3: If we were to remove all `interest_id` values which are lower than the `total_months` value we found in the previous question - how many total data points would we be removing?


```sql
WITH total_months_distribution AS (SELECT DISTINCT interest_id,
                                                   COUNT(month_year) AS total_months
                                   FROM interest_metrics
                                   WHERE interest_id IS NOT NULL
                                   GROUP BY interest_id),

     cumulative_distribution AS (SELECT total_months,
                                        COUNT(DISTINCT interest_id)                    AS qty_interests,
                                        SUM(COUNT(DISTINCT interest_id)) OVER (ORDER BY total_months DESC)::numeric /
                                        SUM(COUNT(DISTINCT interest_id)) OVER () * 100 AS cumulative_percentage
                                 FROM total_months_distribution
                                 GROUP BY total_months),

     interests_to_remove AS (SELECT total_months,
                                    qty_interests,
                                    ROUND(cumulative_percentage, 2) AS cumulative_percentage
                             FROM cumulative_distribution
                             WHERE cumulative_percentage >= 90)

SELECT SUM(qty_interests) AS interests_removed
FROM interests_to_remove;
```

| interests\_removed |
| :--- |
| 143 |


<a id="b4"></a>
#### B4: Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed `interest` example for your arguments - think about what it means to have less months present from a segment perspective.

> *No, removing interests with < 6 months doesn't make business sense because it eliminates valuable seasonal and emerging segments that may have higher conversion rates during specific periods. For example, while "Fitness Enthusiasts" (14 months) provides stable year-round targeting, removing "Black Friday Electronics Shoppers" (3 months) would mean losing a high-value seasonal segment that drives significant revenue during Q4 despite its shorter presence.*

<a id="b5"></a>
#### B5: After removing these interests - how many unique interests are there for each month?


```sql
WITH total_months_distribution AS (SELECT DISTINCT interest_id,
                                                   COUNT(DISTINCT month_year) AS total_months
                                   FROM interest_metrics
                                   WHERE interest_id IS NOT NULL
                                   GROUP BY interest_id),

     interests_to_keep AS (SELECT interest_id
                           FROM total_months_distribution
                           WHERE total_months >= 6)

SELECT month_year,
       COUNT(DISTINCT me.interest_id) AS unique_interests_count
FROM interest_metrics me
         INNER JOIN interests_to_keep itk ON me.interest_id = itk.interest_id
GROUP BY month_year
ORDER BY month_year;
```

| month\_year | unique\_interests\_count |
| :--- | :--- |
| 2018-07-01 | 709 |
| 2018-08-01 | 752 |
| 2018-09-01 | 774 |
| 2018-10-01 | 853 |
| 2018-11-01 | 925 |
| 2018-12-01 | 986 |
| 2019-01-01 | 966 |
| 2019-02-01 | 1072 |
| 2019-03-01 | 1078 |
| 2019-04-01 | 1035 |
| 2019-05-01 | 827 |
| 2019-06-01 | 804 |
| 2019-07-01 | 836 |
| 2019-08-01 | 1062 |


---
### Section C: Segment Analysis
<a id="c1"></a>
#### C1: Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any `month_year`? Only use the maximum composition value for each interest but you must keep the corresponding `month_year`.

```sql
WITH total_months_per_interest AS (SELECT interest_id,
                                          COUNT(DISTINCT month_year) AS total_months
                                   FROM interest_metrics
                                   WHERE interest_id IS NOT NULL
                                   GROUP BY interest_id),

     interests_to_keep AS (SELECT interest_id
                           FROM total_months_per_interest
                           WHERE total_months >= 6),

     one_row_per_interest AS (SELECT interest_id,
                                     composition,
                                     month_year
                              FROM (SELECT m.interest_id,
                                           m.composition,
                                           m.month_year,
                                           ROW_NUMBER()
                                           OVER (PARTITION BY m.interest_id ORDER BY m.composition DESC, m.month_year) AS rn
                                    FROM interest_metrics m
                                             JOIN interests_to_keep k ON k.interest_id = m.interest_id) s
                              WHERE rn = 1),
     ranked AS (SELECT interest_id,
                       composition,
                       month_year,
                       DENSE_RANK() OVER (ORDER BY composition DESC) AS top_rank,
                       DENSE_RANK() OVER (ORDER BY composition)  AS bottom_rank
                FROM one_row_per_interest)

SELECT 'TOP 10' AS segment,
       interest_id,
       composition,
       month_year,
       top_rank AS rank
FROM ranked
WHERE top_rank <= 10

UNION ALL

SELECT 'BOTTOM 10' AS segment,
       interest_id,
       composition,
       month_year,
       bottom_rank AS rank
FROM ranked
WHERE bottom_rank <= 10

ORDER BY segment DESC, rank, composition, month_year, interest_id;
```

| segment | interest\_id | composition | month\_year | rank |
| :--- | :--- | :--- | :--- | :--- |
| TOP 10 | 21057 | 21.2 | 2018-12-01 | 1 |
| TOP 10 | 6284 | 18.82 | 2018-07-01 | 2 |
| TOP 10 | 39 | 17.44 | 2018-07-01 | 3 |
| TOP 10 | 77 | 17.19 | 2018-07-01 | 4 |
| TOP 10 | 12133 | 15.15 | 2018-10-01 | 5 |
| TOP 10 | 5969 | 15.05 | 2018-12-01 | 6 |
| TOP 10 | 171 | 14.91 | 2018-07-01 | 7 |
| TOP 10 | 4898 | 14.23 | 2018-07-01 | 8 |
| TOP 10 | 6286 | 14.1 | 2018-07-01 | 9 |
| TOP 10 | 4 | 13.97 | 2018-07-01 | 10 |
| BOTTOM 10 | 33958 | 1.88 | 2018-08-01 | 1 |
| BOTTOM 10 | 37412 | 1.94 | 2018-10-01 | 2 |
| BOTTOM 10 | 19599 | 1.97 | 2019-03-01 | 3 |
| BOTTOM 10 | 19635 | 2.05 | 2018-07-01 | 4 |
| BOTTOM 10 | 19591 | 2.08 | 2018-10-01 | 5 |
| BOTTOM 10 | 42011 | 2.09 | 2019-01-01 | 6 |
| BOTTOM 10 | 37421 | 2.09 | 2019-08-01 | 6 |
| BOTTOM 10 | 22408 | 2.12 | 2018-07-01 | 7 |
| BOTTOM 10 | 34085 | 2.14 | 2019-08-01 | 8 |
| BOTTOM 10 | 58 | 2.18 | 2018-07-01 | 9 |
| BOTTOM 10 | 36138 | 2.18 | 2019-02-01 | 9 |
| BOTTOM 10 | 20752 | 2.22 | 2018-07-01 | 10 |
| BOTTOM 10 | 19632 | 2.22 | 2019-08-01 | 10 |

<a id="c2"></a>
#### C2: Which 5 interests had the lowest average `ranking` value?


```sql
WITH per_interest AS (SELECT m.interest_id,
                             AVG(m.ranking::numeric)      AS avg_ranking,
                             COUNT(DISTINCT m.month_year) AS months
                      FROM interest_metrics m
                      GROUP BY m.interest_id
                      HAVING COUNT(DISTINCT m.month_year) >= 6),

     ranked AS (SELECT p.interest_id,
                       p.avg_ranking,
                       DENSE_RANK() OVER (ORDER BY p.avg_ranking) AS rank
                FROM per_interest p)

SELECT r.interest_id,
       ma.interest_name,
       ROUND(r.avg_ranking, 2) AS avg_ranking
FROM ranked r
         LEFT JOIN interest_map ma
                   ON ma.id = r.interest_id
WHERE r.rank <= 5
ORDER BY r.avg_ranking, r.interest_id;
```

| interest\_id | interest\_name | avg\_ranking |
| :--- | :--- | :--- |
| 41548 | Winter Apparel Shoppers | 1 |
| 42203 | Fitness Activity Tracker Users | 4.11 |
| 115 | Mens Shoe Shoppers | 5.93 |
| 171 | Shoe Shoppers | 9.36 |
| 4 | Luxury Retail Researchers | 11.86 |
| 6206 | Preppy Clothing Shoppers | 11.86 |


<a id="c3"></a>
#### C3: Which 5 interests had the largest standard deviation in their `percentile_ranking` value?


```sql
WITH per_interest AS (SELECT m.interest_id,
                             stddev_samp(m.percentile_ranking::numeric) AS std_percentile_ranking
                      FROM interest_metrics m
                      GROUP BY m.interest_id
                      HAVING COUNT(DISTINCT m.month_year) >= 6),
     ranked AS (SELECT interest_id,
                       std_percentile_ranking,
                       DENSE_RANK() OVER (ORDER BY std_percentile_ranking DESC) AS rank
                FROM per_interest)
SELECT r.interest_id,
       ma.interest_name,
       ROUND(r.std_percentile_ranking, 2) AS std_percentile_ranking
FROM ranked r
         LEFT JOIN interest_map ma
                   ON ma.id = r.interest_id
WHERE r.rank <= 5
ORDER BY r.std_percentile_ranking DESC, r.interest_id;
```

| interest\_id | interest\_name | std\_percentile\_ranking |
| :--- | :--- | :--- |
| 23 | Techies | 30.18 |
| 20764 | Entertainment Industry Decision Makers | 28.97 |
| 38992 | Oregon Trip Planners | 28.32 |
| 43546 | Personalized Gift Shoppers | 26.24 |
| 10839 | Tampa and St Petersburg Trip Planners | 25.61 |


<a id="c4"></a>
#### C4: For the 5 interests found in the previous question - what was minimum and maximum `percentile_ranking` values for each interest and its corresponding `year_month` value? Can you describe what is happening for these 5 interests?

```sql
WITH per_interest AS (SELECT m.interest_id,
                             stddev_samp(m.percentile_ranking::numeric) AS sd
                      FROM interest_metrics m
                      GROUP BY m.interest_id
                      HAVING COUNT(DISTINCT m.month_year) >= 6),
     top5 AS (SELECT interest_id
              FROM (SELECT interest_id,
                           sd,
                           DENSE_RANK() OVER (ORDER BY sd DESC) AS rank
                    FROM per_interest) s
              WHERE rank <= 5),
     min_rows AS (SELECT interest_id, percentile_ranking AS min_percentile, month_year AS min_month
                  FROM (SELECT m.*,
                               ROW_NUMBER() OVER (
                                   PARTITION BY m.interest_id
                                   ORDER BY m.percentile_ranking, m.month_year
                                   ) AS rn
                        FROM interest_metrics m
                                 JOIN top5 t ON t.interest_id = m.interest_id) x
                  WHERE rn = 1),
     max_rows AS (SELECT interest_id, percentile_ranking AS max_percentile, month_year AS max_month
                  FROM (SELECT m.*,
                               ROW_NUMBER() OVER (
                                   PARTITION BY m.interest_id
                                   ORDER BY m.percentile_ranking DESC, m.month_year
                                   ) AS rn
                        FROM interest_metrics m
                                 JOIN top5 t ON t.interest_id = m.interest_id) x
                  WHERE rn = 1)
SELECT t.interest_id,
       ma.interest_name,
       ROUND(min_rows.min_percentile::numeric, 2) AS min_percentile_ranking,
       TO_CHAR(min_rows.min_month, 'YYYY-MM')     AS min_year_month,
       ROUND(max_rows.max_percentile::numeric, 2) AS max_percentile_ranking,
       TO_CHAR(max_rows.max_month, 'YYYY-MM')     AS max_year_month
FROM top5 t
         JOIN min_rows ON min_rows.interest_id = t.interest_id
         JOIN max_rows ON max_rows.interest_id = t.interest_id
         LEFT JOIN interest_map ma ON ma.id::int = t.interest_id
ORDER BY t.interest_id;
```

| interest\_id | interest\_name | min\_percentile\_ranking | min\_year\_month | max\_percentile\_ranking | max\_year\_month |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 23 | Techies | 7.92 | 2019-08 | 86.69 | 2018-07 |
| 10839 | Tampa and St Petersburg Trip Planners | 4.84 | 2019-03 | 75.03 | 2018-07 |
| 20764 | Entertainment Industry Decision Makers | 11.23 | 2019-08 | 86.15 | 2018-07 |
| 38992 | Oregon Trip Planners | 2.2 | 2019-07 | 82.44 | 2018-11 |
| 43546 | Personalized Gift Shoppers | 5.7 | 2019-06 | 73.15 | 2019-03 |


<a id="c5"></a>
#### C5: How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?


> *Considering only interests with ≥ 6 months of data, lower average ranking means stronger fit and higher composition means larger share. Customers with high composition and low ranking are your core: serve flagship and premium bundles with deeper content, and avoid generic cross-sell. Low composition but low ranking indicates promising niches: run curated trials and discovery content, but hold back big budgets until traction is proven. High composition with high ranking is broad yet undifferentiated demand: lead with competitive pricing, convenience, and starter kits, and skip costly personalization or niche features. Low composition with high ranking signals poor fit: restrict to cheap, broad awareness touches and avoid premium placements.*

---
### Section D: Index Analysis
**The `index_value` is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.**

**Average composition can be calculated by dividing the `composition` column by the `index_value` column rounded to 2 decimal places.**

<a id="d1"></a>
#### D1: What is the top 10 interests by the average composition for each month?


```sql
WITH avg_composition_rank AS (SELECT me.interest_id,
                                     ma.interest_name,
                                     me.month_year,
                                     ROUND(me.composition::numeric / me.index_value::numeric,
                                           2)                                                                        AS avg_composition,
                                     DENSE_RANK()
                                     OVER (PARTITION BY me.month_year ORDER BY me.composition / me.index_value DESC) AS rank
                              FROM interest_metrics me
                                       JOIN interest_map ma
                                            ON me.interest_id = ma.id
                              WHERE me.month_year IS NOT NULL)
SELECT *
FROM avg_composition_rank
WHERE rank <= 10;
```

| interest\_id | interest\_name | month\_year | avg\_composition | rank |
| :--- | :--- | :--- | :--- | :--- |
| 6324 | Las Vegas Trip Planners | 2018-07-01 | 7.36 | 1 |
| 6284 | Gym Equipment Owners | 2018-07-01 | 6.94 | 2 |
| 4898 | Cosmetics and Beauty Shoppers | 2018-07-01 | 6.78 | 3 |
| 77 | Luxury Retail Shoppers | 2018-07-01 | 6.61 | 4 |
| 39 | Furniture Shoppers | 2018-07-01 | 6.51 | 5 |
| 18619 | Asian Food Enthusiasts | 2018-07-01 | 6.1 | 6 |
| 6208 | Recently Retired Individuals | 2018-07-01 | 5.72 | 7 |
| 21060 | Family Adventures Travelers | 2018-07-01 | 4.85 | 8 |
| 21057 | Work Comes First Travelers | 2018-07-01 | 4.8 | 9 |
| 82 | HDTV Researchers | 2018-07-01 | 4.71 | 10 |
| 6324 | Las Vegas Trip Planners | 2018-08-01 | 7.21 | 1 |
| 6284 | Gym Equipment Owners | 2018-08-01 | 6.62 | 2 |
| … | … | … | … | … | 
| 6208 | Recently Retired Individuals | 2019-08-01 | 2.53 | 10 |


<a id="d2"></a>
#### D2: For all of these top 10 interests - which interest appears the most often?


```sql
WITH avg_composition_rank AS (SELECT me.interest_id,
                                     ma.interest_name,
                                     me.month_year,
                                     ROUND(me.composition::numeric / me.index_value::numeric, 2)                     AS avg_composition,
                                     DENSE_RANK()
                                     OVER (PARTITION BY me.month_year ORDER BY me.composition / me.index_value DESC) AS rank
                              FROM interest_metrics me
                                       JOIN interest_map ma
                                            ON me.interest_id = ma.id
                              WHERE me.month_year IS NOT NULL),
     frequent_interests AS (SELECT interest_id,
                                   interest_name,
                                   COUNT(*) AS freq
                            FROM avg_composition_rank
                            WHERE rank <= 10
                            GROUP BY interest_id, interest_name)

SELECT *
FROM frequent_interests
WHERE freq IN (SELECT MAX(freq) FROM frequent_interests);
```

| interest\_id | interest\_name | freq |
| :--- | :--- | :--- |
| 6065 | Solar Energy Researchers | 10 |
| 7541 | Alabama Trip Planners | 10 |
| 5969 | Luxury Bedding Shoppers | 10 |


<a id="d3"></a>
#### D3: What is the average of the average composition for the top 10 interests for each month?


```sql
WITH avg_composition_rank AS (SELECT me.interest_id,
                                     ma.interest_name,
                                     me.month_year,
                                     ROUND(me.composition::numeric / me.index_value::numeric, 2)                     AS avg_composition,
                                     DENSE_RANK()
                                     OVER (PARTITION BY me.month_year ORDER BY me.composition / me.index_value DESC) AS rank
                              FROM interest_metrics me
                                       JOIN interest_map ma
                                            ON me.interest_id = ma.id
                              WHERE me.month_year IS NOT NULL)

SELECT month_year,
       ROUND(AVG(avg_composition),2) AS avg_of_avg_composition
FROM avg_composition_rank
WHERE rank <= 10
GROUP BY month_year;
```

| month\_year | avg\_of\_avg\_composition |
| :--- | :--- |
| 2018-07-01 | 6.038 |
| 2018-08-01 | 5.945 |
| 2018-09-01 | 6.895 |
| 2018-10-01 | 7.066 |
| 2018-11-01 | 6.623 |
| 2018-12-01 | 6.652 |
| 2019-01-01 | 6.399 |
| 2019-02-01 | 6.579 |
| 2019-03-01 | 6.168 |
| 2019-04-01 | 5.75 |
| 2019-05-01 | 3.537 |
| 2019-06-01 | 2.427 |
| 2019-07-01 | 2.765 |
| 2019-08-01 | 2.631 |


<a id="d4"></a>
#### D4: What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
**Required output for question 4:**
| month_year | interest_name                | max_index_composition | 3_month_moving_avg | 1_month_ago                        | 2_months_ago                      |
|------------|------------------------------|-----------------------|--------------------|------------------------------------|-----------------------------------|
| 2018-09-01 | Work Comes First Travelers   | 8.26                  | 7.61               | Las Vegas Trip Planners: 7.21      | Las Vegas Trip Planners: 7.36     |
| 2018-10-01 | Work Comes First Travelers   | 9.14                  | 8.20               | Work Comes First Travelers: 8.26   | Las Vegas Trip Planners: 7.21     |
| 2018-11-01 | Work Comes First Travelers   | 8.28                  | 8.56               | Work Comes First Travelers: 9.14   | Work Comes First Travelers: 8.26  |
| 2018-12-01 | Work Comes First Travelers   | 8.31                  | 8.58               | Work Comes First Travelers: 8.28   | Work Comes First Travelers: 9.14  |
| 2019-01-01 | Work Comes First Travelers   | 7.66                  | 8.08               | Work Comes First Travelers: 8.31   | Work Comes First Travelers: 8.28  |
| 2019-02-01 | Work Comes First Travelers   | 7.66                  | 7.88               | Work Comes First Travelers: 7.66   | Work Comes First Travelers: 8.31  |
| 2019-03-01 | Alabama Trip Planners        | 6.54                  | 7.29               | Work Comes First Travelers: 7.66   | Work Comes First Travelers: 7.66  |
| 2019-04-01 | Solar Energy Researchers     | 6.28                  | 6.83               | Alabama Trip Planners: 6.54        | Work Comes First Travelers: 7.66  |
| 2019-05-01 | Readers of Honduran Content  | 4.41                  | 5.74               | Solar Energy Researchers: 6.28     | Alabama Trip Planners: 6.54       |
| 2019-06-01 | Las Vegas Trip Planners      | 2.77                  | 4.49               | Readers of Honduran Content: 4.41  | Solar Energy Researchers: 6.28    |
| 2019-07-01 | Las Vegas Trip Planners      | 2.82                  | 3.33               | Las Vegas Trip Planners: 2.77      | Readers of Honduran Content: 4.41 |
| 2019-08-01 | Cosmetics and Beauty Shoppers| 2.73                  | 2.77               | Las Vegas Trip Planners: 2.82      | Las Vegas Trip Planners: 2.77     |


```sql
WITH avg_compositions AS (SELECT month_year,
                                 interest_id,
                                 ROUND(composition::numeric / index_value::numeric, 2) AS avg_comp,
                                 ROUND(MAX(composition::numeric / index_value::numeric) OVER (PARTITION BY month_year),
                                       2)                                              AS max_avg_comp
                          FROM interest_metrics
                          WHERE month_year IS NOT NULL),

     max_avg_compositions AS (SELECT *
                              FROM avg_compositions
                              WHERE avg_comp = max_avg_comp),

     moving_avg_compositions AS (SELECT mac.month_year,
                                        ma.interest_name,
                                        mac.max_avg_comp                                                            AS max_index_composition,
                                        ROUND(AVG(mac.max_avg_comp)
                                              OVER (ORDER BY mac.month_year
                                                  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
                                              2)                                                                    AS three_month_moving_avg,
                                        LAG(ma.interest_name) OVER (ORDER BY mac.month_year) || ': ' ||
                                        CAST(LAG(mac.max_avg_comp) OVER (ORDER BY mac.month_year) AS VARCHAR(4))    AS one_month_ago,
                                        LAG(ma.interest_name, 2) OVER (ORDER BY mac.month_year) || ': ' ||
                                        CAST(LAG(mac.max_avg_comp, 2) OVER (ORDER BY mac.month_year) AS VARCHAR(4)) AS two_month_ago
                                 FROM max_avg_compositions mac
                                          JOIN interest_map ma
                                               ON mac.interest_id = ma.id)

SELECT *
FROM moving_avg_compositions
WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01';
```


<a id="d5"></a>
#### D5: Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?

> *The max average composition can change month to month because it is a relative ratio (`composition` ÷ `index_value`) and the leading interest rotates with seasonality and acquisition mix. This alone doesn’t imply a flawed business model; however, abrupt step-changes or frequent leader churn can indicate data or method issues (e.g., changes to index normalization, taxonomy, sampling size, or tracking coverage) rather than true demand shifts, and warrant a pipeline audit.*

***Thanks for reading this far!*** *If you found it useful, consider giving it a* ⭐️. 

---

© ***Pedro Palmier** – São Paulo, September 2025.*
