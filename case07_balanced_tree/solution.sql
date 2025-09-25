/*
================================================================================
BALANCED TREE - CASE STUDY #7
================================================================================
Author: Pedro Palmier
Purpose: Portfolio project demonstrating advanced SQL & analytical thinking
Dataset: Danny Ma's 8 Week SQL Challenge
================================================================================
*/

/* NOTES:
1. In this case study schema, price is assumed to be the unit price per product and discount is assumed to be a percentage (0–1). All queries and calculations are based on these assumptions since the dataset does not clearly define these fields.
2. Revenue is understood as gross amount minus discount.
*/
-- ============================================================================
-- SECTION A: High Level Sales Analysis
-- ============================================================================
/*
QUESTION A1: What was the total quantity sold for all products?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
SELECT SUM(qty) AS total_qty_sold
FROM sales;

/*
QUESTION A2: What is the total generated revenue for all products before discounts?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
SELECT SUM(qty * price) AS total_revenue_before_discounts
FROM sales;

/*
QUESTION A3: What was the total discount amount for all products?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
SELECT SUM((qty * price * (discount / 100.00))) AS total_discount_amount
FROM sales;


-- ============================================================================
-- SECTION B: Transaction Analysis
-- ============================================================================
/*
QUESTION B1: How many unique transactions were there?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
SELECT COUNT(DISTINCT txn_id) AS unique_transactions
FROM sales;


/*
QUESTION B2: What is the average unique products purchased in each transaction?
OWNER: Pedro Palmier
CREATED: 2025-09-16
*/
WITH products AS (SELECT txn_id,
                         COUNT(DISTINCT prod_id) AS unique_products
                  FROM sales
                  GROUP BY txn_id)

SELECT ROUND(AVG(unique_products)) AS avg_unique_products
FROM products;

/*
QUESTION B3: What are the 25th, 50th and 75th percentile values for the revenue per transaction?
OWNER: Pedro Palmier
CREATED: 2025-09-17
*/
WITH revenue_per_transactions AS (SELECT txn_id, SUM(qty * price * (1 - discount / 100.00)) AS transaction_revenue
                                  FROM sales
                                  GROUP BY txn_id)

SELECT percentile_disc(0.25) WITHIN GROUP (ORDER BY transaction_revenue) AS p25,
       percentile_disc(0.5) WITHIN GROUP (ORDER BY transaction_revenue)  AS median,
       percentile_disc(0.75) WITHIN GROUP (ORDER BY transaction_revenue) AS p75
FROM revenue_per_transactions;


/*
QUESTION B4: What is the average discount value per transaction?
OWNER: Pedro Palmier
CREATED: 2025-09-17
*/
WITH discount_per_tnx AS (SELECT txn_id,
                                 SUM((qty * price * (discount / 100.00))) AS discount_per_tnx
                          FROM sales
                          GROUP BY txn_id)


SELECT ROUND(AVG(discount_per_tnx), 2) AS avg_discount_per_tnx
FROM discount_per_tnx;


/*
QUESTION B5: What is the percentage split of all transactions for members vs non-members?
OWNER: Pedro Palmier
CREATED: 2025-09-17
*/
WITH membership_transactions AS (SELECT COUNT(txn_id) AS                                total_tnx,
                                        SUM(CASE WHEN member = TRUE THEN 1 ELSE 0 END)  members_tnx,
                                        SUM(CASE WHEN member = FALSE THEN 1 ELSE 0 END) non_members_tnx
                                 FROM sales)

SELECT ROUND((members_tnx * 100.00 / total_tnx), 2)     AS members_tnx,
       ROUND((non_members_tnx * 100.00 / total_tnx), 2) AS non_members_tnx
FROM membership_transactions;


/*
QUESTION B6: What is the average revenue for member transactions and non-member transactions?
OWNER: Pedro Palmier
CREATED: 2025-09-17
*/

WITH revenue_per_transaction AS (SELECT member,
                                        txn_id,
                                        SUM(qty * price * (1 - discount / 100.00)) AS txn_revenue
                                 FROM sales
                                 GROUP BY member, txn_id)

SELECT member,
       ROUND(AVG(txn_revenue), 2) avg_revenue
FROM revenue_per_transaction
GROUP BY member
ORDER BY avg_revenue DESC;

-- ============================================================================
-- SECTION C: Product Analysis
-- ============================================================================

/*
QUESTION C1: What are the top 3 products by total revenue before discount?
OWNER: Pedro Palmier
CREATED: 2025-09-17
*/
WITH product_rank AS (SELECT s.prod_id,
                             p.product_name,
                             SUM(s.qty * s.price)                             AS total_revenue,
                             RANK() OVER (ORDER BY SUM(s.qty * s.price) DESC) AS rank
                      FROM sales s
                               INNER JOIN product_details p ON p.product_id = s.prod_id
                      GROUP BY prod_id, p.product_name)

SELECT product_name, total_revenue, rank
FROM product_rank
WHERE rank BETWEEN 1 AND 3
ORDER BY rank;


/*
QUESTION C2: What is the total quantity, revenue and discount for each segment?
OWNER: Pedro Palmier
CREATED: 2025-09-17
*/
SELECT p.segment_name,
       SUM(s.qty)                                         AS total_qty,
       SUM((s.qty * s.price * (1 - s.discount / 100.00))) AS total_revenue,
       SUM((s.qty * s.price * (s.discount / 100.00)))     AS total_discount
FROM sales s
         INNER JOIN product_details p ON p.product_id = s.prod_id
GROUP BY p.segment_name
ORDER BY p.segment_name;


/*
QUESTION C3: What is the top selling product for each segment?
OWNER: Pedro Palmier
CREATED: 2025-09-17
*/
WITH total_sells AS (SELECT p.segment_name,
                            p.product_name,
                            SUM(s.qty)                                                         AS total_qty,
                            RANK() OVER (PARTITION BY p.segment_name ORDER BY SUM(s.qty) DESC) AS rank
                     FROM sales s
                              INNER JOIN product_details p ON p.product_id = s.prod_id
                     GROUP BY p.segment_name, p.product_name)

SELECT *
FROM total_sells
WHERE rank = 1
ORDER BY total_qty DESC;


/*
QUESTION C4: What is the total quantity, revenue and discount for each category?
OWNER: Pedro Palmier
CREATED: 2025-09-17
*/
SELECT p.category_name,
       SUM(s.qty)                                         AS total_qty,
       SUM((s.qty * s.price * (1 - s.discount / 100.00))) AS total_revenue,
       SUM((s.qty * s.price * (s.discount / 100.00)))     AS total_discount
FROM sales s
         INNER JOIN product_details p ON p.product_id = s.prod_id
GROUP BY p.category_name
ORDER BY p.category_name;


/*
QUESTION C5: What is the top selling product for each category?
OWNER: Pedro Palmier
CREATED: 2025-09-17
*/
WITH total_sells AS (SELECT p.category_name,
                            p.product_name,
                            SUM(s.qty)                                                          AS total_qty,
                            RANK() OVER (PARTITION BY p.category_name ORDER BY SUM(s.qty) DESC) AS rank
                     FROM sales s
                              INNER JOIN product_details p ON p.product_id = s.prod_id
                     GROUP BY p.category_name, p.product_name)

SELECT *
FROM total_sells
WHERE rank = 1
ORDER BY total_qty DESC;

/*
QUESTION C6: What is the percentage split of revenue by product for each segment?
OWNER: Pedro Palmier
CREATED: 2025-09-17
*/
WITH revenue_per_product AS (SELECT p.segment_name,
                                    p.product_name,
                                    SUM((s.qty * s.price * (1 - s.discount / 100.00))) AS revenue
                             FROM sales s
                                      INNER JOIN product_details p ON p.product_id = s.prod_id
                             GROUP BY p.segment_name, p.product_name)

SELECT segment_name,
       product_name,
       revenue,
       ROUND(revenue * 100.00 / SUM(revenue) OVER (PARTITION BY segment_name), 2) AS percentage
FROM revenue_per_product
ORDER BY segment_name, product_name;


/*
QUESTION C7: What is the percentage split of revenue by segment for each category?
OWNER: Pedro Palmier
CREATED: 2025-09-17
*/
WITH revenue_per_segment AS (SELECT p.category_name,
                                    p.segment_name,
                                    SUM((s.qty * s.price * (1 - s.discount / 100.00))) AS revenue
                             FROM sales s
                                      INNER JOIN product_details p ON p.product_id = s.prod_id
                             GROUP BY p.category_name, p.segment_name)

SELECT category_name,
       segment_name,
       revenue,
       ROUND(revenue * 100.00 / SUM(revenue) OVER (PARTITION BY category_name), 2) AS percentage
FROM revenue_per_segment
ORDER BY category_name, segment_name;


/*
QUESTION C8: What is the percentage split of total revenue by category?
OWNER: Pedro Palmier
CREATED: 2025-09-17
*/
WITH revenue_per_category AS (SELECT p.category_name,
                                     SUM((s.qty * s.price * (1 - s.discount / 100.00))) AS revenue
                              FROM sales s
                                       INNER JOIN product_details p ON p.product_id = s.prod_id
                              GROUP BY p.category_name)

SELECT category_name,
       revenue,
       ROUND(revenue * 100.00 / SUM(revenue) OVER (), 2) AS percentage
FROM revenue_per_category
ORDER BY percentage DESC;


/*
QUESTION C9: What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
OWNER: Pedro Palmier
CREATED: 2025-09-17
*/
WITH txn_per_product AS (SELECT p.product_name,
                                COUNT(DISTINCT s.txn_id) AS product_txn
                         FROM sales s
                                  INNER JOIN product_details p ON p.product_id = s.prod_id
                         GROUP BY p.product_name)

SELECT product_name,
       product_txn,
       ROUND(product_txn * 100.00 / (SELECT COUNT(DISTINCT txn_id)
                                     FROM sales), 2) AS percentage
FROM txn_per_product
ORDER BY product_name;


/*
QUESTION C10: What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
OWNER: Pedro Palmier
CREATED: 2025-09-17
*/
WITH txn_product AS (SELECT DISTINCT txn_id,
                                     prod_id
                     FROM sales),

     triples AS (SELECT a.txn_id, a.prod_id AS p1, b.prod_id AS p2, c.prod_id AS p3
                 FROM txn_product a
                          JOIN txn_product b ON b.txn_id = a.txn_id AND b.prod_id > a.prod_id
                          JOIN txn_product c ON c.txn_id = a.txn_id AND c.prod_id > b.prod_id),

     combo_counts AS (SELECT p1, p2, p3, COUNT(*) AS txn_count
                      FROM triples
                      GROUP BY p1, p2, p3),

     ranked AS (SELECT p1,
                       p2,
                       p3,
                       txn_count,
                       RANK() OVER (ORDER BY txn_count DESC) AS rank
                FROM combo_counts)

SELECT d1.product_name AS product_1,
       d2.product_name AS product_2,
       d3.product_name AS product_3,
       txn_count
FROM ranked r
         JOIN product_details d1 ON d1.product_id = r.p1
         JOIN product_details d2 ON d2.product_id = r.p2
         JOIN product_details d3 ON d3.product_id = r.p3
WHERE r.rank = 1
ORDER BY txn_count DESC;
