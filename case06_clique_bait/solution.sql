/*
================================================================================
CLIQUE BAIT - CASE STUDY #6
================================================================================
Author: Pedro Palmier
Purpose: Portfolio project demonstrating advanced SQL & analytical thinking
Dataset: Danny Ma's 8 Week SQL Challenge
================================================================================
*/

-- ============================================================================
-- SECTION A: Enterprise Relationship Diagram
-- ============================================================================
/*
QUESTION A1: Using the following DDL schema details to create an ERD for all the Clique Bait datasets.
NOTE: Primary Keys are defined even without direct Foreign Keys to guarantee entity integrity, enable indexing, and prepare the schema for future relationships or queries.
OWNER: Pedro Palmier
CREATED: 2025-09-15
*/
-- Primary Keys
ALTER TABLE event_identifier
    ADD CONSTRAINT pk_event_identifier PRIMARY KEY (event_type);

ALTER TABLE page_hierarchy
    ADD CONSTRAINT pk_page_hierarchy PRIMARY KEY (page_id);

ALTER TABLE users
    ADD CONSTRAINT pk_users PRIMARY KEY (cookie_id);

-- Foreign Keys
ALTER TABLE events
    ADD CONSTRAINT fk_events_event_type
        FOREIGN KEY (event_type) REFERENCES event_identifier (event_type);

ALTER TABLE events
    ADD CONSTRAINT fk_events_page_id
        FOREIGN KEY (page_id) REFERENCES page_hierarchy (page_id);

ALTER TABLE events
    ADD CONSTRAINT fk_events_cookie_id
        FOREIGN KEY (cookie_id) REFERENCES users (cookie_id);


-- ============================================================================
-- SECTION B: Digital Analysis
-- ============================================================================
/*
QUESTION B1: How many users are there?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
SELECT COUNT(DISTINCT user_id) AS users_count
FROM users;

/*
QUESTION B2: How many cookies does each user have on average?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/

WITH cookies_count AS (SELECT user_id,
                              COUNT(cookie_id) as cookies_per_user
                       FROM users
                       GROUP BY user_id)

SELECT ROUND(AVG(cookies_per_user), 1) AS avg_cookie_per_user
FROM cookies_count;

/*
QUESTION B3: What is the unique number of visits by all users per month?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
SELECT TRIM(TO_CHAR(event_time, 'YYYY Month')) AS month,
       COUNT(DISTINCT visit_id)                AS visits_count
FROM events
GROUP BY month
ORDER BY MIN(event_time);

/*
QUESTION B4: What is the number of events for each event type?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
SELECT ei.event_name,
       COUNT(*) AS event_count
FROM events e
         INNER JOIN event_identifier ei ON ei.event_type = e.event_type
GROUP BY ei.event_name
ORDER BY event_count DESC;

/*
QUESTION B5: What is the percentage of visits which have a purchase event?
NOTE: MAX ensures each visit is flagged once even if multiple purchase events occur per visit.
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
WITH events_count AS (SELECT visit_id,
                             MAX(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase_count
                      FROM events
                      GROUP BY visit_id)
SELECT ROUND(100.0 * SUM(purchase_count) / COUNT(*), 2) AS purchase_percentage
FROM events_count;


/*
QUESTION B6: What is the percentage of visits which view the checkout page but do not have a purchase event?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
WITH events_count AS (SELECT visit_id,
                             MAX(CASE WHEN page_id = 12 THEN 1 ELSE 0 END)   AS checkout_count,
                             MAX(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase_flag
                      FROM events
                      GROUP BY visit_id)
SELECT ROUND(100.0 * SUM(CASE WHEN checkout_count = 1 AND purchase_flag = 0 THEN 1 ELSE 0 END) / SUM(checkout_count),
             2) AS checkout_without_purchase_view_percentage
FROM events_count;


/*
QUESTION B7: What are the top 3 pages by number of views?
NOTE:: Counting all page view events (not distinct visits) since the question asks for total "views"
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
WITH views_rank AS (SELECT p.page_name                          AS page_name,
                           COUNT(*)                             AS views,
                           RANK() OVER (ORDER BY COUNT(*) DESC) AS rank

                    FROM events e
                             INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                    GROUP BY p.page_name)

SELECT page_name, views
FROM views_rank
WHERE rank IN (1, 2, 3)
ORDER BY views DESC;

/*
QUESTION B8: What is the number of views and cart adds for each product category?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
SELECT p.product_category,
       SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
       SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_adds
FROM page_hierarchy p
         INNER JOIN events e ON e.page_id = p.page_id
         INNER JOIN event_identifier ei ON ei.event_type = e.event_type
GROUP BY p.product_category
ORDER BY p.product_category;


/*
QUESTION B9: What are the top 3 products by purchases?
NOTE: Direct product-to-purchase link is absent in the schema, so it is inferred via visit_id. This proxy cannot disambiguate multiple products per visit, repeated adds, or the exact purchased items.
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
WITH viewed_cart_count AS (SELECT e.visit_id,
                                  p.page_name,
                                  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart_count
                           FROM events e
                                    INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                           WHERE p.product_id IS NOT NULL
                           GROUP BY e.visit_id,
                                    p.page_name),

     purchased_count AS (SELECT e.visit_id,
                                SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases_count

                         FROM events e
                                  INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                         GROUP BY e.visit_id),

     rank_purchases AS (SELECT v.page_name,
                               SUM(CASE
                                       WHEN v.add_to_cart_count = 1 AND p.purchases_count = 1 THEN 1
                                       ELSE 0 END)                             AS purchases,
                               RANK() OVER (ORDER BY SUM(CASE
                                                             WHEN v.add_to_cart_count = 1 AND p.purchases_count = 1
                                                                 THEN 1
                                                             ELSE 0 END) DESC) AS rank
                        FROM viewed_cart_count v
                                 LEFT JOIN purchased_count p ON v.visit_id = p.visit_id
                        WHERE v.page_name IS NOT NULL
                        GROUP BY v.page_name
                        ORDER BY purchases DESC)


SELECT page_name, purchases, rank
FROM rank_purchases
WHERE rank BETWEEN 1 AND 3
ORDER BY rank;



-- ============================================================================
-- SECTION C: Product Funnel Analysis
-- ============================================================================
/*
QUESTION C1: Using a single SQL query - create a new output table which has the following details:
- How many times was each product viewed?
- How many times was each product added to cart?
- How many times was each product added to a cart but not purchased (abandoned)?
- How many times was each product purchased?
NOTE: Direct product-to-purchase link is absent in the schema, so it is inferred via visit_id. This proxy cannot disambiguate multiple products per visit, repeated adds, or the exact purchased items.
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
WITH viewed_cart_count AS (SELECT e.visit_id,
                                  p.page_name,
                                  p.product_category,
                                  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
                                  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart_count
                           FROM events e
                                    INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                           WHERE p.product_id IS NOT NULL
                           GROUP BY e.visit_id,
                                    p.page_name,
                                    p.product_category),

     purchased_count AS (SELECT e.visit_id,
                                SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases_count
                         FROM events e
                                  INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                         GROUP BY e.visit_id)

SELECT v.page_name                                                                        AS product_name,
       v.product_category,
       SUM(v.views)                                                                       AS views,
       SUM(v.add_to_cart_count)                                                           AS add_to_cart,
       SUM(CASE WHEN v.add_to_cart_count = 1 AND p.purchases_count = 0 THEN 1 ELSE 0 END) AS abandoned,
       SUM(CASE WHEN v.add_to_cart_count = 1 AND p.purchases_count = 1 THEN 1 ELSE 0 END) AS purchases
FROM viewed_cart_count v
         LEFT JOIN purchased_count p ON v.visit_id = p.visit_id
WHERE v.page_name IS NOT NULL
GROUP BY v.page_name, v.product_category
ORDER BY v.page_name;

/*
QUESTION C2: Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
NOTE: Direct product-to-purchase link is absent in the schema, so it is inferred via visit_id. This proxy cannot disambiguate multiple products per visit, repeated adds, or the exact purchased items.
OWNER: Pedro Palmier
CREATED: 2025-09-16
 */
WITH viewed_cart_count AS (SELECT e.visit_id,
                                  p.page_name,
                                  p.product_category,
                                  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
                                  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart_count
                           FROM events e
                                    INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                           WHERE p.product_category IS NOT NULL
                           GROUP BY e.visit_id,
                                    p.page_name,
                                    p.product_category),

     purchased_count AS (SELECT e.visit_id,
                                SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases_count
                         FROM events e
                                  INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                         GROUP BY e.visit_id)

SELECT v.product_category,
       SUM(v.views)                                                                       AS views,
       SUM(v.add_to_cart_count)                                                           AS add_to_cart,
       SUM(CASE WHEN v.add_to_cart_count = 1 AND p.purchases_count = 0 THEN 1 ELSE 0 END) AS abandoned,
       SUM(CASE WHEN v.add_to_cart_count = 1 AND p.purchases_count = 1 THEN 1 ELSE 0 END) AS purchases
FROM viewed_cart_count v
         LEFT JOIN purchased_count p ON v.visit_id = p.visit_id
WHERE v.page_name IS NOT NULL
GROUP BY v.product_category
ORDER BY purchases DESC;


/*
QUESTION C3: Which product had the most views, cart adds and purchases?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
WITH viewed_cart_count AS (SELECT e.visit_id,
                                  p.page_name,
                                  p.product_category,
                                  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
                                  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart_count
                           FROM events e
                                    INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                           WHERE p.product_id IS NOT NULL
                           GROUP BY e.visit_id,
                                    p.page_name,
                                    p.product_category),

     purchased_count AS (SELECT e.visit_id,
                                SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases_count
                         FROM events e
                                  INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                         GROUP BY e.visit_id),

     product_stats AS (SELECT v.page_name,
                              v.product_category,
                              SUM(v.views)             AS views,
                              SUM(v.add_to_cart_count) AS add_to_cart,
                              SUM(CASE
                                      WHEN v.add_to_cart_count = 1 AND p.purchases_count = 0 THEN 1
                                      ELSE 0 END)      AS abandoned,
                              SUM(CASE
                                      WHEN v.add_to_cart_count = 1 AND p.purchases_count = 1 THEN 1
                                      ELSE 0 END)      AS purchases
                       FROM viewed_cart_count v
                                LEFT JOIN purchased_count p ON v.visit_id = p.visit_id
                       WHERE v.page_name IS NOT NULL
                       GROUP BY v.page_name, v.product_category),

     ranked_views AS (SELECT page_name,
                             product_category,
                             views,
                             RANK() OVER (ORDER BY views DESC) AS rank
                      FROM product_stats)
SELECT page_name AS product_name,
       product_category,
       views,
       rank
FROM ranked_views
WHERE rank = 1;

WITH viewed_cart_count AS (SELECT e.visit_id,
                                  p.page_name,
                                  p.product_category,
                                  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
                                  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart_count
                           FROM events e
                                    INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                           WHERE p.product_id IS NOT NULL
                           GROUP BY e.visit_id,
                                    p.page_name,
                                    p.product_category),

     purchased_count AS (SELECT e.visit_id,
                                SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases_count
                         FROM events e
                                  INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                         GROUP BY e.visit_id),

     product_stats AS (SELECT v.page_name,
                              v.product_category,
                              SUM(v.views)             AS views,
                              SUM(v.add_to_cart_count) AS add_to_cart,
                              SUM(CASE
                                      WHEN v.add_to_cart_count = 1 AND p.purchases_count = 0 THEN 1
                                      ELSE 0 END)      AS abandoned,
                              SUM(CASE
                                      WHEN v.add_to_cart_count = 1 AND p.purchases_count = 1 THEN 1
                                      ELSE 0 END)      AS purchases
                       FROM viewed_cart_count v
                                LEFT JOIN purchased_count p ON v.visit_id = p.visit_id
                       WHERE v.page_name IS NOT NULL
                       GROUP BY v.page_name, v.product_category),

     ranked_cart_adds AS (SELECT page_name,
                                 product_category,
                                 add_to_cart,
                                 RANK() OVER (ORDER BY add_to_cart DESC) AS rank
                          FROM product_stats)
SELECT page_name AS product_name,
       product_category,
       add_to_cart,
       rank
FROM ranked_cart_adds
WHERE rank = 1;

WITH viewed_cart_count AS (SELECT e.visit_id,
                                  p.page_name,
                                  p.product_category,
                                  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
                                  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart_count
                           FROM events e
                                    INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                           WHERE p.product_id IS NOT NULL
                           GROUP BY e.visit_id,
                                    p.page_name,
                                    p.product_category),

     purchased_count AS (SELECT e.visit_id,
                                SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases_count
                         FROM events e
                                  INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                         GROUP BY e.visit_id),

     product_stats AS (SELECT v.page_name,
                              v.product_category,
                              SUM(v.views)             AS views,
                              SUM(v.add_to_cart_count) AS add_to_cart,
                              SUM(CASE
                                      WHEN v.add_to_cart_count = 1 AND p.purchases_count = 0 THEN 1
                                      ELSE 0 END)      AS abandoned,
                              SUM(CASE
                                      WHEN v.add_to_cart_count = 1 AND p.purchases_count = 1 THEN 1
                                      ELSE 0 END)      AS purchases
                       FROM viewed_cart_count v
                                LEFT JOIN purchased_count p ON v.visit_id = p.visit_id
                       WHERE v.page_name IS NOT NULL
                       GROUP BY v.page_name, v.product_category),

     ranked_purchases AS (SELECT page_name,
                                 product_category,
                                 purchases,
                                 RANK() OVER (ORDER BY purchases DESC) AS rank
                          FROM product_stats)
SELECT page_name AS product_name,
       product_category,
       purchases,
       rank
FROM ranked_purchases
WHERE rank = 1;


/*
QUESTION C4: Which product was most likely to be abandoned?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
WITH viewed_cart_count AS (SELECT e.visit_id,
                                  p.page_name,
                                  p.product_category,
                                  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
                                  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart_count
                           FROM events e
                                    INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                           WHERE p.product_id IS NOT NULL
                           GROUP BY e.visit_id,
                                    p.page_name,
                                    p.product_category),

     purchased_count AS (SELECT e.visit_id,
                                SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases_count
                         FROM events e
                                  INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                         GROUP BY e.visit_id),

     product_stats AS (SELECT v.page_name,
                              v.product_category,
                              SUM(v.views)             AS views,
                              SUM(v.add_to_cart_count) AS add_to_cart,
                              SUM(CASE
                                      WHEN v.add_to_cart_count = 1 AND p.purchases_count = 0 THEN 1
                                      ELSE 0 END)      AS abandoned,
                              SUM(CASE
                                      WHEN v.add_to_cart_count = 1 AND p.purchases_count = 1 THEN 1
                                      ELSE 0 END)      AS purchases
                       FROM viewed_cart_count v
                                LEFT JOIN purchased_count p ON v.visit_id = p.visit_id
                       WHERE v.page_name IS NOT NULL
                       GROUP BY v.page_name, v.product_category),

     ranked_abandoned AS (SELECT page_name,
                                 product_category,
                                 abandoned,
                                 RANK() OVER (ORDER BY abandoned DESC) AS rank
                          FROM product_stats)
SELECT page_name AS product_name,
       product_category,
       abandoned,
       rank
FROM ranked_abandoned
WHERE rank = 1;


/*
QUESTION C5: Which product had the highest view to purchase percentage?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
WITH viewed_cart_count AS (SELECT e.visit_id,
                                  p.page_name,
                                  p.product_category,
                                  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
                                  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart_count
                           FROM events e
                                    INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                           WHERE p.product_id IS NOT NULL
                           GROUP BY e.visit_id,
                                    p.page_name,
                                    p.product_category),

     purchased_count AS (SELECT e.visit_id,
                                SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases_count
                         FROM events e
                                  INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                         GROUP BY e.visit_id),

     product_stats AS (SELECT v.page_name,
                              v.product_category,
                              SUM(v.views)             AS views,
                              SUM(v.add_to_cart_count) AS add_to_cart,
                              SUM(CASE
                                      WHEN v.add_to_cart_count = 1 AND p.purchases_count = 1 THEN 1
                                      ELSE 0 END)      AS purchases,
                              ROUND(
                                      CASE
                                          WHEN SUM(v.views) > 0
                                              THEN SUM(CASE
                                                           WHEN v.add_to_cart_count = 1 AND p.purchases_count = 1 THEN 1
                                                           ELSE 0 END) * 100.0
                                              / SUM(v.views)
                                          ELSE 0 END, 2
                              )                        AS view_to_purchase_percentage
                       FROM viewed_cart_count v
                                LEFT JOIN purchased_count p ON v.visit_id = p.visit_id
                       WHERE v.page_name IS NOT NULL
                       GROUP BY v.page_name, v.product_category),

     ranked_conversion AS (SELECT page_name,
                                  product_category,
                                  view_to_purchase_percentage,
                                  RANK() OVER (ORDER BY view_to_purchase_percentage DESC) AS rank
                           FROM product_stats)

SELECT page_name AS product_name,
       product_category,
       view_to_purchase_percentage,
       rank
FROM ranked_conversion
WHERE rank = 1;


/*
QUESTION C6: What is the average conversion rate from view to cart add?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
WITH viewed_cart_count AS (SELECT e.visit_id,
                                  p.page_name,
                                  p.product_category,
                                  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
                                  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart_count
                           FROM events e
                                    INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                           WHERE p.product_id IS NOT NULL
                           GROUP BY e.visit_id,
                                    p.page_name,
                                    p.product_category),

     purchased_count AS (SELECT e.visit_id,
                                SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases_count
                         FROM events e
                                  INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                         GROUP BY e.visit_id),

     product_stats AS (SELECT v.page_name,
                              v.product_category,
                              SUM(v.views)             AS views,
                              SUM(v.add_to_cart_count) AS add_to_cart,
                              SUM(CASE
                                      WHEN v.add_to_cart_count = 1 AND p.purchases_count = 1 THEN 1
                                      ELSE 0 END)      AS purchases,
                              ROUND(
                                      CASE
                                          WHEN SUM(v.views) > 0
                                              THEN SUM(v.add_to_cart_count) * 100.0 / SUM(v.views)
                                          ELSE 0 END, 2
                              )                        AS view_to_cart_percentage
                       FROM viewed_cart_count v
                                LEFT JOIN purchased_count p ON v.visit_id = p.visit_id
                       WHERE v.page_name IS NOT NULL
                       GROUP BY v.page_name, v.product_category),

     avg_conversion AS (SELECT AVG(view_to_cart_percentage) AS avg_view_to_cart_percentage
                        FROM product_stats)

SELECT avg_view_to_cart_percentage
FROM avg_conversion;

/*
QUESTION C7: What is the average conversion rate from cart add to purchase?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
WITH viewed_cart_count AS (SELECT e.visit_id,
                                  p.page_name,
                                  p.product_category,
                                  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
                                  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart_count
                           FROM events e
                                    INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                           WHERE p.product_id IS NOT NULL
                           GROUP BY e.visit_id,
                                    p.page_name,
                                    p.product_category),

     purchased_count AS (SELECT e.visit_id,
                                SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases_count
                         FROM events e
                                  INNER JOIN page_hierarchy p ON p.page_id = e.page_id
                         GROUP BY e.visit_id),

     product_stats AS (SELECT v.page_name,
                              v.product_category,
                              SUM(v.views)             AS views,
                              SUM(v.add_to_cart_count) AS add_to_cart,
                              SUM(CASE
                                      WHEN v.add_to_cart_count = 1 AND p.purchases_count = 1 THEN 1
                                      ELSE 0 END)      AS purchases,
                              ROUND(
                                      CASE
                                          WHEN SUM(v.add_to_cart_count) > 0
                                              THEN SUM(
                                                           CASE
                                                               WHEN v.add_to_cart_count = 1 AND p.purchases_count = 1
                                                                   THEN 1
                                                               ELSE 0 END
                                                   ) * 100.0 / SUM(v.add_to_cart_count)
                                          ELSE 0 END, 2
                              )                        AS cart_to_purchase_percentage
                       FROM viewed_cart_count v
                                LEFT JOIN purchased_count p ON v.visit_id = p.visit_id
                       WHERE v.page_name IS NOT NULL
                       GROUP BY v.page_name, v.product_category),

     avg_conversion AS (SELECT ROUND(AVG(cart_to_purchase_percentage), 2) AS avg_cart_to_purchase_percentage
                        FROM product_stats)

SELECT avg_cart_to_purchase_percentage
FROM avg_conversion;

