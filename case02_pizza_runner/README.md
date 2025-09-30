# 🍕 Case Study #2 – Pizza Runner
<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/hero_images/hero_pizza_runner.png" width=60% height=60%>

## 💎 Business Context 
Pizza Runner is a pizza delivery startup that uses contracted runners and a mobile ordering app. See the original case study [here](https://8weeksqlchallenge.com/case-study-2/).


## ⚡️Problem Statement
Danny needs help to apply core calculations to better direct runners and optimize Pizza Runner's operations. He began collecting data to support the startup's growth and designed the below entity relationship diagram for the database. See the original schema [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/c0aa498043bdfefe8207e5d8771ed2fdd1388aa9/case02_pizza_runner/schema.sql).  

<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/ERDs/ERD_pizza_runner_preview.png" width=80% height=80% >


However, before meaningful analysis can be performed, the datasets in the `pizza_runner` schema require significant cleaning and preparation. In the `customer_orders` table, the columns `exclusions` and `extras` contain string representations of missing values such as 'NaN', ' ', and 'null'. They also store multiple values in a single row:

| order_id | customer_id | pizza_id | exclusions | extras | order_time           |
|:----------|:-------------|:----------|:------------|:--------|:----------------------|
| 1        | 101         | 1        |            |        | 2021-01-01 18:05:02 |
| 2        | 101         | 1        |            |        | 2021-01-01 19:00:52 |
| 3        | 102         | 1        |            |        | 2021-01-02 23:51:23 |
| 3        | 102         | 2        |            | NaN    | 2021-01-02 23:51:23 |
| 4        | 103         | 1        | 4          |        | 2021-01-04 13:23:46 |
| 4        | 103         | 1        | 4          |        | 2021-01-04 13:23:46 |
| 4        | 103         | 2        | 4          |        | 2021-01-04 13:23:46 |
| 5        | 104         | 1        | null       | 1      | 2021-01-08 21:00:29 |
| 6        | 101         | 2        | null       | null   | 2021-01-08 21:03:13 |
| 7        | 105         | 2        | null       | 1      | 2021-01-08 21:20:29 |
| 8        | 102         | 1        | null       | null   | 2021-01-09 23:54:33 |
| 9        | 103         | 1        | 4          | 1, 5   | 2021-01-10 11:22:59 |
| 10       | 104         | 1        | null       | null   | 2021-01-11 18:34:49 |
| 10       | 104         | 1        | 2, 6       | 1, 4   | 2021-01-11 18:34:49 |

For the `runner_orders` table, `pickup_time`, `distance`, `duration`, and `cancellation` also contained string representations of missing values, and the first two additionally had non-standardized measurement units:


| order_id | runner_id | pickup_time          | distance | duration    | cancellation             |
|:----------|:-----------|:----------------------|:----------|:-------------|:--------------------------|
| 1        | 1         | 2021-01-01 18:15:34 | 20km     | 32 minutes  |                          |
| 2        | 1         | 2021-01-01 19:10:54 | 20km     | 27 minutes  |                          |
| 3        | 1         | 2021-01-03 00:12:37 | 13.4km   | 20 mins     | NaN                      |
| 4        | 2         | 2021-01-04 13:53:03 | 23.4     | 40          | NaN                      |
| 5        | 3         | 2021-01-08 21:10:57 | 10       | 15          | NaN                      |
| 6        | 3         | null                 | null     | null        | Restaurant Cancellation  |
| 7        | 2         | 2020-01-08 21:30:45 | 25km     | 25mins      | null                     |
| 8        | 2         | 2020-01-10 00:15:02 | 23.4 km  | 15 minute   | null                     |
| 9        | 2         | null                 | null     | null        | Customer Cancellation    |
| 10       | 1         | 2020-01-11 18:50:20 | 10km     | 10minutes   | null                     |

Lastly, the `pizza_recipes` table contained multiple values in a single row too:
| pizza_id | toppings               |
|:----------|:-------------------------|
| 1        | 1, 2, 3, 4, 5, 6, 8, 10 |
| 2        | 4, 6, 7, 9, 11, 12      |


## ❓Case Study Questions
### Section 0: Data Cleansing Steps
1. [Make the necessary adjustments and clean the database to answer the questions in the best way.](#01)


### Section A:  Pizza Metrics
1. [How many pizzas were ordered?](#a1)
2. [How many unique customer orders were made?](#a2)
3. [How many successful orders were delivered by each runner?](#a3)
4. [How many of each type of pizza was delivered?](#a4)
5. [How many Vegetarian and Meatlovers were ordered by each customer?](#a5)
6. [What was the maximum number of pizzas delivered in a single order?](#a6)
7. [For each customer, how many delivered pizzas had at least 1 change and how many had no changes?](#a7)
8. [How many pizzas were delivered that had both exclusions and extras?](#a8)
9. [What was the total volume of pizzas ordered for each hour of the day?](#a9)
10. [What was the volume of orders for each day of the week?](#a10)

### Section B: Runner and Customer Experience
1. [How many runners signed up for each 1 week period? (i.e. week starts `2021-01-01`)](#b1)
2. [What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?](#b2)
3. [Is there any relationship between the number of pizzas and how long the order takes to prepare?](#b3)
4. [What was the average distance travelled for each customer?](#b4)
5. [What was the difference between the longest and shortest delivery times for all orders?](#b5)
6. [What was the average speed for each runner for each delivery and do you notice any trend for these values?](#b6)
7. [What is the successful delivery percentage for each runner?](#b7)

### Section C: Ingredient Optimisation
1. [What are the standard ingredients for each pizza?](#c1)
2. [What was the most commonly added extra?](#c2)
3. [What was the most common exclusion?](#c3)
4. [Generate an order item for each record in the `customer_orders` table in the format of one of the following(…)](#c4)
5. [Generate an alphabetically ordered comma separated ingredient list for each pizza order from the `customer_orders` table and add a 2x in front of any relevant ingredients (…)](#c5)
6. [What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?](#c6)

### Section D: Pricing and Ratings
1. [If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?](#d1)
2. [What if there was an additional $1 charge for any pizza extras?](#d2)
3. [The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.](#d3)
4. [Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries? (…)](#d4)
5. [If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?](#d5)

### Section E: Bonus Questions
1. [If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an `INSERT` statement to demonstrate what would happen if a new `Supreme` pizza with all the toppings was added to the Pizza Runner menu?](#e1)



## 🎯 My Solution
*View the complete syntax [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/c0aa498043bdfefe8207e5d8771ed2fdd1388aa9/case02_pizza_runner/solution.sql).*

### Section 0: Data Cleansing Steps
<a id="01"></a>
#### 01. Make the necessary adjustments and clean the database to answer the questions in the best way.   
> - *For cleaning and standardization of the `customer_orders` amd `runner_orders` tables, and normalization of the `pizza_recipes` table, I created new ones instead of overwriting the originals to preserve records, simulating a real version control scenario.*
> - *Additionally, to better handle the multi-valued fields in the `exclusions` and `extras` columns of the `customer_orders` table, I created two new tables with these values normalized.*

```sql
-- Cleaning customer_orders table
DROP TABLE IF EXISTS customer_orders_cleaned;
CREATE TABLE customer_orders_cleaned AS
SELECT order_id,
       customer_id,
       pizza_id,
       CASE
           WHEN exclusions IS NULL OR TRIM(LOWER(exclusions)) IN ('null', 'nan', '') THEN NULL
           ELSE TRIM(exclusions)
           END AS exclusions,
       CASE
           WHEN extras IS NULL OR TRIM(LOWER(extras)) IN ('null', 'nan', '') THEN NULL
           ELSE TRIM(extras)
           END AS extras,
       order_time
FROM customer_orders;
```

| order\_id | customer\_id | pizza\_id | exclusions | extras | order\_time |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | 101 | 1 | null | null | 2020-01-01 18:05:02.000000 |
| 2 | 101 | 1 | null | null | 2020-01-01 19:00:52.000000 |
| 3 | 102 | 1 | null | null | 2020-01-02 23:51:23.000000 |
| 3 | 102 | 2 | null | null | 2020-01-02 23:51:23.000000 |
| 4 | 103 | 1 | 4 | null | 2020-01-04 13:23:46.000000 |
| 4 | 103 | 1 | 4 | null | 2020-01-04 13:23:46.000000 |
| 4 | 103 | 2 | 4 | null | 2020-01-04 13:23:46.000000 |
| 5 | 104 | 1 | null | 1 | 2020-01-08 21:00:29.000000 |
| 6 | 101 | 2 | null | null | 2020-01-08 21:03:13.000000 |
| 7 | 105 | 2 | null | 1 | 2020-01-08 21:20:29.000000 |
| 8 | 102 | 1 | null | null | 2020-01-09 23:54:33.000000 |
| 9 | 103 | 1 | 4 | 1, 5 | 2020-01-10 11:22:59.000000 |
| 10 | 104 | 1 | null | null | 2020-01-11 18:34:49.000000 |
| 10 | 104 | 1 | 2, 6 | 1, 4 | 2020-01-11 18:34:49.000000 |

```sql
-- Cleaning and standardization runner_orders table
DROP TABLE IF EXISTS runner_orders_cleaned;
CREATE TABLE runner_orders_cleaned AS
SELECT order_id,
       runner_id,
       CASE
           WHEN pickup_time IS NULL OR TRIM(LOWER(pickup_time)) IN ('null', '') THEN NULL
           ELSE pickup_time::timestamp
           END AS pickup_time,
       CASE
           WHEN distance IS NULL OR TRIM(LOWER(distance)) IN ('null', '') THEN NULL
           ELSE REGEXP_REPLACE(TRIM(distance), '[^0-9.]', '', 'g')::numeric
           END AS distance,
       CASE
           WHEN duration IS NULL OR TRIM(LOWER(duration)) IN ('null', '') THEN NULL
           ELSE REGEXP_REPLACE(TRIM(duration), '[^0-9]', '', 'g')::int
           END AS duration,
       CASE
           WHEN cancellation IS NULL OR TRIM(LOWER(cancellation)) IN ('null', 'nan', '') THEN NULL
           ELSE TRIM(LOWER(cancellation))
           END AS cancellation
FROM runner_orders;

```

| order\_id | runner\_id | pickup\_time | distance | duration | cancellation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | 1 | 2020-01-01 18:15:34.000000 | 20 | 32 | null |
| 2 | 1 | 2020-01-01 19:10:54.000000 | 20 | 27 | null |
| 3 | 1 | 2020-01-03 00:12:37.000000 | 13.4 | 20 | null |
| 4 | 2 | 2020-01-04 13:53:03.000000 | 23.4 | 40 | null |
| 5 | 3 | 2020-01-08 21:10:57.000000 | 10 | 15 | null |
| 6 | 3 | null | null | null | restaurant cancellation |
| 7 | 2 | 2020-01-08 21:30:45.000000 | 25 | 25 | null |
| 8 | 2 | 2020-01-10 00:15:02.000000 | 23.4 | 15 | null |
| 9 | 2 | null | null | null | customer cancellation |
| 10 | 1 | 2020-01-11 18:50:20.000000 | 10 | 10 | null |

```sql
-- Unnesting pizza_recipes table
DROP TABLE IF EXISTS pizza_recipes_unnested;
CREATE TABLE pizza_recipes_unnested AS
SELECT pizza_id,
       TRIM(UNNEST(STRING_TO_ARRAY(toppings, ',')))::int AS topping_id
FROM pizza_recipes;
```

| pizza\_id | topping\_id |
| :--- | :--- |
| 1 | 1 |
| 1 | 2 |
| 1 | 3 |
| 1 | 4 |
| 1 | 5 |
| 1 | 6 |
| 1 | 8 |
| 1 | 10 |
| 2 | 4 |
| 2 | 6 |
| 2 | 7 |
| 2 | 9 |
| 2 | 11 |
| 2 | 12 |

```sql
--Normalizing exclusions
DROP TABLE IF EXISTS exclusions_norm;
CREATE TABLE exclusions_norm AS
SELECT order_id,
       pizza_id,
       TRIM(UNNEST(STRING_TO_ARRAY(exclusions, ',')))::int AS topping_id
FROM customer_orders_cleaned
WHERE exclusions IS NOT NULL;
```

| order\_id | pizza\_id | topping\_id |
| :--- | :--- | :--- |
| 4 | 1 | 4 |
| 4 | 1 | 4 |
| 4 | 2 | 4 |
| 9 | 1 | 4 |
| 10 | 1 | 2 |
| 10 | 1 | 6 |


```sql
-- Normalizing extras
DROP TABLE IF EXISTS extras_norm;
CREATE TABLE extras_norm AS
SELECT order_id,
       pizza_id,
       TRIM(UNNEST(STRING_TO_ARRAY(extras, ',')))::int AS topping_id
FROM customer_orders_cleaned
WHERE extras IS NOT NULL;
```

| order\_id | pizza\_id | topping\_id |
| :--- | :--- | :--- |
| 5 | 1 | 1 |
| 7 | 2 | 1 |
| 9 | 1 | 1 |
| 9 | 1 | 5 |
| 10 | 1 | 1 |
| 10 | 1 | 4 |


---
### Section A: Pizza Metrics
<a id="a1"></a>
#### A1. How many pizzas were ordered?



```sql
SELECT COUNT(*) AS pizzas_ordered
FROM customer_orders_cleaned;
```

| pizzas\_ordered |
| :--- |
| 14 |

<a id="a2"></a>
#### A2. How many unique customer orders were made?

```sql
SELECT count(DISTINCT order_id) AS unique_orders
FROM customer_orders_cleaned;
```

| unique\_orders |
| :--- |
| 10 |

<a id="a3"></a>
#### A3. How many successful orders were delivered by each runner?



```sql
SELECT runner_id,
       count(*) AS successful_orders
FROM runner_orders_cleaned
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;
```

| runner\_id | successful\_orders |
| :--- | :--- |
| 1 | 4 |
| 2 | 3 |
| 3 | 1 |

<a id="a4"></a>
#### A4. How many of each type of pizza was delivered?

```sql
SELECT p.pizza_name,
       COUNT(*) AS delivered
FROM customer_orders_cleaned c
         JOIN runner_orders_cleaned ro ON c.order_id = ro.order_id
         JOIN pizza_names p ON c.pizza_id = p.pizza_id
WHERE ro.cancellation IS NULL
GROUP BY p.pizza_name
ORDER BY delivered DESC;
```

| pizza\_name | delivered |
| :--- | :--- |
| Meatlovers | 9 |
| Vegetarian | 3 |

<a id="a5"></a>
#### A5. How many Vegetarian and Meatlovers were ordered by each customer?

```sql
SELECT c.customer_id,
       SUM(CASE WHEN c.pizza_id = 1 THEN 1 ELSE 0 END) AS meatlovers,
       SUM(CASE WHEN c.pizza_id = 2 THEN 1 ELSE 0 END) AS vegetarian
FROM customer_orders_cleaned c
         JOIN pizza_names p ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id
ORDER BY c.customer_id;
```

| customer\_id | meatlovers | vegetarian |
| :--- | :--- | :--- |
| 101 | 2 | 1 |
| 102 | 2 | 1 |
| 103 | 3 | 1 |
| 104 | 3 | 0 |
| 105 | 0 | 1 |

<a id="a6"></a>
#### A6. What was the maximum number of pizzas delivered in a single order?

```sql
WITH order_count AS (SELECT c.order_id,
                            count(*)                             AS pizza_count,
                            RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
                     FROM customer_orders_cleaned c
                              INNER JOIN runner_orders_cleaned ro ON c.order_id = ro.order_id
                     WHERE ro.cancellation IS NULL
                     GROUP BY c.order_id)

SELECT order_id,
       pizza_count
FROM order_count
WHERE rank = 1;
```

| order\_id | pizza\_count |
| :--- | :--- |
| 4 | 3 |

<a id="a7"></a>
#### A7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?


```sql
/*
QUESTION A7: For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
OWNER: Pedro Palmier
CREATED: 2025-09-06
*/

SELECT c.customer_id,
       COUNT(CASE WHEN c.exclusions IS NOT NULL OR c.extras IS NOT NULL THEN 1 END) AS plus_one_changes,
       COUNT(CASE WHEN c.exclusions IS NULL AND c.extras IS NULL THEN 1 END)        AS no_changes
FROM customer_orders_cleaned c
         INNER JOIN runner_orders_cleaned ro ON ro.order_id = c.order_id
WHERE ro.cancellation IS NULL
GROUP BY c.customer_id
ORDER BY c.customer_id;
```

| customer\_id | plus\_one\_changes | no\_changes |
| :--- | :--- | :--- |
| 101 | 0 | 2 |
| 102 | 0 | 3 |
| 103 | 3 | 0 |
| 104 | 2 | 1 |
| 105 | 1 | 0 |

<a id="a8"></a>
#### A8. How many pizzas were delivered that had both exclusions and extras?

```sql
SELECT COUNT(*) AS with_exclusions_and_extras
FROM customer_orders_cleaned c
         INNER JOIN runner_orders_cleaned ro ON c.order_id = ro.order_id
WHERE ro.cancellation IS NULL
  AND c.exclusions IS NOT NULL
  AND c.extras IS NOT NULL;
```

| with\_exclusions\_and\_extras |
| :--- |
| 1 |

<a id="a9"></a>
#### A9. What was the total volume of pizzas ordered for each hour of the day?


```sql
SELECT EXTRACT(HOUR FROM c.order_time) AS hour,
       COUNT(*)                        AS pizzas_ordered_per_hour
FROM customer_orders_cleaned c
GROUP BY hour
ORDER BY hour;
```

| hour | pizzas\_ordered\_per\_hour |
| :--- | :--- |
| 11 | 1 |
| 13 | 3 |
| 18 | 3 |
| 19 | 1 |
| 21 | 3 |
| 23 | 3 |

<a id="a10"></a>
#### A10. What was the volume of orders for each day of the week?

```sql
SELECT TRIM(TO_CHAR(c.order_time, 'Day')) AS day_of_week,
       COUNT(*)                           AS ordered_per_day
FROM customer_orders_cleaned c
GROUP BY day_of_week, EXTRACT(DOW FROM c.order_time)
ORDER BY EXTRACT(DOW FROM c.order_time);
```

| day\_of\_week | ordered\_per\_day |
| :--- | :--- |
| Wednesday | 5 |
| Thursday | 3 |
| Friday | 1 |
| Saturday | 5 |

---
### Section B: Runner and Customer Experience

<a id="b1"></a>
#### B1. How many runners signed up for each 1 week period? (i.e. week starts `2021-01-01`)

| week | runners\_signed\_up |
| :--- | :--- |
| 1 | 2 |
| 2 | 1 |
| 3 | 1 |

```sql
/*
QUESTION B1: How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
OWNER: Pedro Palmier
CREATED: 2025-09-08
*/
SELECT ((registration_date - DATE '2021-01-01') / 7) + 1 AS week,
       COUNT(runner_id)                                  AS runners_signed_up
FROM runners
GROUP BY ((registration_date - DATE '2021-01-01') / 7) + 1
ORDER BY week;

```

<a id="b2"></a>
#### B2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?


```sql
WITH time_to_arrive AS (SELECT DISTINCT ro.runner_id                                        AS runner_id,
                                        c.order_id                                          AS order_id,
                                        EXTRACT(MINUTES FROM ro.pickup_time - c.order_time) AS minutes_to_arrive

                        FROM customer_orders_cleaned c
                                 INNER JOIN runner_orders_cleaned ro ON c.order_id = ro.order_id)
SELECT runner_id,
       ROUND(AVG(t.minutes_to_arrive), 2) AS avg_minutes_to_arrive

FROM time_to_arrive t
GROUP BY runner_id
ORDER BY 2 DESC;
```

| runner\_id | avg\_minutes\_to\_arrive |
| :--- | :--- |
| 2 | 19.67 |
| 1 | 14 |
| 3 | 10 |

<a id="b3"></a>
#### B3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
> 💬 **Note**
> - *`Pickup_time` used as prep completion proxy (may include wait time) since completion timestamps unavailable.*


```sql
WITH pizza_time_per_order AS (SELECT c.order_id                                          AS order_id,
                                     COUNT(*)                                            AS pizzas_per_order,
                                     EXTRACT(MINUTES FROM ro.pickup_time - c.order_time) AS prep_minutes
                              FROM customer_orders_cleaned c
                                       INNER JOIN runner_orders_cleaned ro ON c.order_id = ro.order_id
                              WHERE ro.cancellation IS NULL
                              GROUP BY c.order_id, prep_minutes
                              ORDER BY 1)
SELECT pizzas_per_order,
       AVG(prep_minutes) AS avg_prep_minutes
FROM pizza_time_per_order
GROUP BY pizzas_per_order
ORDER BY avg_prep_minutes DESC;
```

| pizzas\_per\_order | avg\_prep\_minutes |
| :--- | :--- |
| 3 | 29 |
| 2 | 18 |
| 1 | 12 |

<a id="b4"></a>
#### B4. What was the average distance travelled for each customer?



```sql
SELECT c.customer_id,
       ROUND(AVG(DISTINCT ro.distance), 2) AS avg_distance
FROM runner_orders_cleaned ro
         INNER JOIN customer_orders_cleaned c ON c.order_id = ro.order_id
WHERE ro.distance IS NOT NULL
GROUP BY c.customer_id
ORDER BY avg_distance DESC;
```

| customer\_id | avg\_distance |
| :--- | :--- |
| 105 | 25 |
| 103 | 23.4 |
| 101 | 20 |
| 102 | 18.4 |
| 104 | 10 |

<a id="b5"></a>
#### B5. What was the difference between the longest and shortest delivery times for all orders?

```sql
SELECT MAX(ro.duration) - MIN(ro.duration) AS delivery_difference_minutes
FROM runner_orders_cleaned ro
WHERE ro.duration IS NOT NULL;
```

| delivery\_difference\_minutes |
| :--- |
| 30 |

<a id="b6"></a>
#### B6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

> 💬 **Note**
> - *Runners `1` and `3` had similar avg speeds: 45.5 km/h and 40 km/h, respectively.*
> - *Flag runner `2` for Danny: 260% fluctuation rate and avg speed of 93.6 km/h on `order_id` `8`, indicating a speeding violation.*

```sql
SELECT ro.runner_id                                   AS runner_id,
       ro.order_id                                    AS order_id,
       ROUND((ro.distance / (ro.duration / 60.0)), 2) AS km_per_hour
FROM runner_orders_cleaned ro
WHERE ro.duration IS NOT NULL
ORDER BY ro.runner_id;


-- Query used to calculate overall average per runner.
WITH speed_per_order AS (SELECT ro.runner_id                                   AS runner_id,
                                ro.order_id                                    AS order_id,
                                ROUND((ro.distance / (ro.duration / 60.0)), 2) AS km_per_hour
                         FROM runner_orders_cleaned ro
                         WHERE ro.duration IS NOT NULL
                         ORDER BY ro.runner_id)
SELECT runner_id,
       ROUND(AVG(km_per_hour), 2) AS avg_speed
FROM speed_per_order
GROUP BY runner_id
ORDER BY avg_speed DESC;
```

| runner\_id | order\_id | km\_per\_hour |
| :--- | :--- | :--- |
| 1 | 1 | 37.5 |
| 1 | 2 | 44.44 |
| 1 | 3 | 40.2 |
| 1 | 10 | 60 |
| 2 | 7 | 60 |
| 2 | 8 | 93.6 |
| 2 | 4 | 35.1 |
| 3 | 5 | 40 |

| runner\_id | avg\_speed |
| :--- | :--- |
| 2 | 62.9 |
| 1 | 45.54 |
| 3 | 40 |

<a id="b7"></a>
#### B7. What is the successful delivery percentage for each runner?

> 💬 **Note**
> - *Interpreting successful delivery as orders completed and not canceled for any reason.*

```sql
SELECT ro.runner_id,
       ROUND(SUM(CASE WHEN ro.cancellation IS NULL THEN 1 ELSE 0 END * 100.00) / COUNT(ro.order_id), 2) AS success_rate
FROM runner_orders_cleaned ro
GROUP BY ro.runner_id;
```

| runner\_id | success\_rate |
| :--- | :--- |
| 1 | 100 |
| 2 | 75 |
| 3 | 50 |

---
### Section C: Ingredient Optimisation

<a id="c1"></a>
#### C1. What are the standard ingredients for each pizza?



```sql
SELECT pn.pizza_name,
       STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name) AS ingredients
FROM pizza_recipes_unnested pr
         INNER JOIN pizza_toppings pt ON pt.topping_id = pr.topping_id
         INNER JOIN pizza_names pn ON pn.pizza_id = pr.pizza_id
GROUP BY pn.pizza_name;
```

| pizza\_name | ingredients |
| :--- | :--- |
| Meatlovers | BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| Vegetarian | Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |

<a id="c2"></a>
#### C2. What was the most commonly added extra?

```sql
WITH extra_rank AS (SELECT pt.topping_name                      AS topping_name,
                           COUNT(*)                             AS times_added,
                           RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
                    FROM extras_norm ext
                             INNER JOIN pizza_toppings pt ON pt.topping_id = ext.topping_id
                    GROUP BY pt.topping_name)
SELECT topping_name,
       times_added
FROM extra_rank
WHERE rank = 1;
```

| topping\_name | times\_added |
| :--- | :--- |
| Bacon | 4 |


<a id="c3"></a>
#### C3. What was the most common exclusion?


```sql
WITH exclusion_rank AS (SELECT pt.topping_name                      AS topping_name,
                               COUNT(*)                             AS times_excluded,
                               RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
                        FROM exclusions_norm exc
                                 INNER JOIN pizza_toppings pt ON pt.topping_id = exc.topping_id
                        GROUP BY pt.topping_name)
SELECT topping_name,
       times_excluded
FROM exclusion_rank
WHERE rank = 1;
```

| topping\_name | times\_excluded |
| :--- | :--- |
| Cheese | 4 |

<a id="c4"></a>
#### C4. Generate an order item for each record in the `customer_orders` table in the format of one of the following:
- **`Meat Lovers`**
- **`Meat Lovers - Exclude Beef`**
- **`Meat Lovers - Extra Bacon`**
- **`Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers`**

```sql
WITH order_details AS (SELECT c.order_id,
                              c.customer_id,
                              c.pizza_id,
                              pn.pizza_name,
                              STRING_AGG(DISTINCT pt_exc.topping_name, ', ') AS exclusions_list,
                              STRING_AGG(DISTINCT pt_ext.topping_name, ', ') AS extras_list
                       FROM customer_orders_cleaned c
                                LEFT JOIN pizza_names pn ON pn.pizza_id = c.pizza_id
                                LEFT JOIN exclusions_norm exc ON exc.order_id = c.order_id AND exc.pizza_id = c.pizza_id
                                LEFT JOIN pizza_toppings pt_exc ON pt_exc.topping_id = exc.topping_id
                                LEFT JOIN extras_norm ext ON ext.order_id = c.order_id AND ext.pizza_id = c.pizza_id
                                LEFT JOIN pizza_toppings pt_ext ON pt_ext.topping_id = ext.topping_id
                       GROUP BY c.order_id, c.customer_id, c.pizza_id, pn.pizza_name)
SELECT order_id,
       CONCAT(
               pizza_name,
               CASE WHEN exclusions_list IS NOT NULL THEN CONCAT(' – Exclude ', exclusions_list) ELSE '' END,
               CASE WHEN extras_list IS NOT NULL THEN CONCAT(' – Extra ', extras_list) ELSE '' END
       ) AS order_description
FROM order_details
ORDER BY order_id;
```

| order\_id | order\_description |
| :--- | :--- |
| 1 | Meatlovers |
| 2 | Meatlovers |
| 3 | Meatlovers |
| 3 | Vegetarian |
| 4 | Meatlovers – Exclude Cheese |
| 4 | Vegetarian – Exclude Cheese |
| 5 | Meatlovers – Extra Bacon |
| 6 | Vegetarian |
| 7 | Vegetarian – Extra Bacon |
| 8 | Meatlovers |
| 9 | Meatlovers – Exclude Cheese – Extra Bacon, Chicken |
| 10 | Meatlovers – Exclude BBQ Sauce, Mushrooms – Extra Bacon, Cheese |

<a id="c5"></a>
#### C5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the `customer_orders` table and add a `2x` in front of any relevant ingredients. For example: `Meat Lovers: 2xBacon, Beef, ... , Salami`.

```sql
WITH ingredient_counts AS (SELECT c.order_id,
                                  c.pizza_id,
                                  pn.pizza_name,
                                  pt.topping_name,
                                  1 + COALESCE(ext_count, 0) - COALESCE(exc_count, 0) as total_qty
                           FROM customer_orders_cleaned c
                                    INNER JOIN pizza_names pn ON pn.pizza_id = c.pizza_id
                                    INNER JOIN pizza_recipes_unnested pr ON pr.pizza_id = c.pizza_id
                                    INNER JOIN pizza_toppings pt ON pt.topping_id = pr.topping_id
                                    LEFT JOIN (SELECT order_id, pizza_id, topping_id, COUNT(*) as ext_count
                                               FROM extras_norm
                                               GROUP BY order_id, pizza_id, topping_id) ext
                                              ON ext.order_id = c.order_id AND ext.pizza_id = c.pizza_id AND
                                                 ext.topping_id = pr.topping_id
                                    LEFT JOIN (SELECT order_id, pizza_id, topping_id, COUNT(*) as exc_count
                                               FROM exclusions_norm
                                               GROUP BY order_id, pizza_id, topping_id) exc
                                              ON exc.order_id = c.order_id AND exc.pizza_id = c.pizza_id AND
                                                 exc.topping_id = pr.topping_id
                           WHERE 1 + COALESCE(ext_count, 0) - COALESCE(exc_count, 0) > 0)
SELECT order_id,
       CONCAT(pizza_name, ': ', STRING_AGG(
               CASE
                   WHEN total_qty > 1 THEN CONCAT(total_qty, 'x ', topping_name)
                   ELSE topping_name END,
               ', ' ORDER BY topping_name
                                )) AS order_description
FROM ingredient_counts
GROUP BY order_id, pizza_name
ORDER BY order_id;
```

| order\_id | order\_description |
| :--- | :--- |
| 1 | Meatlovers: BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 2 | Meatlovers: BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 3 | Meatlovers: BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 3 | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 4 | Meatlovers: BBQ Sauce, BBQ Sauce, Bacon, Bacon, Beef, Beef, Chicken, Chicken, Mushrooms, Mushrooms, Pepperoni, Pepperoni, Salami, Salami |
| 4 | Vegetarian: Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 5 | Meatlovers: BBQ Sauce, 2x Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 6 | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 7 | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 8 | Meatlovers: BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 9 | Meatlovers: BBQ Sauce, 2x Bacon, Beef, 2x Chicken, Mushrooms, Pepperoni, Salami |
| 10 | Meatlovers: 2x Bacon, 2x Bacon, Beef, Beef, 2x Cheese, 2x Cheese, Chicken, Chicken, Pepperoni, Pepperoni, Salami, Salami |

<a id="c6"></a>
#### C6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

```sql
WITH ingredient_counts AS (SELECT c.order_id,
                                  pt.topping_name,
                                  1 + COALESCE(ext_count, 0) - COALESCE(exc_count, 0) as total_qty
                           FROM customer_orders_cleaned c
                                    INNER JOIN runner_orders_cleaned ro ON c.order_id = ro.order_id
                                    INNER JOIN pizza_names pn ON pn.pizza_id = c.pizza_id
                                    INNER JOIN pizza_recipes_unnested pr ON pr.pizza_id = c.pizza_id
                                    INNER JOIN pizza_toppings pt ON pt.topping_id = pr.topping_id
                                    LEFT JOIN (SELECT order_id, pizza_id, topping_id, COUNT(*) as ext_count
                                               FROM extras_norm
                                               GROUP BY order_id, pizza_id, topping_id) ext
                                              ON ext.order_id = c.order_id AND ext.pizza_id = c.pizza_id AND
                                                 ext.topping_id = pr.topping_id
                                    LEFT JOIN (SELECT order_id, pizza_id, topping_id, COUNT(*) as exc_count
                                               FROM exclusions_norm
                                               GROUP BY order_id, pizza_id, topping_id) exc
                                              ON exc.order_id = c.order_id AND exc.pizza_id = c.pizza_id AND
                                                 exc.topping_id = pr.topping_id
                           WHERE 1 + COALESCE(ext_count, 0) - COALESCE(exc_count, 0) > 0
                             AND ro.cancellation IS NULL)
SELECT topping_name,
       SUM(total_qty) AS most_frequent
FROM ingredient_counts
GROUP BY topping_name
ORDER BY most_frequent DESC;
```

| topping\_name | most\_frequent |
| :--- | :--- |
| Bacon | 12 |
| Cheese | 11 |
| Mushrooms | 10 |
| Pepperoni | 9 |
| Beef | 9 |
| Salami | 9 |
| Chicken | 9 |
| BBQ Sauce | 7 |
| Tomatoes | 3 |
| Tomato Sauce | 3 |
| Peppers | 3 |
| Onions | 3 |

---
### Section D: Pricing and Ratings
<a id="d1"></a>
#### D1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?



```sql
SELECT SUM(
               CASE WHEN c.pizza_id = 1 THEN 12 ELSE 10 END
       ) AS total_money_earned
FROM runner_orders_cleaned ro
         INNER JOIN customer_orders_cleaned c ON c.order_id = ro.order_id
WHERE ro.cancellation IS NULL;
```

| total\_money\_earned |
| :--- |
| 138 |

<a id="d2"></a>
#### D2. What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra.



```sql
WITH pizza_revenue AS (
   SELECT SUM(CASE WHEN c.pizza_id = 1 THEN 12 ELSE 10 END) AS base_revenue
   FROM runner_orders_cleaned ro
   INNER JOIN customer_orders_cleaned c ON c.order_id = ro.order_id
   WHERE ro.cancellation IS NULL
),
extras_revenue AS (
   SELECT COUNT(*) AS total_extras
   FROM extras_norm ext
   INNER JOIN runner_orders_cleaned ro ON ro.order_id = ext.order_id
   WHERE ro.cancellation IS NULL
)
SELECT
   (SELECT base_revenue FROM pizza_revenue) +
   (SELECT total_extras FROM extras_revenue) AS total_revenue;
```

| total\_revenue |
| :--- |
| 142 |

<a id="d3"></a>
#### D3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

```sql
DROP TABLE IF EXISTS pizza_runner.runner_rating;
CREATE TABLE pizza_runner.runner_rating
(
    order_id    INTEGER,
    runner_id   INTEGER,
    customer_id INTEGER,
    rating      INTEGER,
    CONSTRAINT fk_order
        FOREIGN KEY (order_id) REFERENCES runner_orders_cleaned (order_id),
    CONSTRAINT fk_runner
        FOREIGN KEY (runner_id) REFERENCES runners (runner_id)
);

INSERT INTO pizza_runner.runner_rating (order_id, runner_id, customer_id, rating)
SELECT ro.order_id,
       ro.runner_id,
       MIN(co.customer_id)          AS customer_id,
       FLOOR(RANDOM() * 5 + 1)::INT AS rating
FROM runner_orders_cleaned ro
         JOIN customer_orders_cleaned co
              ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY ro.order_id, ro.runner_id
ORDER BY ro.order_id;
```

| order\_id | runner\_id | customer\_id | rating |
| :--- | :--- | :--- | :--- |
| 1 | 1 | 101 | 3 |
| 2 | 1 | 101 | 1 |
| 3 | 1 | 102 | 5 |
| 4 | 2 | 103 | 3 |
| 5 | 3 | 104 | 2 |
| 7 | 2 | 105 | 2 |
| 8 | 2 | 102 | 5 |
| 10 | 1 | 104 | 1 |

<a id="d4"></a>
#### D4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
- **`customer_id`**
- **`order_id`**
- **`runner_id`**
- **`rating`**
- **`order_time`**
- **`pickup_time`**
- **Time between order and pickup**
- **Delivery duration**
- **Average speed**
- **Total number of pizzas**

```sql
SELECT rr.customer_id,
       rr.order_id,
       rr.runner_id,
       rr.rating,
       c.order_time,
       ro.pickup_time,
       EXTRACT(MINUTE FROM (ro.pickup_time - c.order_time)) AS minutes_to_pickup,
       ro.duration                                          AS delivery_duration,
       ROUND((ro.distance / (ro.duration / 60.0)), 2)       AS avg_speed_kmph,
       COUNT(c.pizza_id)                                    AS total_pizzas
FROM runner_rating rr
         LEFT JOIN customer_orders_cleaned c ON c.order_id = rr.order_id
         LEFT JOIN runner_orders_cleaned ro ON ro.order_id = rr.order_id
GROUP BY rr.customer_id,
         rr.order_id,
         rr.runner_id,
         rr.rating,
         c.order_time,
         ro.pickup_time, minutes_to_pickup, delivery_duration, avg_speed_kmph
ORDER BY rr.order_id;
```

| customer\_id | order\_id | runner\_id | rating | order\_time | pickup\_time | minutes\_to\_pickup | delivery\_duration | avg\_speed\_kmph | total\_pizzas |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 101 | 1 | 1 | 3 | 2020-01-01 18:05:02.000000 | 2020-01-01 18:15:34.000000 | 10 | 32 | 37.5 | 1 |
| 101 | 2 | 1 | 1 | 2020-01-01 19:00:52.000000 | 2020-01-01 19:10:54.000000 | 10 | 27 | 44.44 | 1 |
| 102 | 3 | 1 | 5 | 2020-01-02 23:51:23.000000 | 2020-01-03 00:12:37.000000 | 21 | 20 | 40.2 | 2 |
| 103 | 4 | 2 | 3 | 2020-01-04 13:23:46.000000 | 2020-01-04 13:53:03.000000 | 29 | 40 | 35.1 | 3 |
| 104 | 5 | 3 | 2 | 2020-01-08 21:00:29.000000 | 2020-01-08 21:10:57.000000 | 10 | 15 | 40 | 1 |
| 105 | 7 | 2 | 2 | 2020-01-08 21:20:29.000000 | 2020-01-08 21:30:45.000000 | 10 | 25 | 60 | 1 |
| 102 | 8 | 2 | 5 | 2020-01-09 23:54:33.000000 | 2020-01-10 00:15:02.000000 | 20 | 15 | 93.6 | 1 |
| 104 | 10 | 1 | 1 | 2020-01-11 18:34:49.000000 | 2020-01-11 18:50:20.000000 | 15 | 10 | 60 | 2 |

<a id="d5"></a>
#### D5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?


```sql
WITH coust_per_order AS (SELECT c.order_id,
                                SUM(
                                        CASE WHEN c.pizza_id = 1 THEN 12 ELSE 10 END
                                )                 AS cost,
                                ro.distance * 0.3 AS runner_paid
                         FROM runner_orders_cleaned ro
                                  INNER JOIN customer_orders_cleaned c ON c.order_id = ro.order_id
                         WHERE ro.cancellation IS NULL
                         GROUP BY c.order_id, runner_paid)

SELECT SUM(cost - runner_paid) AS total_profit
FROM coust_per_order;
```

| total\_profit |
| :--- |
| 94.44 |

---
### Section E: Bonus Question
<a id="e1"></a>
#### E1. If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an `INSERT` statement to demonstrate what would happen if a new `Supreme` pizza with all the toppings was added to the Pizza Runner menu?


```sql
INSERT INTO pizza_runner.pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

INSERT INTO pizza_runner.pizza_recipes_unnested (pizza_id, topping_id)
SELECT 3, topping_id
FROM pizza_runner.pizza_toppings;

INSERT INTO pizza_runner.pizza_recipes (pizza_id, toppings)
SELECT 3, string_agg(topping_id::text, ', ')
FROM pizza_runner.pizza_toppings;
```

| pizza\_id | pizza\_name |
| :--- | :--- |
| 1 | Meatlovers |
| 2 | Vegetarian |
| 3 | Supreme |

| pizza\_id | topping\_id |
| :--- | :--- |
| 1 | 1 |
| 1 | 2 |
| 1 | 3 |
| 1 | 4 |
| 1 | 5 |
| 1 | 6 |
| 1 | 8 |
| 1 | 10 |
| 2 | 4 |
| 2 | 6 |
| 2 | 7 |
| 2 | 9 |
| 2 | 11 |
| 2 | 12 |
| 3 | 1 |
| 3 | 2 |
| 3 | 3 |
| 3 | 4 |
| 3 | 5 |
| 3 | 6 |
| 3 | 7 |
| 3 | 8 |
| 3 | 9 |
| 3 | 10 |
| 3 | 11 |
| 3 | 12 |

***Thanks for reading this far!*** *If you found it useful, consider giving it a* ⭐️. 

---

### 🏃🏻‍♂️‍➡️ Go to the next case!

<div align="center"><a href="https://github.com/pedropalmier/8-week-sql-challenge/tree/597b5e3bdda197074441501a8aaa405b7a222069/case03_foodie_fi"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/hero_images/hero_foodie_fi.png"  style="width:50%; height:50%;"></a></div>

---
© ***Pedro Palmier** • September 2025*
