# 🏦 Case Study #4 – Data Bank
<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/hero_images/hero_data_bank.png" width=60% height=60%>

## 💎 Business Context 
Danny launched Data Bank, a digital-only bank that links customer account balances to secure distributed data storage limits. See the original case study [here](https://8weeksqlchallenge.com/case-study-4/).


## ⚡️Problem Statement
Danny needs help to analyze customer and storage data to forecast demand and support business growth. He and the Data Bank team prepared this entity relationship diagram. See the original schema [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/c0aa498043bdfefe8207e5d8771ed2fdd1388aa9/case04_data_bank/schema.sql).

<p align="center"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/ERDs/ERD_data_bank_preview.png" width=80% height=80% >



## ❓Case Study Questions
### Section A: Customer Nodes Exploration
1. [How many unique nodes are there on the Data Bank system?](#a1)
2. [What is the number of nodes per region?](#a2)
3. [How many customers are allocated to each region?](#a3)
4. [How many days on average are customers reallocated to a different node?](#a4)
5. [What is the median, 80th and 95th percentile for this same reallocation days metric for each region?](#a5)

### Section B: Customer Transactions
1. [What is the unique count and total amount for each transaction type?](#b1)
2. [What is the average total historical deposit counts and amounts for all customers?](#b2)
3. [For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?](#b3)
4. [What is the closing balance for each customer at the end of the month?](#b4)
5. [What is the percentage of customers who increase their closing balance by more than 5%?](#b5)


## 🎯 My Solution
*View the complete syntax [here](https://github.com/pedropalmier/8-week-sql-challenge/blob/c0aa498043bdfefe8207e5d8771ed2fdd1388aa9/case04_data_bank/solution.sql).*

### Section A: Customer Nodes Exploration

<a id="a1"></a>
#### A1: How many unique nodes are there on the Data Bank system?


```sql
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;
```

| unique\_nodes |
| :--- |
| 5 |


<a id="a2"></a>
#### A2: What is the number of nodes per region?

> 💬 **Note**
> - Number of nodes *is ambiguous. It can mean total assignments (`COUNT`) or unique nodes per region (`COUNT DISTINCT`). This query counts total assignments, but `COUNT(DISTINCT node_id)` may be more accurate for active infrastructure analysis.*

```sql
SELECT region_id, COUNT(DISTINCT node_id) AS nodes_count
FROM customer_nodes
GROUP BY region_id
ORDER BY nodes_count DESC;
```

| region\_id | nodes\_count |
| :--- | :--- |
| 1 | 5 |
| 2 | 5 |
| 3 | 5 |
| 4 | 5 |
| 5 | 5 |


<a id="a3"></a>
#### A3: How many customers are allocated to each region?

```sql
SELECT r.region_name,
       COUNT(DISTINCT customer_id) AS customer_count
FROM customer_nodes c
         INNER JOIN regions r ON r.region_id = c.region_id
GROUP BY r.region_name
ORDER BY customer_count DESC;
```

| region\_name | customer\_count |
| :--- | :--- |
| Australia | 110 |
| America | 105 |
| Africa | 102 |
| Asia | 95 |
| Europe | 88 |


<a id="a4"></a>
#### A4: How many days on average are customers reallocated to a different node?

> 💬 **Note**
> - *The dataset uses `9999-12-31` to represent an open allocation (still active). Although not explicit in the case text, this interpretation was assumed for the calculation.*

```sql
WITH node_days AS (SELECT c2.customer_id,
                          node_id,
                          (c2.end_date - c2.start_date) AS days_in_node
                   FROM customer_nodes c2
                   WHERE c2.end_date != '9999-12-31'),

     total_node_days AS (SELECT customer_id,
                                node_id,
                                SUM(days_in_node) as total_days
                         FROM node_days
                         GROUP BY customer_id, node_id)

SELECT ROUND(AVG(total_days), 0) AS avg_days_in_node
FROM total_node_days;
```

| avg\_days\_in\_node |
| :--- |
| 24 |


<a id="a5"></a>
#### A5: What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

```sql
WITH region_days AS (SELECT region_id,
                            (end_date - start_date) AS days_in_node
                     FROM customer_nodes
                     WHERE end_date != '9999-12-31')

SELECT rd.region_id,
       r.region_name,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_in_node)  AS median,
       PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY days_in_node)  AS p80,
       PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY days_in_node) AS p95
FROM region_days rd
         INNER JOIN regions r ON rd.region_id = r.region_id
GROUP BY rd.region_id, r.region_name;
```

| region\_id | region\_name | median | p80 | p95 |
| :--- | :--- | :--- | :--- | :--- |
| 1 | Australia | 15 | 23 | 28 |
| 2 | America | 15 | 23 | 28 |
| 3 | Africa | 15 | 24 | 28 |
| 4 | Asia | 15 | 23 | 28 |
| 5 | Europe | 15 | 24 | 28 |

---
### Section B: Customer Transactions

<a id="b1"></a>
#### B1: What is the unique count and total amount for each transaction type?

```sql
SELECT ct.txn_type,
       COUNT(ct.txn_type) AS unique_count,
       SUM(ct.txn_amount) AS total_amount
FROM customer_transactions ct
GROUP BY ct.txn_type
ORDER BY SUM(ct.txn_amount) DESC;
```

| txn\_type | unique\_count | total\_amount |
| :--- | :--- | :--- |
| deposit | 2671 | 1359168 |
| purchase | 1617 | 806537 |
| withdrawal | 1580 | 793003 |


<a id="b2"></a>
#### B2: What is the average total historical deposit counts and amounts for all customers?

```sql
WITH total_deposits AS (SELECT ct.customer_id,
                               COUNT(ct.txn_type) AS unique_count,
                               SUM(ct.txn_amount) AS total_amount
                        FROM customer_transactions ct
                        WHERE ct.txn_type = 'deposit'
                        GROUP BY ct.customer_id)

SELECT ROUND(AVG(unique_count), 0) AS avg_total_deposit,
       ROUND(AVG(total_amount), 2) AS avg_total_amount
FROM total_deposits;
```

| avg\_total\_deposit | avg\_total\_amount |
| :--- | :--- |
| 5 | 2718.34 |


<a id="b3"></a>
#### B3: For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?


```sql
WITH txn_count AS (SELECT DATE_TRUNC('month', txn_date)                              AS month_date,
                          TRIM(TO_CHAR(DATE_TRUNC('month', txn_date), 'YYYY Month')) AS month,
                          customer_id,
                          SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END)      AS deposit_count,
                          SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END)     AS purchase_count,
                          SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END)   AS withdrawal_count
                   FROM customer_transactions
                   GROUP BY DATE_TRUNC('month', txn_date), customer_id)

SELECT month,
       COUNT(customer_id)
FROM txn_count
WHERE deposit_count > 1
  AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY month, month_date
ORDER BY month_date;
```

| month | count |
| :--- | :--- |
| 2020 January | 168 |
| 2020 February | 181 |
| 2020 March | 192 |
| 2020 April | 70 |

<a id="b4"></a>
#### B4: What is the closing balance for each customer at the end of the month?


```sql
WITH txn_count AS (SELECT customer_id,
                          DATE_TRUNC('month', txn_date)                                                  AS month_date,
                          TRIM(TO_CHAR(DATE_TRUNC('month', txn_date), 'YYYY Month'))                     AS month,
                          SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE txn_amount * (-1) END) AS transactions

                   FROM customer_transactions
                   GROUP BY DATE_TRUNC('month', txn_date), customer_id)

SELECT customer_id,
       month,
       SUM(transactions) OVER (PARTITION BY customer_id ORDER BY month_date) AS closing_balance
FROM txn_count
ORDER BY customer_id, month_date;
```

| customer\_id | month | closing\_balance |
| :--- | :--- | :--- |
| 1 | 2020 January | 312 |
| 1 | 2020 March | -640 |
| 2 | 2020 January | 549 |
| 2 | 2020 March | 610 |
| 3 | 2020 January | 144 |
| 3 | 2020 February | -821 |
| 3 | 2020 March | -1222 |
| 3 | 2020 April | -729 |
| 4 | 2020 January | 848 |
| 4 | 2020 March | 655 |
| 5 | 2020 January | 954 |
| 5 | 2020 March | -1923 |
| 5 | 2020 April | -2413 |
| … | … | … |

<a id="b5"></a>
#### B5: What is the percentage of customers who increase their closing balance by more than 5%?

> 💬 **Note**
> - *MoM comparison on `closing_balance`.*
> - *Denominator = customers with at least one valid `prev_balance` > `0`.*

```sql
WITH txn_count AS (SELECT customer_id,
                          DATE_TRUNC('month', txn_date)                                                  AS month_date,
                          SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE txn_amount * (-1) END) AS transactions
                   FROM customer_transactions
                   GROUP BY customer_id, DATE_TRUNC('month', txn_date)),

     closing_balance AS (SELECT customer_id,
                                month_date,
                                SUM(transactions) OVER (PARTITION BY customer_id ORDER BY month_date) AS closing_balance
                         FROM txn_count),

     variation AS (SELECT customer_id,
                          month_date,
                          closing_balance,
                          LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month_date) AS prev_balance
                   FROM closing_balance),

     stats AS (SELECT COUNT(DISTINCT customer_id)
                      FILTER (WHERE prev_balance > 0 AND (closing_balance - prev_balance) / prev_balance > 0.05) AS qualified,
                      COUNT(DISTINCT customer_id) FILTER (WHERE prev_balance > 0)                                AS eligible
               FROM variation)

SELECT ROUND(100.0 * qualified::numeric / NULLIF(eligible, 0), 2) AS pct_customers_increase_over_5
FROM stats;
```

| pct\_customers\_increase\_over\_5 |
| :--- |
| 48.43 |


***Thanks for reading this far!*** *If you found it useful, consider giving it a* ⭐️. 

---

### 🏃🏻‍♂️‍➡️ Go to the next case!

<div align="center"><a href="https://github.com/pedropalmier/8-week-sql-challenge/tree/855582d1225e335646ff754feb701adaed39602f/case05_data_mart"><img src="https://default-pedro.s3.us-east-2.amazonaws.com/8weekschallenge/hero_images/hero_data_mart.png"  style="width:50%; height:50%;"></a></div>

---
© ***Pedro Palmier** – São Paulo, Winter 2025.*