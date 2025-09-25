# 🍜 Case Study #1 – Danny's Diner
<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/hero_images/hero_dannys_diner.png" width=60% height=60%>

## 💎 Business Context
Danny’s Diner is a small japanese restaurant that opened at the start of 2021. The menu offers three simple dishes: sushi, curry, and ramen. See the original case study statement [here](https://8weeksqlchallenge.com/case-study-1/).

## ⚡️Problem Statement
Danny needed support to analyze customer behavior using the limited data he had collected over time. The relationship diagram below illustrates the three core tables used in this case. See the original schema [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/c0aa498043bdfefe8207e5d8771ed2fdd1388aa9/case01_dannys_diner/schema.sql).

<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/ERDs/ERD_dannys_diner_preview.png" width=80% height=80% >



## ❓Case Study Questions
### Section A: Case Study Questions
1. [What is the total amount each customer spent at the restaurant?](#a1)
2. [How many days has each customer visited the restaurant?](#a2)
3. [What was the first item from the menu purchased by each customer?](#a3)
4. [What is the most purchased item on the menu and how many times was it purchased by all customers?](#a4)
5. [Which item was the most popular for each customer?](#a5)
6. [Which item was purchased first by the customer after they became a member?](#a6)
7. [Which item was purchased just before the customer became a member?](#a7)
8. [What is the total items and amount spent for each member before they became a member?](#a8)
9. [If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?](#a9)
10. [In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?](#a10)
### Section B: Bonus Questions
1. [Create a table with `customer_id`, `order_date`, `product_name`, `price`, `member` (Y/N)](#b1)
2. [Ranking of products purchased by each customer after they became a member, showing `NULL` ranking values for non-member purchases](#b2)



## 🎯 My Solution
*View the complete syntax [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/c0aa498043bdfefe8207e5d8771ed2fdd1388aa9/case01_dannys_diner/solution.sql).*

<a id="a1"></a>
#### A1. What is the total amount each customer spent at the restaurant?

```sql
SELECT s.customer_id,
       SUM(m.price) AS total_amount
FROM sales s
         INNER JOIN
     menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY total_amount DESC;
```

| customer\_id | total\_amount |
| ------------ | ------------- |
| A            | 76            |
| B            | 74            |
| C            | 36            |

<a id="a2"></a>
#### A2. How many days has each customer visited the restaurant?


```sql
SELECT s.customer_id,
       COUNT(DISTINCT s.order_date) AS visit_count
FROM sales s
GROUP BY s.customer_id
ORDER BY visit_count DESC;
```

| customer\_id | visit\_count |
| ------------ | ------------ |
| B            | 6            |
| A            | 4            |
| C            | 2            |

<a id="a3"></a>
#### A3. What was the first item from the menu purchased by each customer?

> 💬 **Notes**
> - *Multiple same-day purchases require deterministic ranking - using product_id ASC to ensure consistent results across database environments and avoid arbitrary ties*
> - *Deterministic tiebreaking critical for reliable customer journey analysis*


```sql
WITH first_purchase AS (SELECT s.customer_id,
                               m.product_id,
                               m.product_name,
                               s.order_date,
                               RANK() OVER (PARTITION BY s.customer_id ORDER BY
                                   s.order_date, s.product_id) AS rank
                        FROM sales s
                                 JOIN
                             menu m ON s.product_id = m.product_id)
SELECT customer_id,
       product_name,
       order_date
FROM first_purchase
WHERE rank = 1
ORDER BY order_date;
```

| customer\_id | product\_name | order\_date |
| ------------ | ------------- | ----------- |
| A            | sushi         | 2021-01-01  |
| B            | curry         | 2021-01-01  |
| C            | ramen         | 2021-01-01  |

<a id="a4"></a>
#### A4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```sql
WITH purchase_counts AS (SELECT m.product_name,
                                COUNT(*)                             AS purchase_count,
                                RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
                         FROM menu m
                                  INNER JOIN
                              sales s ON m.product_id = s.product_id
                         GROUP BY m.product_id, m.product_name)

SELECT product_name, purchase_count, rank
FROM purchase_counts
WHERE rank = 1;
```

| product\_name | purchase\_count | rank |
| :--- | :--- | :--- |
| ramen | 8 | 1 |

<a id="a5"></a>
#### A5. Which item was the most popular for each customer?
> 💬 **Notes**
> - *RANK() handles ties properly - customers with equal purchase counts get same rank*
> - *Preserves all tied preferences rather than arbitrary selection via ROW_NUMBER*
> - *Edge Case: customer B shows 3-way tie (sushi/curry/ramen), all ranked #1 - intentional behavior*

```sql
WITH item_rank AS (SELECT s.customer_id,
                          m.product_name,
                          COUNT(s.product_id)                                                        AS purchase_count,
                          RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS popularity_rank
                   FROM sales s
                            INNER JOIN
                        menu m ON s.product_id = m.product_id
                   GROUP BY s.customer_id, s.product_id, m.product_name)

SELECT customer_id,
       product_name,
       purchase_count
FROM item_rank
WHERE popularity_rank = 1;
```

| customer\_id | product\_name | purchase\_count |
| ------------ | ------------- | --------------- |
| A            | ramen         | 3               |
| B            | ramen         | 2               |
| B            | sushi         | 2               |
| B            | curry         | 2               |
| C            | ramen         | 3               |

<a id="a6"></a>
#### A6. Which item was purchased first by the customer after they became a member?

```sql
WITH purchased_order AS (SELECT s.customer_id,
                                s.product_id,
                                m.product_name                                                                AS first_item,
                                s.order_date,
                                RANK()
                                OVER (PARTITION BY s.customer_id ORDER BY s.order_date, s.product_id) AS purchased_order
                         FROM sales s
                                  INNER JOIN
                              members mb ON s.customer_id = mb.customer_id
                                  INNER JOIN
                              menu m ON s.product_id = m.product_id
                         WHERE s.order_date >= mb.join_date)

SELECT customer_id,
       first_item
FROM purchased_order
WHERE purchased_order = 1;
```

| customer\_id | first\_item |
| ------------ | ----------- |
| A            | curry       |
| B            | sushi       |

<a id="a7"></a>
#### A7. Which item was purchased just before the customer became a member?
> 💬 **Note**:  *handles same-day purchases using product_id ASC as deterministic tiebreaker*

```sql
WITH pre_membership_purchases AS (SELECT s.customer_id,
                                         m.product_name,
                                         s.order_date,
                                         RANK()
                                         OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC, s.product_id) AS recency_rank
                                  FROM sales s
                                           INNER JOIN
                                       members mb ON s.customer_id = mb.customer_id
                                           INNER JOIN
                                       menu m ON s.product_id = m.product_id
                                  WHERE s.order_date < mb.join_date)

SELECT customer_id,
       product_name
FROM pre_membership_purchases
WHERE recency_rank = 1;
```

| customer\_id | product\_name |
| ------------ | ------------- |
| A            | sushi         |
| B            | sushi         |

<a id="a8"></a>
#### A8. What is the total items and amount spent for each member before they became a member?

```sql
SELECT s.customer_id,
       COUNT(*)     AS total_items,
       SUM(m.price) AS total_amount
FROM sales s
         INNER JOIN
     members mb ON s.customer_id = mb.customer_id
         INNER JOIN
     menu m ON s.product_id = m.product_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;
```

| customer\_id | total\_items | total\_amount |
| ------------ | ------------ | ------------- |
| A            | 2            | 25            |
| B            | 3            | 40            |

<a id="a9"></a>
#### A9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
> 💬 **Note**: *since the question doesn't specify eligibility criteria, I interpreted points as valid only for purchases made after membership enrollment.*


```sql
WITH customer_points AS (SELECT s.customer_id,
                                m.price * 10 * CASE
                                                   WHEN m.product_id = 1 THEN 2
                                                   ELSE 1
                                    END AS points
                         FROM sales s
                                  LEFT JOIN
                              menu m ON s.product_id = m.product_id
                                  LEFT JOIN
                              members mb ON s.customer_id = mb.customer_id
                         WHERE mb.join_date IS NOT NULL
                           AND s.order_date >= mb.join_date)

SELECT customer_id,
       SUM(points) AS total_points
FROM customer_points
GROUP BY customer_id
ORDER BY total_points DESC;
```

| customer\_id | total\_points |
| ------------ | ------------- |
| A            | 510           |
| B            | 440           |

<a id="a10"></a>
#### A10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi – how many points do customer A and B have at the end of January?
> 💬 **Note**: *since the question doesn't specify eligibility criteria, I interpreted points as valid only for purchases made after membership enrollment.*

```sql
WITH customer_points AS (SELECT s.customer_id,
                                s.order_date,
                                mb.join_date,
                                m.product_id,
                                CASE
                                    WHEN s.order_date BETWEEN mb.join_date AND mb.join_date + 6 THEN m.price * 10 * 2
                                    ELSE m.price * 10 * CASE
                                                            WHEN m.product_id = 1 THEN 2
                                                            ELSE 1
                                        END
                                    END AS points
                         FROM sales s
                                  INNER JOIN
                              menu m ON s.product_id = m.product_id
                                  INNER JOIN
                              members mb ON s.customer_id = mb.customer_id
                         WHERE s.order_date >= mb.join_date
                           AND s.order_date BETWEEN '2021-01-01' AND '2021-01-31'
                           AND s.customer_id IN ('A', 'B'))

SELECT customer_id,
       SUM(points) AS total_points
FROM customer_points
GROUP BY customer_id
ORDER BY total_points DESC;
```

| customer\_id | total\_points |
| ------------ | ------------- |
| A            | 1020          |
| B            | 320           |


<a id="b1"></a>
#### B1. Create a table with `customer_id`, `order_date`, `product_name`, `price`, `member` (Y/N).

```sql
SELECT s.customer_id,
       s.order_date,
       m.product_name,
       m.price,
       CASE
           WHEN mb.join_date IS NOT NULL AND s.order_date >= mb.join_date THEN 'Y'
           ELSE 'N'
           END AS member
FROM sales s
         LEFT JOIN menu m ON s.product_id = m.product_id
         LEFT JOIN members mb ON s.customer_id = mb.customer_id
ORDER BY s.customer_id, s.order_date;
```

| customer_id | order_date | product_name | price | member |
|-------------|------------|--------------|-------|--------|
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

<a id="b2"></a>
#### B2. Ranking of products purchased by each customer after they became a member, showing `NULL` ranking values for non-member purchases


```sql
SELECT s.customer_id,
       s.order_date,
       m.product_name,
       m.price,
       CASE
           WHEN mb.join_date IS NOT NULL AND s.order_date >= mb.join_date THEN 'Y'
           ELSE 'N'
           END AS member,
       CASE
           WHEN mb.join_date IS NOT NULL AND s.order_date >= mb.join_date THEN
                       RANK() OVER (PARTITION BY s.customer_id,
                   CASE
                       WHEN mb.join_date IS NOT NULL AND s.order_date >= mb.join_date THEN 1
                       ELSE 0
                       END
                   ORDER BY s.order_date)
           END AS ranking
FROM sales s
         LEFT JOIN menu m ON s.product_id = m.product_id
         LEFT JOIN members mb ON s.customer_id = mb.customer_id
ORDER BY s.customer_id, s.order_date;
```

| customer_id | order_date | product_name | price | member | ranking |
|-------------|------------|--------------|-------|--------|---------|
| A           | 2021-01-01 | sushi        | 10    | N      | NULL    |
| A           | 2021-01-01 | curry        | 15    | N      | NULL    |
| A           | 2021-01-07 | curry        | 15    | Y      | 1       |
| A           | 2021-01-10 | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01 | curry        | 15    | N      | NULL    |
| B           | 2021-01-02 | curry        | 15    | N      | NULL    |
| B           | 2021-01-04 | sushi        | 10    | N      | NULL    |
| B           | 2021-01-11 | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16 | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01 | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01 | ramen        | 12    | N      | NULL    |
| C           | 2021-01-01 | ramen        | 12    | N      | NULL    |
| C           | 2021-01-07 | ramen        | 12    | N      | NULL    |

---
***Thanks for reading this far!** If you found it useful, consider giving it a ⭐️.* 

### 🏃🏻‍♂️‍➡️ *Go to the next case!*

<div align="center"><a href="https://github.com/pedropalmier/8-week-sql-challenge/tree/c14d132358e554ad11fa196c3434e1e784f23e9d/case02_pizza_runner"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/hero_images/hero_pizza_runner.png"  style="width:50%; height:50%;"></a></div>

---
© ***Pedro Palmier** – São Paulo, Winter 2025.*



