/*
================================================================================
DATA MART - CASE STUDY #5
================================================================================
Author: Pedro Palmier
Purpose: Portfolio project demonstrating advanced SQL & analytical thinking
Dataset: Danny Ma's 8 Week SQL Challenge
================================================================================
*/

-- ============================================================================
-- SECTION A: Data Cleansing Steps
-- ============================================================================
/*
QUESTION A1: In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
- Convert the week_date to a DATE format
- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
- Add a month_number with the calendar month for each week_date value as the 3rd column
- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
- Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value:
    segment	age_band
    1	Young Adults
    2	Middle Aged
    3 or 4	Retirees
-Add a new demographic column using the following mapping for the first letter in the segment values:
    segment	demographic
    C	Couples
    F	Families
- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
OWNER: Pedro Palmier
CREATED: 2025-09-15
*/
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



-- ============================================================================
-- SECTION B: Data Cleansing Steps
-- ============================================================================

/*
QUESTION B1: What day of the week is used for each week_date value?
OWNER: Pedro Palmier
CREATED: 2025-09-15
*/
SELECT DISTINCT TRIM(TO_CHAR(week_date, 'day')) AS day_of_week
FROM clean_weekly_sales;


/*
QUESTION B2: What range of week numbers are missing from the dataset?
OWNER: Pedro Palmier
CREATED: 2025-09-15
*/
WITH all_week_numbers AS (SELECT generate_series(1, 53) AS week_number)
SELECT DISTINCT a.week_number
FROM all_week_numbers a
         LEFT JOIN clean_weekly_sales c ON c.week_number = a.week_number
WHERE c.week_number IS NULL;

/*
QUESTION B3: How many total transactions were there for each year in the dataset?
OWNER: Pedro Palmier
CREATED: 2025-09-15
*/
SELECT calendar_year,
       SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;

/*
QUESTION B4: What is the total sales for each region for each month?
NOTE: The question is ambiguous about month aggregation, so calendar_year is included to ensure correct interpretation and totals.
OWNER: Pedro Palmier
CREATED: 2025-09-15
*/
SELECT region,
       calendar_year,
       month_number,
       SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region, calendar_year, month_number
ORDER BY region, calendar_year, month_number;

/*
QUESTION B5: What is the total count of transactions for each platform?
OWNER: Pedro Palmier
CREATED: 2025-09-15
*/
SELECT platform,
       SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY platform
ORDER BY SUM(transactions) DESC;

/*
QUESTION B6: What is the percentage of sales for Retail vs Shopify for each month?
NOTE: The question is ambiguous about month aggregation, so calendar_year is included to ensure correct interpretation and totals.
OWNER: Pedro Palmier
CREATED: 2025-09-15
*/
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

/*
QUESTION B7: What is the percentage of sales by demographic for each year in the dataset?
OWNER: Pedro Palmier
CREATED: 2025-09-15
*/
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

/*
QUESTION B8: Which age_band and demographic values contribute the most to Retail sales?
OWNER: Pedro Palmier
CREATED: 2025-09-15
*/
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

/*
QUESTION B9: Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
OWNER: Pedro Palmier
CREATED: 2025-09-15
*/
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

-- ============================================================================
-- SECTION C: Before & After Analysis
-- ============================================================================

/*
QUESTION C1: What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
OWNER: Pedro Palmier
CREATED: 2025-09-15
*/

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


/*
QUESTION C2: What about the entire 12 weeks before and after?
OWNER: Pedro Palmier
CREATED: 2025-09-15
*/

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

/*
QUESTION C3: How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
OWNER: Pedro Palmier
CREATED: 2025-09-15
*/
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