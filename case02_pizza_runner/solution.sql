/*
================================================================================
PIZZA RUNNER - CASE STUDY #2
================================================================================
Author: Pedro Palmier
Purpose: Portfolio project demonstrating advanced SQL & analytical thinking
Dataset: Danny Ma's 8 Week SQL Challenge
================================================================================
*/

-- ============================================================================
-- Section 0: Data Cleansing Steps
-- ============================================================================

/*
QUESTION 01: Make the necessary adjustments and clean the database to answer the questions in the best way.
OWNER: Pedro Palmier
CREATED: 2025-09-06
*/

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


-- Unnesting pizza_recipes table
DROP TABLE IF EXISTS pizza_recipes_unnested;
CREATE TABLE pizza_recipes_unnested AS
SELECT pizza_id,
       TRIM(UNNEST(STRING_TO_ARRAY(toppings, ',')))::int AS topping_id
FROM pizza_recipes;


--Normalizing exclusions
DROP TABLE IF EXISTS exclusions_norm;
CREATE TABLE exclusions_norm AS
SELECT order_id,
       pizza_id,
       TRIM(UNNEST(STRING_TO_ARRAY(exclusions, ',')))::int AS topping_id
FROM customer_orders_cleaned
WHERE exclusions IS NOT NULL;


-- Normalizing extras
DROP TABLE IF EXISTS extras_norm;
CREATE TABLE extras_norm AS
SELECT order_id,
       pizza_id,
       TRIM(UNNEST(STRING_TO_ARRAY(extras, ',')))::int AS topping_id
FROM customer_orders_cleaned
WHERE extras IS NOT NULL;

-- ============================================================================
-- SECTION A: PIZZA METRICS
-- ============================================================================
/*
QUESTION A1: How many pizzas were ordered?
OWNER: Pedro Palmier
CREATED: 2025-09-04
*/
SELECT COUNT(*) AS pizzas_ordered
FROM customer_orders_cleaned;


/*
QUESTION A2: How many unique customer orders were made?
OWNER: Pedro Palmier
CREATED: 2025-09-06
*/
SELECT count(DISTINCT order_id) AS unique_orders
FROM customer_orders_cleaned;


/*
QUESTION A3: How many successful orders were delivered by each runner?
OWNER: Pedro Palmier
CREATED: 2025-09-06
*/
SELECT runner_id,
       count(*) AS successful_orders
FROM runner_orders_cleaned
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;


/*
QUESTION A4: How many of each type of pizza was delivered?
OWNER: Pedro Palmier
CREATED: 2025-09-04
*/
SELECT p.pizza_name,
       COUNT(*) AS delivered
FROM customer_orders_cleaned c
         JOIN runner_orders_cleaned ro ON c.order_id = ro.order_id
         JOIN pizza_names p ON c.pizza_id = p.pizza_id
WHERE ro.cancellation IS NULL
GROUP BY p.pizza_name
ORDER BY delivered DESC;

/*
QUESTION A5: How many Vegetarian and Meatlovers were ordered by each customer?
OWNER: Pedro Palmier
CREATED: 2025-09-06
*/
SELECT c.customer_id,
       SUM(CASE WHEN c.pizza_id = 1 THEN 1 ELSE 0 END) AS meatlovers,
       SUM(CASE WHEN c.pizza_id = 2 THEN 1 ELSE 0 END) AS vegetarian
FROM customer_orders_cleaned c
         JOIN pizza_names p ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id
ORDER BY c.customer_id;


/*
QUESTION A6: What was the maximum number of pizzas delivered in a single order?
OWNER: Pedro Palmier
CREATED: 2025-09-06
*/
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


/*
QUESTION A8: How many pizzas were delivered that had both exclusions and extras?
OWNER: Pedro Palmier
CREATED: 2025-09-06
*/

SELECT COUNT(*) AS with_exclusions_and_extras
FROM customer_orders_cleaned c
         INNER JOIN runner_orders_cleaned ro ON c.order_id = ro.order_id
WHERE ro.cancellation IS NULL
  AND c.exclusions IS NOT NULL
  AND c.extras IS NOT NULL;


/*
QUESTION A9: What was the total volume of pizzas ordered for each hour of the day?
OWNER: Pedro Palmier
CREATED: 2025-09-06
*/
SELECT EXTRACT(HOUR FROM c.order_time) AS hour,
       COUNT(*)                        AS pizzas_ordered_per_hour
FROM customer_orders_cleaned c
GROUP BY hour
ORDER BY hour;

/*
QUESTION A10: What was the volume of orders for each day of the week?
OWNER: Pedro Palmier
CREATED: 2025-09-07
*/

SELECT TRIM(TO_CHAR(c.order_time, 'Day')) AS day_of_week,
       COUNT(*)                           AS ordered_per_day
FROM customer_orders_cleaned c
GROUP BY day_of_week, EXTRACT(DOW FROM c.order_time)
ORDER BY EXTRACT(DOW FROM c.order_time);

-- ============================================================================
-- SECTION B: RUNNER AND CUSTOMER EXPERIENCE
-- ============================================================================

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


/*
QUESTION B2: What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
OWNER: Pedro Palmier
CREATED: 2025-09-08
*/
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


/*
QUESTION B3: Is there any relationship between the number of pizzas and how long the order takes to prepare?
NOTE: pickup_time used as prep completion proxy (may include wait time) since completion timestamps unavailable
OWNER: Pedro Palmier
CREATED: 2025-09-08
*/

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


/*
QUESTION B4: What was the average distance travelled for each customer?
OWNER: Pedro Palmier
CREATED: 2025-09-08
*/

SELECT c.customer_id,
       ROUND(AVG(DISTINCT ro.distance), 2) AS avg_distance
FROM runner_orders_cleaned ro
         INNER JOIN customer_orders_cleaned c ON c.order_id = ro.order_id
WHERE ro.distance IS NOT NULL
GROUP BY c.customer_id
ORDER BY avg_distance DESC;


/*
QUESTION B5: What was the difference between the longest and shortest delivery times for all orders?
OWNER: Pedro Palmier
CREATED: 2025-09-08
*/
SELECT MAX(ro.duration) - MIN(ro.duration) AS delivery_difference_minutes
FROM runner_orders_cleaned ro
WHERE ro.duration IS NOT NULL;


/*
QUESTION B6: What was the average speed for each runner for each delivery and do you notice any trend for these values?
NOTES:
- Runners 1 and 3 had similar avg speeds: 45.5 km/h and 40 km/h, respectively;
- flag runner 2 for Danny: 260% fluctuation rate and avg speed of 93.6 km/h on order_id 8, indicating a speeding violation;
OWNER: Pedro Palmier
CREATED: 2025-09-08
*/
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


/*
QUESTION B7: What is the successful delivery percentage for each runner?
NOTE: interpreting successful delivery as orders completed and not canceled for any reason.
OWNER: Pedro Palmier
CREATED: 2025-09-08
*/

SELECT ro.runner_id,
       ROUND(SUM(CASE WHEN ro.cancellation IS NULL THEN 1 ELSE 0 END * 100.00) / COUNT(ro.order_id), 2) AS success_rate
FROM runner_orders_cleaned ro
GROUP BY ro.runner_id;



-- ============================================================================
-- SECTION C: INGREDIENT OPTIMISATION
-- ============================================================================

/*
QUESTION C1: What are the standard ingredients for each pizza?
OWNER: Pedro Palmier
CREATED: 2025-09-08
*/

SELECT pn.pizza_name,
       STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name) AS ingredients
FROM pizza_recipes_unnested pr
         INNER JOIN pizza_toppings pt ON pt.topping_id = pr.topping_id
         INNER JOIN pizza_names pn ON pn.pizza_id = pr.pizza_id
GROUP BY pn.pizza_name;


/*
QUESTION C2: What was the most commonly added extra?
OWNER: Pedro Palmier
CREATED: 2025-09-08
*/
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


/*
QUESTION C3: What was the most common exclusion?
OWNER: Pedro Palmier
CREATED: 2025-09-08
*/
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


/*
QUESTION C4: Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
OWNER: Pedro Palmier
CREATED: 2025-09-08
*/
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


/*
QUESTION C5: Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients.
OWNER: Pedro Palmier
CREATED: 2025-09-10
*/
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


/*
QUESTION C6: What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
OWNER: Pedro Palmier
CREATED: 2025-09-10
*/
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

-- ============================================================================
-- SECTION D: PRICING AND RATINGS
-- ============================================================================

/*
QUESTION D1: If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
OWNER: Pedro Palmier
CREATED: 2025-09-10
*/

SELECT SUM(
               CASE WHEN c.pizza_id = 1 THEN 12 ELSE 10 END
       ) AS total_money_earned
FROM runner_orders_cleaned ro
         INNER JOIN customer_orders_cleaned c ON c.order_id = ro.order_id
WHERE ro.cancellation IS NULL;

/*
QUESTION D2: What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
OWNER: Pedro Palmier
CREATED: 2025-09-10
*/
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


/*
QUESTION D3: The Pizza Runner team now wants to add an ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
OWNER: Pedro Palmier
CREATED: 2025-09-10
*/
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
       MIN(c.customer_id)          AS customer_id,
       FLOOR(RANDOM() * 5 + 1)::INT AS rating
FROM runner_orders_cleaned ro
         JOIN customer_orders_cleaned c
              ON c.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY ro.order_id, ro.runner_id
ORDER BY ro.order_id;


/*
QUESTION D4: Using your newly generated table - can you join all the information together to form a table which has the following information for successful deliveries?
- customer_id
- order_id
- runner_id
- rating
- order_time
- pickup_time
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas
OWNER: Pedro Palmier
CREATED: 2025-09-10
*/

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


/*
QUESTION D5: If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
OWNER: Pedro Palmier
CREATED: 2025-09-10
*/
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


-- ============================================================================
-- SECTION E: BONUS
-- ============================================================================
/*
QUESTION E1: If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
OWNER: Pedro Palmier
CREATED: 2025-09-10
*/

INSERT INTO pizza_runner.pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

INSERT INTO pizza_runner.pizza_recipes_unnested (pizza_id, topping_id)
SELECT 3, topping_id
FROM pizza_runner.pizza_toppings;

INSERT INTO pizza_runner.pizza_recipes (pizza_id, toppings)
SELECT 3, string_agg(topping_id::text, ', ')
FROM pizza_runner.pizza_toppings;
