# 🥑 Case Study #3 – Foodie Fi
<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/hero_images/hero_foodie_fi.png" width=60% height=60%>



## 💎 Business Context 
Danny launched Foodie-Fi in 2020 as a subscription streaming service focused exclusively on food content, offering monthly and annual plans for unlimited access. See the original case study [here](https://8weeksqlchallenge.com/case-study-3/).

## ⚡️Problem Statement
Danny needs help to analyze subscription data to generate insights that guide growth, investments, and feature development. This is the entity relationship diagram he shared. See the original schema [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/c0aa498043bdfefe8207e5d8771ed2fdd1388aa9/case03_foodie_fi/schema.sql).

<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/ERDs/ERD_foodie_fi_preview.png" width=80% height=80% >


## ❓Case Study Questions
### Section A: Customer Journey
1. [Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding (…)](#a1)

### Section B: Data Analysis Questions
1. [How many customers has Foodie-Fi ever had?](#b1)
2. [What is the monthly distribution of `trial` plan `start_date` values for our dataset - use the start of the month as the group by value?](#b2)
3. [What plan `start_date` values occur after the year 2020 for our dataset? Show the breakdown by count of events for each `plan_name`?](#b3)
4. [What is the customer count and percentage of customers who have churned rounded to 1 decimal place?](#b4)
5. [How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?](#b5)
6. [What is the number and percentage of customer plans after their initial free trial?](#b6)
7. [What is the customer count and percentage breakdown of all 5 `plan_name` values at `2020-12-31`?](#b7)
8. [How many customers have upgraded to an annual plan in 2020?](#b8)
9. [How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?](#b9)
10. [Can you further breakdown this average value into 30 day periods (i.e. `0-30 days`, `31-60 days` etc)](#b10)
11. [How many customers downgraded from a pro monthly to a basic monthly plan in 2020?](#b11)

### Section C: Challenge Payment Question
1. [The Foodie-Fi team wants you to create a new `payments` table for the year 2020 that includes amounts paid by each customer in the `subscriptions` table with the following requirements(…)](#c1)

### Section D: Outside The Box Questions
1. [How would you calculate the rate of growth for Foodie-Fi?](#d1)
2. [What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?](#d2)
3. [What are some key customer journeys or experiences that you would analyse further to improve customer retention?](#d3)
4. [If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?](#d4)
5. [What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?](#d5)



## 🎯 My Solution
*View the complete syntax [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/c0aa498043bdfefe8207e5d8771ed2fdd1388aa9/case03_foodie_fi/solution.sql).*

### Section A: Customer Journey

<a id="a1"></a>
#### A1. Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey. Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

> *Bringing the brief of each customer’s onboarding journey through the following table. Assumption: `acquisition_date` = first subscription date (trial start) and `activation_date` = first paid plan start date (plans 1–3).*


```sql
SELECT
    s.customer_id,
    MIN(s.start_date) AS acquisition_date,
    MIN(CASE WHEN s.plan_id BETWEEN 1 AND 3 THEN s.start_date END) AS activation_date,
    ARRAY_TO_STRING(ARRAY_AGG(p.plan_name ORDER BY s.start_date), ' → ') AS plan_journey,
    MAX(CASE WHEN s.plan_id = 4 THEN s.start_date END) AS churn_date
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
WHERE s.customer_id IN (1, 2, 11, 13, 15, 16, 18, 19)
GROUP BY s.customer_id
ORDER BY s.customer_id;
```

| customer\_id | acquisition\_date | activation\_date | plan\_journey | churn\_date |
| :--- | :--- | :--- | :--- | :--- |
| 1 | 2020-08-01 | 2020-08-08 | trial → basic monthly | null |
| 2 | 2020-09-20 | 2020-09-27 | trial → pro annual | null |
| 11 | 2020-11-19 | null | trial → churn | 2020-11-26 |
| 13 | 2020-12-15 | 2020-12-22 | trial → basic monthly → pro monthly | null |
| 15 | 2020-03-17 | 2020-03-24 | trial → pro monthly → churn | 2020-04-29 |
| 16 | 2020-05-31 | 2020-06-07 | trial → basic monthly → pro annual | null |
| 18 | 2020-07-06 | 2020-07-13 | trial → pro monthly | null |
| 19 | 2020-06-22 | 2020-06-29 | trial → pro monthly → pro annual | null |



---
### Section B: Data Analysis Questions

<a id="b1"></a>
#### B1: How many customers has Foodie-Fi ever had?

```sql
SELECT COUNT(DISTINCT s.customer_id) AS total_customers
FROM subscriptions s;
```

| total\_customers |
| :--- |
| 1000 |


<a id="b2"></a>
#### B2: What is the monthly distribution of `trial` plan `start_date` values for our dataset - use the start of the month as the group by value


```sql
SELECT TRIM(TO_CHAR(DATE_TRUNC('month', s.start_date), 'YYYY Month')) AS month,
       SUM(CASE WHEN s.plan_id = 0 THEN 1 ELSE 0 END)                 AS trial_plans_starts
FROM subscriptions s
GROUP BY month
ORDER BY MIN(s.start_date);
```

| month | trial\_plans\_starts |
| :--- | :--- |
| 2020 January | 88 |
| 2020 February | 68 |
| 2020 March | 94 |
| 2020 April | 81 |
| 2020 May | 88 |
| 2020 June | 79 |
| 2020 July | 89 |
| 2020 August | 88 |
| 2020 September | 87 |
| 2020 October | 79 |
| 2020 November | 75 |
| 2020 December | 84 |
| 2021 January | 0 |
| 2021 February | 0 |
| 2021 March | 0 |
| 2021 April | 0 |


<a id="b3"></a>
#### B3: What plan `start_date` values occur after the year 2020 for our dataset? Show the breakdown by count of events for each `plan_name`.

```sql
SELECT p.plan_name,
       COUNT(s.start_date) AS plans_after_2020
FROM plans p
         LEFT JOIN subscriptions s
                   ON p.plan_id = s.plan_id
                       AND s.start_date >= '2021-01-01'
GROUP BY p.plan_name
ORDER BY plans_after_2020 DESC;
```

| plan\_name | plans\_after\_2020 |
| :--- | :--- |
| churn | 71 |
| pro annual | 63 |
| pro monthly | 60 |
| basic monthly | 8 |
| trial | 0 |


<a id="b4"></a>
#### B4: What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

> 💬 **Note** 
> - *Churn defined as the last plan (`plan_id `= `4`). Query isolates each customer’s final plan to avoid double counting and ensure churn is measured at customer level, designed to be robust even if future datasets contain intermediate churn events.*

```sql
WITH last_plan AS (SELECT s.customer_id,
                          plan_id
                   FROM subscriptions s
                   WHERE s.start_date = (SELECT MAX(s2.start_date)
                                         FROM subscriptions s2
                                         WHERE s2.customer_id = s.customer_id))
SELECT COUNT(*) FILTER (WHERE plan_id = 4) AS customers_churned,
       ROUND(COUNT(*) FILTER (WHERE plan_id = 4)::numeric / COUNT(*)::numeric * 100, 1
       )                                   AS churn_percentage
FROM last_plan;
```

| customers\_churned | churn\_percentage |
| :--- | :--- |
| 307 | 30.7 |


<a id="b5"></a>
#### B5: How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

```sql
WITH subscription_history AS (SELECT customer_id,
                                     plan_id,
                                     LAG(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS prev_plan_id
                              FROM subscriptions)
SELECT COUNT(DISTINCT customer_id) AS churned_customers,
       ROUND(COUNT(DISTINCT customer_id) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),
             0)                    AS churn_percentage
FROM subscription_history
WHERE plan_id = 4
  AND prev_plan_id = 0;
```

| churned\_customers | churn\_percentage |
| :--- | :--- |
| 92 | 9 |

<a id="b6"></a>
#### B6: What is the number and percentage of customer plans after their initial free trial?

> 💬 **Note**
> - *Denominator restricted to trial exits to stay valid if customers skip trial.*

```sql
WITH subscription_history AS (SELECT s2.customer_id,
                                     s2.plan_id,
                                     LAG(s2.plan_id)
                                     OVER (PARTITION BY s2.customer_id ORDER BY s2.start_date) AS prev_plan_id
                              FROM subscriptions s2)
SELECT p.plan_name,
       COUNT(DISTINCT sh.customer_id) as customer_plans,
       ROUND(COUNT(DISTINCT sh.customer_id) * 100.0 / (SELECT COUNT(DISTINCT customer_id)
                                                       FROM subscription_history
                                                       WHERE prev_plan_id = 0),
             2)                       AS plans_percentage
FROM subscription_history sh
         INNER JOIN plans p ON sh.plan_id = p.plan_id
WHERE prev_plan_id = 0
GROUP BY p.plan_name
ORDER BY plans_percentage DESC;
```

| plan\_name | customer\_plans | plans\_percentage |
| :--- | :--- | :--- |
| basic monthly | 546 | 54.6 |
| pro monthly | 325 | 32.5 |
| churn | 92 | 9.2 |
| pro annual | 37 | 3.7 |


<a id="b7"></a>
#### B7: What is the customer count and percentage breakdown of all 5 plan_name values at `2020-12-31`?

> 💬 **Note**
> - *Choice to use CTEs for clarity and scalability, reusing snapshot and denominator consistently.*


```sql
WITH plans_with_end AS (
    SELECT s2.customer_id,
           s2.plan_id,
           s2.start_date,
           LEAD(s2.start_date) OVER (PARTITION BY s2.customer_id ORDER BY s2.start_date) AS end_date
    FROM subscriptions s2
),
snapshot_20201231 AS (
    SELECT *
    FROM plans_with_end
    WHERE start_date <= '2020-12-31'
      AND (end_date > '2020-12-31' OR end_date IS NULL)
),
denominator AS (
    SELECT COUNT(DISTINCT customer_id) AS total_customers
    FROM snapshot_20201231
)
SELECT p.plan_name,
       COUNT(DISTINCT s.customer_id) AS customer_plans,
       ROUND(COUNT(DISTINCT s.customer_id) * 100.0 / d.total_customers, 2) AS plans_percentage
FROM snapshot_20201231 s
JOIN plans p ON p.plan_id = s.plan_id
CROSS JOIN denominator d
GROUP BY p.plan_name, d.total_customers
ORDER BY plans_percentage DESC;
```

<a id="b8"></a>
#### B8: How many customers have upgraded to an annual plan in 2020?

> 💬 **Note**
> - *Current dataset always starts with trial, so any pro annual in 2020 is an upgrade. However, if direct annual sign-ups existed, they would not count. This universal query ensures only true upgrades are returned.*

```sql
SELECT COUNT(DISTINCT s.customer_id) AS annual_upgrades_2020
FROM subscriptions s
WHERE s.plan_id = 3
  AND s.start_date BETWEEN '2020-01-01' AND '2020-12-31'
  AND EXISTS (SELECT
              FROM subscriptions s2
              WHERE s2.customer_id = s.customer_id
                AND s2.start_date < s.start_date
                AND s2.plan_id IN (0, 1, 2));
```

| annual\_upgrades\_2020 |
| :--- |
| 195 |


<a id="b9"></a>
#### B9: How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?


```sql
WITH join_upgrade_dates AS (SELECT s2.customer_id                                         AS customer_id,
                                   MIN(CASE WHEN s2.plan_id = 3 THEN s2.start_date END)   AS start_annual_plan,
                                   MIN(CASE WHEN s2.plan_id < 3 THEN (s2.start_date) END) AS join_date
                            FROM subscriptions s2
                            GROUP BY s2.customer_id
                            HAVING MIN(CASE WHEN s2.plan_id = 3 THEN s2.start_date END) IS NOT NULL),

     days_to_annual AS (SELECT j.customer_id,
                               j.start_annual_plan - j.join_date AS days_per_customer
                        FROM join_upgrade_dates j
                        ORDER BY j.customer_id)

SELECT ROUND(AVG(days_per_customer), 0) AS avg_days_to_annual
FROM days_to_annual;
```

| avg\_days\_to\_annual |
| :--- |
| 105 |

<a id="b10"></a>
#### B10: Can you further breakdown this average value into 30 day periods (i.e. `0-30 days`, `31-60 days` etc)

```sql
WITH join_upgrade_dates AS (SELECT s2.customer_id                                         AS customer_id,
                                   MIN(CASE WHEN s2.plan_id = 3 THEN s2.start_date END)   AS start_annual_plan,
                                   MIN(CASE WHEN s2.plan_id < 3 THEN (s2.start_date) END) AS join_date
                            FROM subscriptions s2
                            GROUP BY s2.customer_id
                            HAVING MIN(CASE WHEN s2.plan_id = 3 THEN s2.start_date END) IS NOT NULL),

     days_to_annual AS (SELECT j.customer_id,
                               j.start_annual_plan - j.join_date AS days_per_customer
                        FROM join_upgrade_dates j
                        ORDER BY j.customer_id)

SELECT
    CONCAT((FLOOR(days_per_customer/30)*30+1), '-', (FLOOR(days_per_customer/30)+1)*30, ' days') AS day_period,
    COUNT(*) AS annual_upgrades
FROM days_to_annual
GROUP BY day_period
ORDER BY MIN(days_per_customer);
```

| day\_period | annual\_upgrades |
| :--- | :--- |
| 1-30 days | 48 |
| 31-60 days | 25 |
| 61-90 days | 33 |
| 91-120 days | 35 |
| 121-150 days | 43 |
| 151-180 days | 35 |
| 181-210 days | 27 |
| 211-240 days | 4 |
| 241-270 days | 5 |
| 271-300 days | 1 |
| 301-330 days | 1 |
| 331-360 days | 1 |


<a id="b11"></a>
#### B11: How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

```sql
SELECT COUNT(DISTINCT s.customer_id) AS pro_downgrades_2020
FROM subscriptions s
WHERE s.plan_id = 1
  AND s.start_date BETWEEN '2020-01-01' AND '2020-12-31'
  AND EXISTS (SELECT
              FROM subscriptions s2
              WHERE s2.customer_id = s.customer_id
                AND s2.start_date < s.start_date
                AND s2.plan_id = 2);
```

| pro\_downgrades\_2020 |
| :--- |
| 0 |

---
### Section C: Challenge Payment Question

<a id="c1"></a>
#### C1: The Foodie-Fi team wants you to create a new `payments` table for the year 2020 that includes amounts paid by each customer in the `subscriptions` table with the following requirements:
- **monthly payments always occur on the same day of month as the original `start_date` of any monthly paid plan**
- **upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately**
- **upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period**
- **once a customer churns they will no longer make payments**

**Example outputs for this table might look like the following:**

| customer_id | plan_id | plan_name     | payment_date | amount | payment_order |
|-------------|---------|---------------|--------------|--------|---------------|
| 1           | 1       | basic monthly | 2020-08-08   | 9.90   | 1             |
| 1           | 1       | basic monthly | 2020-09-08   | 9.90   | 2             |
| 1           | 1       | basic monthly | 2020-10-08   | 9.90   | 3             |
| 1           | 1       | basic monthly | 2020-11-08   | 9.90   | 4             |
| 1           | 1       | basic monthly | 2020-12-08   | 9.90   | 5             |
| 2           | 3       | pro annual    | 2020-09-27   | 199.00 | 1             |
| 13          | 1       | basic monthly | 2020-12-22   | 9.90   | 1             |
| 15          | 2       | pro monthly   | 2020-03-24   | 19.90  | 1             |
| 15          | 2       | pro monthly   | 2020-04-24   | 19.90  | 2             |
| 16          | 1       | basic monthly | 2020-06-07   | 9.90   | 1             |
| 16          | 1       | basic monthly | 2020-07-07   | 9.90   | 2             |
| 16          | 1       | basic monthly | 2020-08-07   | 9.90   | 3             |
| 16          | 1       | basic monthly | 2020-09-07   | 9.90   | 4             |
| 16          | 1       | basic monthly | 2020-10-07   | 9.90   | 5             |
| 16          | 3       | pro annual    | 2020-10-21   | 189.10 | 6             |
| 18          | 2       | pro monthly   | 2020-07-13   | 19.90  | 1             |
| 18          | 2       | pro monthly   | 2020-08-13   | 19.90  | 2             |
| 18          | 2       | pro monthly   | 2020-09-13   | 19.90  | 3             |
| 18          | 2       | pro monthly   | 2020-10-13   | 19.90  | 4             |
| 18          | 2       | pro monthly   | 2020-11-13   | 19.90  | 5             |
| 18          | 2       | pro monthly   | 2020-12-13   | 19.90  | 6             |
| 19          | 2       | pro monthly   | 2020-06-29   | 19.90  | 1             |
| 19          | 2       | pro monthly   | 2020-07-29   | 19.90  | 2             |
| 19          | 3       | pro annual    | 2020-08-29   | 199.00 | 3             |

```sql
WITH ordered_subs AS (SELECT s.customer_id,
                             s.plan_id,
                             p.plan_name,
                             p.price,
                             s.start_date,
                             LEAD(s.start_date) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_date,
                             LEAD(s.plan_id) OVER (PARTITION BY s.customer_id ORDER BY s.start_date)    AS next_plan
                      FROM subscriptions s
                               JOIN plans p ON s.plan_id = p.plan_id),

     monthly_expanded AS (SELECT customer_id,
                                 plan_id,
                                 plan_name,
                                 price,
                                 start_date,
                                 generate_series(start_date,
                                                 COALESCE(next_date - INTERVAL '1 day', '2020-12-31'::date),
                                                 '1 month')::date AS payment_date
                          FROM ordered_subs
                          WHERE plan_id IN (1, 2)),

     monthly_adjusted AS (SELECT m.*,
                                 CASE
                                     WHEN o.next_plan IN (2, 3) AND o.next_date = m.payment_date THEN
                                             (SELECT price FROM plans WHERE plan_id = o.next_plan) - m.price
                                     ELSE m.price
                                     END AS amount
                          FROM monthly_expanded m
                                   JOIN ordered_subs o
                                        ON o.customer_id = m.customer_id
                                            AND o.plan_id = m.plan_id
                                            AND o.start_date = m.start_date),
     annuals AS (SELECT customer_id,
                        plan_id,
                        plan_name,
                        CASE
                            WHEN LAG(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) = 2
                                THEN start_date
                            ELSE start_date
                            END AS payment_date,
                        price   AS amount
                 FROM ordered_subs
                 WHERE plan_id = 3),

     all_payments AS (SELECT customer_id, plan_id, plan_name, payment_date, amount
                      FROM monthly_adjusted
                      UNION ALL
                      SELECT customer_id, plan_id, plan_name, payment_date, amount
                      FROM annuals)
SELECT customer_id,
       plan_id,
       plan_name,
       payment_date,
       amount,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY payment_date) AS payment_order
FROM all_payments
WHERE EXTRACT(YEAR FROM payment_date) = 2020
  AND customer_id IN (1, 2, 13, 15, 16, 18, 19)
ORDER BY customer_id, payment_date;
```


---
### Section D: Outside The Box Questions

<a id="d1"></a>
##### D1: How would you calculate the rate of growth for Foodie-Fi?

> *I would define growth in two complementary ways: customer growth rate and revenue growth rate.*
> *For the customer growth rate, I would measure the variation in the number of active paying customers in a given period divided by the total customer base at the start of that period. This indicates whether the business is expanding or contracting its paying user base.*
> *For the revenue growth rate, I would apply the same logic but using values related to new paid sign-ups, upgrades, downgrades, and churn (ARR/MRR movements). This shows the financial health of the business.*
> *It is important to analyze both in parallel because growth in one aspect does not necessarily mean growth in the other. For example, revenue growth may come from the same customer base upgrading to higher-value plans rather than from acquiring new paying customers.*

<a id="d2"></a>
##### D2: What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?

> *If the company is in an early stage (prioritizing acquisition and growth), and interpreting the dataset it seems to be the case, I would recommend Foodie-Fi to focus mainly on trial-to-paid conversion rate and time-to-convert. These metrics show how well the activation strategy is working and whether the business is moving toward proving product-market fit.*
> *If the company is in a scale-up phase, I would suggest tracking MRR/ARR growth and churn rate to evaluate how healthy that growth really is.*
> *Finally, in a mature stage, I would prioritize Net Revenue Retention (NRR) and the LTV:CAC ratio to assess predictability and acquisition efficiency. As a benchmark, an NRR consistently above 100% is usually a sign of a very strong subscription business.*

<a id="d3"></a>
##### D3: What are some key customer journeys or experiences that you would analyse further to improve customer retention?

> *I would first focus on tracking the observable customer journeys in the data, such as trial, upgrade, downgrade, and churn paths. Then I would cross-reference these outcomes with qualitative experience metrics like NPS, CSAT, and CES to gain a more complete view of potential causes and effects behind retention or attrition.*

<a id="d4"></a>
##### D4: If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?

> *The question should be multiple choice with an “Other” option to capture anything unexpected. A clear phrasing could be:*
> > ***What is the main reason you decided to cancel your Foodie-Fi subscription?***
> > 1. [ ] *I don’t use it enough to justify the cost (captures low engagement)*
> > 2. [ ] *I found a better service (identifies competitive pressure)*
> > 3. [ ] *Not enough variety or relevance in the content (highlights dissatisfaction with value)*
> > 4. [ ] *The platform was difficult to use (points to usability issues)*
> > 5. [ ] *I experienced technical problems (signals product reliability gaps)*
> > 6. [ ] *Other [please specify] (leaves room for unanticipated reasons)*

<a id="d5"></a>
##### D5: What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?

> *Churn is the ultimate lagging indicator, but I would validate levers early through leading metrics like engagement frequency, return time, content completion, and support tickets. By reason:*
> - *Too expensive / low usage – flexible pricing or pause options and track login frequency.*
> - *Found a better service – exclusive content or partnerships and track adoption of new offerings.*
> - *Lack of variety/relevance – more releases, personalization and track content depth.*
> - *Difficult to use – onboarding and UX improvements and track drop-off rates.*
> - *Technical problems – faster bug fixing and QA and track support volume.*



***Thanks for reading this far!*** *If you found it useful, consider giving it a* ⭐️. 

---

### 🏃🏻‍♂️‍➡️ Go to the next case!

<div align="center"><a href="https://github.com/pedropalmier/8-week-sql-challenge/tree/0eedcb6a42db46ac5aa13ffc4ea21a3c5cb40b78/case04_data_bank"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/hero_images/hero_data_bank.png"  style="width:50%; height:50%;"></a></div>

---
© ***Pedro Palmier** • August 2025*