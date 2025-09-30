# 🌳 Case Study #7 – Balanced Tree
<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/hero_images/hero_balanced_tree.png" width=60% height=60%>



## 💎 Business Context 
Danny leads Balanced Tree Clothing Company, a fashion brand focused on optimized clothing and lifestyle wear for modern adventurers. See the original case study [here](https://8weeksqlchallenge.com/case-study-7/).

## ⚡️Problem Statement
Danny needs help to analyze sales performance and produce a financial report to support the merchandising team and wider business. He prepared a total of 4 datasets for this case study. See the original schema [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/b84caab5db93cc00dea9500f779837babaa8283e/case07_balanced_tree/schema.sql).

<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/ERDs/ERD_balanced_tree_preview.png" width=80% height=80% >



## ❓Case Study Questions
### Section A: High Level Sales Analysis
1. [What was the total quantity sold for all products?](#a1)
2. [What is the total generated revenue for all products before discounts?](#a2)
3. [What was the total discount amount for all products?](#a3)

### Section B: Transaction Analysis
1. [How many unique transactions were there?](#b1)
2. [What is the average unique products purchased in each transaction?](#b2)
3. [What are the 25th, 50th and 75th percentile values for the revenue per transaction?](#b3)
4. [What is the average discount value per transaction?](#b4)
5. [What is the percentage split of all transactions for members vs non-members?](#b5)
6. [What is the average revenue for member transactions and non-member transactions?](#b6)

### Section C: Product Analysis
1. [What are the top 3 products by total revenue before discount?](#c1)
2. [What is the total quantity, revenue and discount for each segment?](#c2)
3. [What is the top selling product for each segment?](#c3)
4. [What is the total quantity, revenue and discount for each category?](#c4)
5. [What is the top selling product for each category?](#c5)
6. [What is the percentage split of revenue by product for each segment?](#c6)
7. [What is the percentage split of revenue by segment for each category?](#c7)
8. [What is the percentage split of total revenue by category?](#c8)
9. [What is the total transaction *penetration* for each product? (…)](#c9)
10. [What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?](#c10)


## 🎯 My Solution
*View the complete syntax [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/b84caab5db93cc00dea9500f779837babaa8283e/case07_balanced_tree/solution.sql).*

> 💬 **Note**
> - *In this case study schema, `price` is assumed to be the unit price per product and `discount` is assumed to be a percentage (0-1). All queries and calculations are based on these assumptions since the dataset does not clearly define these fields.*
> - *Revenue is understood as gross amount minus `discount`.*

### Section A: High Level Sales Analysis
<a id="a1"></a>
#### A1: What was the total quantity sold for all products?

```sql
SELECT SUM(qty) AS total_qty_sold
FROM sales;
```

| total\_qty\_sold |
| :--- |
| 45216 |


<a id="a2"></a>
#### A2: What is the total generated revenue for all products before discounts?

```sql
SELECT SUM(qty * price) AS total_revenue_before_discounts
FROM sales;
```

| total\_revenue\_before\_discounts |
| :--- |
| 1289453 |


<a id="a3"></a>
#### A3: What was the total discount amount for all products?

```sql
SELECT SUM((qty * price * (discount / 100.00))) AS total_discount_amount
FROM sales;
```

| total\_discount\_amount |
| :--- |
| 156229.14 |

---
### Section B: Transaction Analysis
<a id="b1"></a>
#### B1: How many unique transactions were there?


```sql
SELECT COUNT(DISTINCT txn_id) AS unique_transactions
FROM sales;
```

| unique\_transactions |
| :--- |
| 2500 |


<a id="b2"></a>
#### B2: What is the average unique products purchased in each transaction?


```sql
WITH products AS (SELECT txn_id,
                         COUNT(DISTINCT prod_id) AS unique_products
                  FROM sales
                  GROUP BY txn_id)

SELECT ROUND(AVG(unique_products)) AS avg_unique_products
FROM products;
```

| avg\_unique\_products |
| :--- |
| 6 |


<a id="b3"></a>
#### B3: What are the 25th, 50th and 75th percentile values for the revenue per transaction?


```sql
WITH revenue_per_transactions AS (SELECT txn_id, SUM(qty * price * (1 - discount / 100.00)) AS transaction_revenue
                                  FROM sales
                                  GROUP BY txn_id)

SELECT percentile_disc(0.25) WITHIN GROUP (ORDER BY transaction_revenue) AS p25,
       percentile_disc(0.5) WITHIN GROUP (ORDER BY transaction_revenue)  AS median,
       percentile_disc(0.75) WITHIN GROUP (ORDER BY transaction_revenue) AS p75
FROM revenue_per_transactions;
```

| p25 | median | p75 |
| :--- | :--- | :--- |
| 326.18 | 441 | 572.75 |


<a id="b4"></a>
#### B4: What is the average discount value per transaction?


```sql
WITH discount_per_tnx AS (SELECT txn_id,
                                 SUM((qty * price * (discount / 100.00))) AS discount_per_tnx
                          FROM sales
                          GROUP BY txn_id)


SELECT ROUND(AVG(discount_per_tnx), 2) AS avg_discount_per_tnx
FROM discount_per_tnx;
```

| avg\_discount\_per\_tnx |
| :--- |
| 62.49 |


<a id="b5"></a>
#### B5: What is the percentage split of all transactions for members vs non-members?

```sql
WITH membership_transactions AS (SELECT COUNT(txn_id) AS                                total_tnx,
                                        SUM(CASE WHEN member = TRUE THEN 1 ELSE 0 END)  members_tnx,
                                        SUM(CASE WHEN member = FALSE THEN 1 ELSE 0 END) non_members_tnx
                                 FROM sales)

SELECT ROUND((members_tnx * 100.00 / total_tnx), 2)     AS members_tnx,
       ROUND((non_members_tnx * 100.00 / total_tnx), 2) AS non_members_tnx
FROM membership_transactions;
```

| members\_tnx | non\_members\_tnx |
| :--- | :--- |
| 60.03 | 39.97 |


<a id="b6"></a>
#### B6: What is the average revenue for member transactions and non-member transactions?

```sql
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
```

| member | avg\_revenue |
| :--- | :--- |
| true | 454.14 |
| false | 452.01 |

---
### Section C: Product Analysis
<a id="c1"></a>
#### C1: What are the top 3 products by total revenue before discount?

```sql
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
```

| product\_name | total\_revenue | rank |
| :--- | :--- | :--- |
| Blue Polo Shirt - Mens | 217683 | 1 |
| Grey Fashion Jacket - Womens | 209304 | 2 |
| White Tee Shirt - Mens | 152000 | 3 |


<a id="c2"></a>
#### C2: What is the total quantity, revenue and discount for each segment?


```sql
SELECT p.segment_name,
       SUM(s.qty)                                         AS total_qty,
       SUM((s.qty * s.price * (1 - s.discount / 100.00))) AS total_revenue,
       SUM((s.qty * s.price * (s.discount / 100.00)))     AS total_discount
FROM sales s
         INNER JOIN product_details p ON p.product_id = s.prod_id
GROUP BY p.segment_name
ORDER BY p.segment_name;

```

| segment\_name | total\_qty | total\_revenue | total\_discount |
| :--- | :--- | :--- | :--- |
| Jacket | 11385 | 322705.54 | 44277.46 |
| Jeans | 11349 | 183006.03 | 25343.97 |
| Shirt | 11265 | 356548.73 | 49594.27 |
| Socks | 11217 | 270963.56 | 37013.44 |


<a id="c3"></a>
#### C3: What is the top selling product for each segment?

```sql
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
```

| segment\_name | product\_name | total\_qty | rank |
| :--- | :--- | :--- | :--- |
| Jacket | Grey Fashion Jacket - Womens | 3876 | 1 |
| Jeans | Navy Oversized Jeans - Womens | 3856 | 1 |
| Shirt | Blue Polo Shirt - Mens | 3819 | 1 |
| Socks | Navy Solid Socks - Mens | 3792 | 1 |


<a id="c4"></a>
#### C4: What is the total quantity, revenue and discount for each category?


```sql
SELECT p.category_name,
       SUM(s.qty)                                         AS total_qty,
       SUM((s.qty * s.price * (1 - s.discount / 100.00))) AS total_revenue,
       SUM((s.qty * s.price * (s.discount / 100.00)))     AS total_discount
FROM sales s
         INNER JOIN product_details p ON p.product_id = s.prod_id
GROUP BY p.category_name
ORDER BY p.category_name;
```

| category\_name | total\_qty | total\_revenue | total\_discount |
| :--- | :--- | :--- | :--- |
| Mens | 22482 | 627512.29 | 86607.71 |
| Womens | 22734 | 505711.57 | 69621.43 |


<a id="c5"></a>
#### C5: What is the top selling product for each category?


```sql
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
```

| category\_name | product\_name | total\_qty | rank |
| :--- | :--- | :--- | :--- |
| Womens | Grey Fashion Jacket - Womens | 3876 | 1 |
| Mens | Blue Polo Shirt - Mens | 3819 | 1 |


<a id="c6"></a>
#### C6: What is the percentage split of revenue by product for each segment?


```sql
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
```

| segment\_name | product\_name | revenue | percentage |
| :--- | :--- | :--- | :--- |
| Jacket | Grey Fashion Jacket - Womens | 183912.12 | 56.99 |
| Jacket | Indigo Rain Jacket - Womens | 62740.47 | 19.44 |
| Jacket | Khaki Suit Jacket - Womens | 76052.95 | 23.57 |
| Jeans | Black Straight Jeans - Womens | 106407.04 | 58.14 |
| Jeans | Cream Relaxed Jeans - Womens | 32606.6 | 17.82 |
| Jeans | Navy Oversized Jeans - Womens | 43992.39 | 24.04 |
| Shirt | Blue Polo Shirt - Mens | 190863.93 | 53.53 |
| Shirt | Teal Button Up Shirt - Mens | 32062.4 | 8.99 |
| Shirt | White Tee Shirt - Mens | 133622.4 | 37.48 |
| Socks | Navy Solid Socks - Mens | 119861.64 | 44.24 |
| Socks | Pink Fluro Polkadot Socks - Mens | 96377.73 | 35.57 |
| Socks | White Striped Socks - Mens | 54724.19 | 20.2 |


<a id="c7"></a>
#### C7: What is the percentage split of revenue by segment for each category?


```sql
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
```

| category\_name | segment\_name | revenue | percentage |
| :--- | :--- | :--- | :--- |
| Mens | Shirt | 356548.73 | 56.82 |
| Mens | Socks | 270963.56 | 43.18 |
| Womens | Jacket | 322705.54 | 63.81 |
| Womens | Jeans | 183006.03 | 36.19 |


<a id="c8"></a>
#### C8: What is the percentage split of total revenue by category?


```sql
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
```

| category\_name | revenue | percentage |
| :--- | :--- | :--- |
| Mens | 627512.29 | 55.37 |
| Womens | 505711.57 | 44.63 |


<a id="c9"></a>
#### C9: What is the total transaction *penetration* for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)


```sql
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
```

| product\_name | product\_txn | percentage |
| :--- | :--- | :--- |
| Black Straight Jeans - Womens | 1246 | 49.84 |
| Blue Polo Shirt - Mens | 1268 | 50.72 |
| Cream Relaxed Jeans - Womens | 1243 | 49.72 |
| Grey Fashion Jacket - Womens | 1275 | 51 |
| Indigo Rain Jacket - Womens | 1250 | 50 |
| Khaki Suit Jacket - Womens | 1247 | 49.88 |
| Navy Oversized Jeans - Womens | 1274 | 50.96 |
| Navy Solid Socks - Mens | 1281 | 51.24 |
| Pink Fluro Polkadot Socks - Mens | 1258 | 50.32 |
| Teal Button Up Shirt - Mens | 1242 | 49.68 |
| White Striped Socks - Mens | 1243 | 49.72 |
| White Tee Shirt - Mens | 1268 | 50.72 |


<a id="c10"></a>
#### C10: What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?


```sql
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
```

| product\_1 | product\_2 | product\_3 | txn\_count |
| :--- | :--- | :--- | :--- |
| White Tee Shirt - Mens | Grey Fashion Jacket - Womens | Teal Button Up Shirt - Mens | 352 |


***Thanks for reading this far!*** *If you found it useful, consider giving it a* ⭐️. 

---

### 🏃🏻‍♂️‍➡️ Go to the next case!

<div align="center"><a href="https://github.com/pedropalmier/8-week-sql-challenge/tree/d5670cdc4a4b7f6ad6f546611a896478045f55ff/case08_fresh_segments"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/hero_images/hero_fresh_segments.png"  style="width:50%; height:50%;"></a></div>

---
© ***Pedro Palmier** – São Paulo, September 2025.*
