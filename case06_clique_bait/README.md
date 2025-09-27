# 🎣 Case Study #6 – Clique Bait
<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/hero_images/hero_clique_bait.png" width=60% height=60%>

## 💎 Business Context 
Danny founded Clique Bait, an online seafood store, combining his background in digital data analytics with the seafood industry. See the original case study [here](https://8weeksqlchallenge.com/case-study-6/).

## ⚡️Problem Statement
Danny needs help to analyze store data and calculate funnel fallout rates to support his business vision. He prepared a total of 5 datasets that need to be combined to answer the questions. See the original schema [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/b84caab5db93cc00dea9500f779837babaa8283e/case06_clique_bait/schema.sql).

<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/ERDs/ERD_clique_bait_preview.png" width=80% height=80% >



## ❓Case Study Questions
### Section A: Entity Relationship Diagram
1. [Using the following DDL schema details to create an ERD for all the Clique Bait datasets.](#a1)

### Section B: Digital Analysis
1. [How many users are there?](#b1)
2. [How many cookies does each user have on average?](#b2)
3. [What is the unique number of visits by all users per month?](#b3)
4. [What is the number of events for each event type?](#b4)
5. [What is the percentage of visits which have a purchase event?](#b5)
6. [What is the percentage of visits which view the checkout page but do not have a purchase event?](#b6)
7. [What are the top 3 pages by number of views?](#b7)
8. [What is the number of views and cart adds for each product category?](#b8)
9. [What are the top 3 products by purchases?](#b9)

### Section C: Product Funnel Analysis
1. [Using a single SQL query - create a new output table which has the following details:(…)](#c1)
2. [Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.](#c2)
3. [Which product had the most views, cart adds and purchases?](#c3)
4. [Which product was most likely to be abandoned?](#c4)
5. [Which product had the highest view to purchase percentage?](#c5)
6. [What is the average conversion rate from view to cart add?](#c6)
7. [What is the average conversion rate from cart add to purchase?](#c7)


## 🎯 My Solution
*View the complete syntax [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/c0aa498043bdfefe8207e5d8771ed2fdd1388aa9/case06_clique_bait/solution.sql).*

### Section A: Entity Relationship Diagram
<a id="a1"></a>
#### A1: Using the following DDL schema details to create an ERD for all the Clique Bait datasets.

```sql
CREATE TABLE clique_bait.event_identifier (
  "event_type" INTEGER,
  "event_name" VARCHAR(13)
);

CREATE TABLE clique_bait.campaign_identifier (
  "campaign_id" INTEGER,
  "products" VARCHAR(3),
  "campaign_name" VARCHAR(33),
  "start_date" TIMESTAMP,
  "end_date" TIMESTAMP
);

CREATE TABLE clique_bait.page_hierarchy (
  "page_id" INTEGER,
  "page_name" VARCHAR(14),
  "product_category" VARCHAR(9),
  "product_id" INTEGER
);

CREATE TABLE clique_bait.users (
  "user_id" INTEGER,
  "cookie_id" VARCHAR(6),
  "start_date" TIMESTAMP
);

CREATE TABLE clique_bait.events (
  "visit_id" VARCHAR(6),
  "cookie_id" VARCHAR(6),
  "page_id" INTEGER,
  "event_type" INTEGER,
  "sequence_number" INTEGER,
  "event_time" TIMESTAMP
);

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
```

<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/ERDs/ERD_clique_bait_solution_preview.png" width=80% height=80% >

---
### Section B: Digital Analysis
<a id="b1"></a>
#### B1: How many users are there?

```sql
SELECT COUNT(DISTINCT user_id) AS users_count
FROM users;
```

| users\_count |
| :--- |
| 500 |


<a id="b2"></a>
#### B2: How many cookies does each user have on average?

```sql
WITH cookies_count AS (SELECT user_id,
                              COUNT(cookie_id) as cookies_per_user
                       FROM users
                       GROUP BY user_id)

SELECT ROUND(AVG(cookies_per_user), 1) AS avg_cookie_per_user
FROM cookies_count;
```

| avg\_cookie\_per\_user |
| :--- |
| 3.6 |


<a id="b3"></a>
#### B3: What is the unique number of visits by all users per month?


```sql
SELECT TRIM(TO_CHAR(event_time, 'YYYY Month')) AS month,
       COUNT(DISTINCT visit_id)                AS visits_count
FROM events
GROUP BY month
ORDER BY MIN(event_time);
```

| month | visits\_count |
| :--- | :--- |
| 2020 January | 876 |
| 2020 February | 1488 |
| 2020 March | 916 |
| 2020 April | 248 |
| 2020 May | 36 |


<a id="b4"></a>
#### B4: What is the number of events for each event type?


```sql
SELECT ei.event_name,
       COUNT(*) AS event_count
FROM events e
         INNER JOIN event_identifier ei ON ei.event_type = e.event_type
GROUP BY ei.event_name
ORDER BY event_count DESC;
```

| event\_name | event\_count |
| :--- | :--- |
| Page View | 20928 |
| Add to Cart | 8451 |
| Purchase | 1777 |
| Ad Impression | 876 |
| Ad Click | 702 |


<a id="b5"></a>
#### B5: What is the percentage of visits which have a purchase event?

```sql
WITH events_count AS (SELECT visit_id,
                             MAX(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase_count
                      FROM events
                      GROUP BY visit_id)
SELECT ROUND(100.0 * SUM(purchase_count) / COUNT(*), 2) AS purchase_percentage
FROM events_count;
```

| purchase\_percentage |
| :--- |
| 49.86 |


<a id="b6"></a>
#### B6: What is the percentage of visits which view the checkout page but do not have a purchase event?

```sql
WITH events_count AS (SELECT visit_id,
                             MAX(CASE WHEN page_id = 12 THEN 1 ELSE 0 END)   AS checkout_count,
                             MAX(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase_flag
                      FROM events
                      GROUP BY visit_id)
SELECT ROUND(100.0 * SUM(CASE WHEN checkout_count = 1 AND purchase_flag = 0 THEN 1 ELSE 0 END) / SUM(checkout_count),
             2) AS checkout_without_purchase_view_percentage
FROM events_count;
```

| checkout\_without\_purchase\_view\_percentage |
| :--- |
| 15.5 |


<a id="b7"></a>
#### B7: What are the top 3 pages by number of views?

> 💬 **Note**
> - *Counting all page view events (not distinct visits) since the question asks for total "views"*

```sql
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
```

| page\_name | views |
| :--- | :--- |
| All Products | 4752 |
| Lobster | 2515 |
| Crab | 2513 |


<a id="b8"></a>
#### B8: What is the number of views and cart adds for each product category?

```sql
SELECT p.product_category,
       SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
       SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_adds
FROM page_hierarchy p
         INNER JOIN events e ON e.page_id = p.page_id
         INNER JOIN event_identifier ei ON ei.event_type = e.event_type
GROUP BY p.product_category
ORDER BY p.product_category;
```

| product\_category | views | cart\_adds |
| :--- | :--- | :--- |
| Fish | 4633 | 2789 |
| Luxury | 3032 | 1870 |
| Shellfish | 6204 | 3792 |
| null | 7059 | 0 |


<a id="b9"></a>
#### B9: What are the top 3 products by purchases?

> 💬 **Note**
> - *Direct product-to-purchase link is absent in the schema, so it is inferred via `visit_id`. This proxy cannot disambiguate multiple products per visit, repeated adds, or the exact purchased items.*

```sql
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
```

| page\_name | purchases | rank |
| :--- | :--- | :--- |
| Lobster | 754 | 1 |
| Oyster | 726 | 2 |
| Crab | 719 | 3 |

---
### Section C: Product Funnel Analysis
<a id="c1"></a>
#### C1: Using a single SQL query - create a new output table which has the following details:
- **How many times was each product viewed?**
- **How many times was each product added to cart?**
- **How many times was each product added to a cart but not purchased (abandoned)?**
- **How many times was each product purchased?**

> 💬 **Note**
> - *D‌irect product-to-purchase link is absent in the schema, so it is inferred via `visit_id`. This proxy cannot disambiguate multiple products per visit, repeated adds, or the exact purchased items.*

```sql
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
```

| product\_name | product\_category | views | add\_to\_cart | abandoned | purchases |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Abalone | Shellfish | 1525 | 932 | 233 | 699 |
| Black Truffle | Luxury | 1469 | 924 | 217 | 707 |
| Crab | Shellfish | 1564 | 949 | 230 | 719 |
| Kingfish | Fish | 1559 | 920 | 213 | 707 |
| Lobster | Shellfish | 1547 | 968 | 214 | 754 |
| Oyster | Shellfish | 1568 | 943 | 217 | 726 |
| Russian Caviar | Luxury | 1563 | 946 | 249 | 697 |
| Salmon | Fish | 1559 | 938 | 227 | 711 |
| Tuna | Fish | 1515 | 931 | 234 | 697 |


<a id="c2"></a>
#### C2: Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

> 💬 **Note**
> - *‌Direct product-to-purchase link is absent in the schema, so it is inferred via `visit_id`. This proxy cannot disambiguate multiple products per visit, repeated adds, or the exact purchased items.*

```sql
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
```

| product\_category | views | add\_to\_cart | abandoned | purchases |
| :--- | :--- | :--- | :--- | :--- |
| Shellfish | 6204 | 3792 | 894 | 2898 |
| Fish | 4633 | 2789 | 674 | 2115 |
| Luxury | 3032 | 1870 | 466 | 1404 |


<a id="c3"></a>
#### C3: Which product had the most views, cart adds and purchases?


```sql
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
```

| product\_name | product\_category | views | rank |
| :--- | :--- | :--- | :--- |
| Oyster | Shellfish | 1568 | 1 |


```sql
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
```

| product\_name | product\_category | add\_to\_cart | rank |
| :--- | :--- | :--- | :--- |
| Lobster | Shellfish | 968 | 1 |


```sql
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
```

| product\_name | product\_category | purchases | rank |
| :--- | :--- | :--- | :--- |
| Lobster | Shellfish | 754 | 1 |


<a id="c4"></a>
#### C4: Which product was most likely to be abandoned?


```sql
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
```

| product\_name | product\_category | abandoned | rank |
| :--- | :--- | :--- | :--- |
| Russian Caviar | Luxury | 249 | 1 |


<a id="c5"></a>
#### C5: Which product had the highest view to purchase percentage?

```sql
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
```

| product\_name | product\_category | view\_to\_purchase\_percentage | rank |
| :--- | :--- | :--- | :--- |
| Lobster | Shellfish | 48.74 | 1 |

<a id="c6"></a>
#### C6: What is the average conversion rate from view to cart add?

```sql
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
```

| avg\_view\_to\_cart\_percentage |
| :--- |
| 60.95 |

<a id="c7"></a>
#### C7: What is the average conversion rate from cart add to purchase?

```sql
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
```

| avg\_cart\_to\_purchase\_percentage |
| :--- |
| 75.93 |


***Thanks for reading this far!*** *If you found it useful, consider giving it a* ⭐️. 

---

### 🏃🏻‍♂️‍➡️ Go to the next case!

<div align="center"><a href="https://github.com/pedropalmier/8-week-sql-challenge/tree/b66446d8a8290d94964d91ed2e3e92c5aa2b02cd/case07_balanced_tree"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/hero_images/hero_balanced_tree.png"  style="width:50%; height:50%;"></a></div>

---
© ***Pedro Palmier** – São Paulo, Winter 2025.*