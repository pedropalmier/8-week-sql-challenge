# 🛒 Case Study #5 – Data Mart
<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/hero_images/hero_data_mart.png" width=60% height=60%>


## 💎 Business Context 
Danny launched Data Mart, an online supermarket specializing in fresh produce, and introduced sustainable packaging across the supply chain in June 2020. See the original case study [here](https://8weeksqlchallenge.com/case-study-5/).

## ⚡️Problem Statement
Danny needs help to measure the sales impact of the sustainability changes and identify the most affected platforms, regions, segments, and customer types. He and the Data Mart team prepared only one table. See the original schema [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/c0aa498043bdfefe8207e5d8771ed2fdd1388aa9/case05_data_mart/schema.sql).

<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/ERDs/ERD_data_mart_preview.png" width=80% height=80% >



## ❓Case Study Questions
### Section A: Data Cleansing Steps
1. [In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales (…)](#a1)

### Section B: Data Exploration
1. [What day of the week is used for each `week_date` value?](#b1)
2. [What range of week numbers are missing from the dataset?](#b2)
3. [How many total transactions were there for each year in the dataset?](#b3)
4. [What is the total sales for each region for each month?](#b4)
5. [What is the total count of transactions for each platform](#b5)
6. [What is the percentage of sales for Retail vs Shopify for each month?](#b6)
7. [What is the percentage of sales by demographic for each year in the dataset?](#b7)
8. [Which `age_band` and `demographic` values contribute the most to Retail sales?](#b8)
9. [Can we use the `avg_transaction` column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?](#b9)

### Section C: Before & After Analysis
1. [What is the total sales for the 4 weeks before and after `2020-06-15`? What is the growth or reduction rate in actual values and percentage of sales?](#c1)
2. [What about the entire 12 weeks before and after?](#c2)
3. [How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?](#c3)


## 🎯 My Solution
*View the complete syntax [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/c0aa498043bdfefe8207e5d8771ed2fdd1388aa9/case05_data_mart/solution.sql).*

### Section A: Data Cleansing Steps

<a id="a1"></a>
#### A1: In a single query, perform the following operations and generate a new table in the `data_mart` schema named `clean_weekly_sales`:

- **Convert the `week_date` to a `DATE` format**
- **Add a `week_number` as the second column for each `week_date` value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc**
- **Add a `month_number` with the calendar month for each `week_date` value as the 3rd column**
- **Add a `calendar_year` column as the 4th column containing either 2018, 2019 or 2020 values**
- **Add a new column called `age_band` after the original `segment` column using the following mapping on the number inside the `segment` value:**

| segment | age_band     |
|---------|--------------|
| 1       | Young Adults |
| 2       | Middle Aged  |
| 3 or 4  | Retirees     |

- **Add a new `demographic` column using the following mapping for the first letter in the `segment` values:**

| segment | demographic |
|---------|-------------|
| C       | Couples     |
| F       | Families    |

- **Ensure all `null` string values with an `"unknown"` string value in the original `segment` column as well as the new `age_band` and `demographic` columns**
- **Generate a new `avg_transaction` column as the `sales` value divided by `transactions` rounded to 2 decimal places for each record**

```sql
DROP TABLE IF EXISTS clean_weekly_sales CASCADE;
CREATE TABLE clean_weekly_sales AS
SELECT TO_DATE(week_date, 'DD/MM/YY')                               AS week_date,
       CEIL(EXTRACT(DAY FROM TO_DATE(week_date, 'DD/MM/YY')) / 7.0) AS week_number,
       EXTRACT(MONTH FROM TO_DATE(week_date, 'DD/MM/YY'))           AS month_number,
       EXTRACT(YEAR FROM TO_DATE(week_date, 'DD/MM/YY'))            AS calendar_year,
       region,
       platform,
       NULLIF(segment, 'null')                                      AS segment,
       CASE
           WHEN RIGHT(segment, 1) = '1' THEN 'Young Adults'
           WHEN RIGHT(segment, 1) = '2' THEN 'Middle Aged'
           WHEN RIGHT(segment, 1) IN ('3', '4') THEN 'Retirees'
           ELSE 'unknown'
           END                                                      AS age_band,
       CASE
           WHEN LEFT(segment, 1) = 'C' THEN 'Couples'
           WHEN LEFT(segment, 1) = 'F' THEN 'Families'
           ELSE 'unknown'
           END                                                      AS demographic,
       customer_type,
       transactions,
       sales,
       ROUND((sales::numeric / transactions), 2)                    AS avg_transaction
FROM weekly_sales;
```

| week\_date | week\_number | month\_number | calendar\_year | region | platform | segment | age\_band | demographic | customer\_type | transactions | sales | avg\_transaction |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 2020-08-31 | 5 | 8 | 2020 | ASIA | Retail | C3 | Retirees | Couples | New | 120631 | 3656163 | 30.31 |
| 2020-08-31 | 5 | 8 | 2020 | ASIA | Retail | F1 | Young Adults | Families | New | 31574 | 996575 | 31.56 |
| 2020-08-31 | 5 | 8 | 2020 | USA | Retail | null | unknown | unknown | Guest | 529151 | 16509610 | 31.2 |
| 2020-08-31 | 5 | 8 | 2020 | EUROPE | Retail | C1 | Young Adults | Couples | New | 4517 | 141942 | 31.42 |
| 2020-08-31 | 5 | 8 | 2020 | AFRICA | Retail | C2 | Middle Aged | Couples | New | 58046 | 1758388 | 30.29 |
| … | … | … | … | … | … | … | … | … | … | … | … | … |

---
### Section B: Data Exploration
<a id="b1"></a>
#### B1: What day of the week is used for each week_date value?

```sql
SELECT DISTINCT TRIM(TO_CHAR(week_date, 'day')) AS day_of_week
FROM clean_weekly_sales;
```

| day\_of\_week |
| :--- |
| monday |


<a id="b2"></a>
#### B2: What range of week numbers are missing from the dataset?

> 💬 **Note**
> - *Used `53` as the upper bound in `generate_series` to account for the ISO week date system, where some years contain 53 weeks instead of the usual 52.*

```sql
WITH all_week_numbers AS (SELECT generate_series(1, 53) AS week_number)
SELECT DISTINCT a.week_number
FROM all_week_numbers a
         LEFT JOIN clean_weekly_sales c ON c.week_number = a.week_number
WHERE c.week_number IS NULL;
```

| week\_number |
| :--- |
| 6 |
| 7 |
| 8 |
| 9 |
| … |
| 49 |
| 50 |
| 51 |
| 52 |
| 53 |


<a id="b3"></a>
#### B3: How many total transactions were there for each year in the dataset?

```sql
SELECT calendar_year,
       SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year
```

| calendar\_year | total\_transactions |
| :--- | :--- |
| 2018 | 346406460 |
| 2019 | 365639285 |
| 2020 | 375813651 |


<a id="b4"></a>
#### B4: What is the total sales for each region for each month?

> 💬 **Note**
> - *The question is ambiguous about month aggregation, so `calendar_year` is included to ensure correct interpretation and totals.*

```sql
SELECT region,
       calendar_year,
       month_number,
       SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region, calendar_year, month_number
ORDER BY region, calendar_year, month_number;
```

| region | calendar\_year | month\_number | total\_sales |
| :--- | :--- | :--- | :--- |
| AFRICA | 2018 | 3 | 130542213 |
| AFRICA | 2018 | 4 | 650194751 |
|…|…|…|…|
| AFRICA | 2020 | 7 | 574216244 |
| AFRICA | 2020 | 8 | 706022238 |
| ASIA | 2018 | 3 | 119180883 |
| ASIA | 2018 | 4 | 603716301 |
|…|…|…|…|
| ASIA | 2020 | 7 | 530568085 |
| ASIA | 2020 | 8 | 662388351 |
| CANADA | 2018 | 3 | 33815571 |
| CANADA | 2018 | 4 | 163479820 |
|…|…|…|…|
| CANADA | 2020 | 7 | 138944935 |
| CANADA | 2020 | 8 | 174008340 |
| EUROPE | 2018 | 3 | 8402183 |
| EUROPE | 2018 | 4 | 44549418 |
|…|…|…|…|
| EUROPE | 2020 | 7 | 39067454 |
| EUROPE | 2020 | 8 | 46360191 |
| OCEANIA | 2018 | 3 | 175777460 |
|…|…|…|…|
| OCEANIA | 2020 | 7 | 757648850 |
| OCEANIA | 2020 | 8 | 958930687 |
| SOUTH AMERICA | 2018 | 3 | 16302144 |
| SOUTH AMERICA | 2018 | 4 | 80814046 |
|…|…|…|…|
| SOUTH AMERICA | 2020 | 7 | 69314667 |
| SOUTH AMERICA | 2020 | 8 | 86722019 |
| USA | 2018 | 3 | 52734998 |
| USA | 2018 | 4 | 260725717 |
|…|…|…|…|
| USA | 2020 | 7 | 223735311 |
| USA | 2020 | 8 | 277361606 |


<a id="b5"></a>
#### B5: What is the total count of transactions for each platform?

```sql
SELECT platform,
       SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY platform
ORDER BY SUM(transactions) DESC;
```

| platform | total\_transactions |
| :--- | :--- |
| Retail | 1081934227 |
| Shopify | 5925169 |


<a id="b6"></a>
#### B6: What is the percentage of sales for Retail vs Shopify for each month?

> 💬 **Note**
> - *The question is ambiguous about month aggregation, so `calendar_year` is included to ensure correct interpretation and totals.*

```sql
WITH total_sales AS (SELECT calendar_year,
                            month_number,
                            SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END)  as retail_sales,
                            SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END) as shopify_sales,
                            SUM(sales)                                                AS total_sales
                     FROM clean_weekly_sales
                     GROUP BY calendar_year, month_number)

SELECT calendar_year,
       month_number,
       ROUND(retail_sales * 100.00 / total_sales, 2)  AS retail_percentage,
       ROUND(shopify_sales * 100.00 / total_sales, 2) AS shopify_percentage
FROM total_sales
ORDER BY calendar_year, month_number;
```

| calendar\_year | month\_number | retail\_percentage | shopify\_percentage |
| :--- | :--- | :--- | :--- |
| 2018 | 3 | 97.92 | 2.08 |
| 2018 | 4 | 97.93 | 2.07 |
| 2018 | 5 | 97.73 | 2.27 |
| 2018 | 6 | 97.76 | 2.24 |
| 2018 | 7 | 97.75 | 2.25 |
| 2018 | 8 | 97.71 | 2.29 |
| 2018 | 9 | 97.68 | 2.32 |
| 2019 | 3 | 97.71 | 2.29 |
| 2019 | 4 | 97.8 | 2.2 |
| 2019 | 5 | 97.52 | 2.48 |
| 2019 | 6 | 97.42 | 2.58 |
| 2019 | 7 | 97.35 | 2.65 |
| 2019 | 8 | 97.21 | 2.79 |
| 2019 | 9 | 97.09 | 2.91 |
| 2020 | 3 | 97.3 | 2.7 |
| 2020 | 4 | 96.96 | 3.04 |
| 2020 | 5 | 96.71 | 3.29 |
| 2020 | 6 | 96.8 | 3.2 |
| 2020 | 7 | 96.67 | 3.33 |
| 2020 | 8 | 96.51 | 3.49 |

<a id="b7"></a>
#### B7: What is the percentage of sales by demographic for each year in the dataset?

```sql
WITH total_sales AS (SELECT calendar_year,
                            SUM(CASE WHEN demographic = 'Couples' THEN sales ELSE 0 END)  as couples_sales,
                            SUM(CASE WHEN demographic = 'Families' THEN sales ELSE 0 END) as families_sales,
                            SUM(CASE WHEN demographic = 'unknown' THEN sales ELSE 0 END)  as unknown_sales,
                            SUM(sales)                                                    AS total_sales
                     FROM clean_weekly_sales
                     GROUP BY calendar_year)

SELECT calendar_year,
       ROUND(couples_sales * 100.00 / total_sales, 2)  AS couples_percentage,
       ROUND(families_sales * 100.00 / total_sales, 2) AS families_percentage,
       ROUND(unknown_sales * 100.00 / total_sales, 2)  AS unknown_percentage
FROM total_sales
ORDER BY calendar_year;
```

| calendar\_year | couples\_percentage | families\_percentage | unknown\_percentage |
| :--- | :--- | :--- | :--- |
| 2018 | 26.38 | 31.99 | 41.63 |
| 2019 | 27.28 | 32.47 | 40.25 |
| 2020 | 28.72 | 32.73 | 38.55 |

<a id="b8"></a>
#### B8: Which `age_band` and `demographic` values contribute the most to Retail sales?

```sql
WITH values_contribution AS (SELECT age_band,
                                    demographic,
                                    SUM(sales)                             AS total_sales,
                                    RANK() OVER (ORDER BY SUM(sales) DESC) AS rank
                             FROM clean_weekly_sales
                             WHERE platform = 'Retail'
                             GROUP BY age_band, demographic)

SELECT age_band, demographic, total_sales
FROM values_contribution
WHERE rank = 1;
```

| age\_band | demographic | total\_sales |
| :--- | :--- | :--- |
| unknown | unknown | 16067285533 |


<a id="b9"></a>
#### B9: Can we use the `avg_transaction` column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

```sql
WITH total_transaction AS (SELECT calendar_year,
                                  platform,
                                  SUM(transactions) AS transactions,
                                  SUM(sales)        AS sales
                           FROM clean_weekly_sales
                           GROUP BY calendar_year, platform)

SELECT calendar_year,
       platform,
       ROUND((sales::numeric / transactions), 2) AS avg_sales
FROM total_transaction
ORDER BY calendar_year, platform;
```

| calendar\_year | platform | avg\_sales |
| :--- | :--- | :--- |
| 2018 | Retail | 36.56 |
| 2018 | Shopify | 192.48 |
| 2019 | Retail | 36.83 |
| 2019 | Shopify | 183.36 |
| 2020 | Retail | 36.56 |
| 2020 | Shopify | 179.03 |


### Section C: Before & After Analysis
<a id="c1"></a>
#### C1: What is the total sales for the 4 weeks before and after `2020-06-15`? What is the growth or reduction rate in actual values and percentage of sales?


```sql
WITH total_before_after AS (SELECT SUM(CASE
                                           WHEN week_date BETWEEN DATE '2020-06-15' - INTERVAL '28 days' AND DATE '2020-06-15' - INTERVAL '1 day'
                                               THEN sales END) AS total_before,
                                   SUM(CASE
                                           WHEN week_date BETWEEN DATE '2020-06-15' AND DATE '2020-06-15' + INTERVAL '27 days'
                                               THEN sales END) AS total_after
                            FROM clean_weekly_sales)

SELECT total_before,
       total_after,
       (total_after - total_before)                                    AS variance,
       ROUND(((total_after - total_before) * 100.0 / total_before), 2) AS percentage
FROM total_before_after;
```

| total\_before | total\_after | variance | percentage |
| :--- | :--- | :--- | :--- |
| 2345878357 | 2318994169 | -26884188 | -1.15 |


<a id="c2"></a>
#### C2: What about the entire 12 weeks before and after?


```sql
WITH total_before_after AS (SELECT SUM(CASE
                                           WHEN week_date BETWEEN DATE '2020-06-15' - INTERVAL '84 days' AND DATE '2020-06-15' - INTERVAL '1 day'
                                               THEN sales END) AS total_before,
                                   SUM(CASE
                                           WHEN week_date BETWEEN DATE '2020-06-15' AND DATE '2020-06-15' + INTERVAL '83 days'
                                               THEN sales END) AS total_after
                            FROM clean_weekly_sales)

SELECT total_before,
       total_after,
       (total_after - total_before)                                    AS variance,
       ROUND(((total_after - total_before) * 100.0 / total_before), 2) AS percentage
FROM total_before_after;
```

| total\_before | total\_after | variance | percentage |
| :--- | :--- | :--- | :--- |
| 7126273147 | 6973947753 | -152325394 | -2.14 |


<a id="c3"></a>
#### C3: How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

```sql
WITH total_before_after AS (SELECT calendar_year,
                                   week_number,
                                   SUM(CASE
                                           WHEN week_date BETWEEN (DATE(calendar_year || '-06-15') - INTERVAL '28 days')
                                               AND (DATE(calendar_year || '-06-15') - INTERVAL '1 day')
                                               THEN sales END) AS total_before,
                                   SUM(CASE
                                           WHEN week_date BETWEEN DATE(calendar_year || '-06-15')
                                               AND (DATE(calendar_year || '-06-15') + INTERVAL '27 days')
                                               THEN sales END) AS total_after
                            FROM clean_weekly_sales
                            GROUP BY calendar_year, week_number)


SELECT calendar_year,
       SUM(total_before)                                                                       AS total_before,
       SUM(total_after)                                                                        AS total_after,
       SUM(total_after) - SUM(total_before)                                                    AS variance,
       ROUND((SUM(total_after) - SUM(total_before)) * 100.0 / NULLIF(SUM(total_before), 0), 2) AS percentage
FROM total_before_after
GROUP BY calendar_year;
```

| calendar\_year | total\_before | total\_after | variance | percentage |
| :--- | :--- | :--- | :--- | :--- |
| 2018 | 2125140809 | 2129242914 | 4102105 | 0.19 |
| 2019 | 2249989796 | 2252326390 | 2336594 | 0.1 |
| 2020 | 2345878357 | 2318994169 | -26884188 | -1.15 |

```sql
WITH total_before_after AS (SELECT calendar_year,
                                   week_number,
                                   SUM(CASE
                                           WHEN week_date BETWEEN (DATE(calendar_year || '-06-15') - INTERVAL '84 days')
                                               AND (DATE(calendar_year || '-06-15') - INTERVAL '1 day')
                                               THEN sales END) AS total_before,
                                   SUM(CASE
                                           WHEN week_date BETWEEN DATE(calendar_year || '-06-15')
                                               AND (DATE(calendar_year || '-06-15') + INTERVAL '83 days')
                                               THEN sales END) AS total_after
                            FROM clean_weekly_sales
                            GROUP BY calendar_year, week_number)


SELECT calendar_year,
       SUM(total_before)                                                                       AS total_before,
       SUM(total_after)                                                                        AS total_after,
       SUM(total_after) - SUM(total_before)                                                    AS variance,
       ROUND((SUM(total_after) - SUM(total_before)) * 100.0 / NULLIF(SUM(total_before), 0), 2) AS percentage
FROM total_before_after
GROUP BY calendar_year;
```

| calendar\_year | total\_before | total\_after | variance | percentage |
| :--- | :--- | :--- | :--- | :--- |
| 2018 | 6396562317 | 6500818510 | 104256193 | 1.63 |
| 2019 | 6883386397 | 6862646103 | -20740294 | -0.3 |
| 2020 | 7126273147 | 6973947753 | -152325394 | -2.14 |

***Thanks for reading this far!*** *If you found it useful, consider giving it a* ⭐️. 

---

### 🏃🏻‍♂️‍➡️ Go to the next case!

<div align="center"><a href="https://github.com/pedropalmier/8-week-sql-challenge/tree/09278f36d9782d1ecf241e81053646813f591452/case06_clique_bait"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/hero_images/hero_clique_bait.png"  style="width:50%; height:50%;"></a></div>

---
© ***Pedro Palmier** – São Paulo, Winter 2025.*