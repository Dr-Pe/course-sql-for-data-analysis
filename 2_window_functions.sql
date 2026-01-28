-- Databricks notebook source
-- MAGIC %md
-- MAGIC II. Window Functions

-- COMMAND ----------

-- Window functions

SELECT customer_id, order_id, order_date, transaction_id,
  ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY transaction_id) AS transaction_number
FROM orders;

-- COMMAND ----------

-- Row numbering

SELECT order_id, product_id, units,
  DENSE_RANK() OVER(PARTITION BY order_id ORDER BY units DESC) AS product_rank
FROM orders
ORDER BY order_id, product_rank;

-- COMMAND ----------

-- Value within a window

SELECT order_id, product_id, units
FROM (
  SELECT order_id, product_id, units,
    DENSE_RANK() OVER(PARTITION BY order_id ORDER BY units DESC) AS dense_rank
  FROM orders
)
WHERE dense_rank = 2;

-- COMMAND ----------

-- Value relative to a row

WITH cot_orders AS (
  SELECT customer_id, order_id, SUM(units) AS total_units, MIN(transaction_id) AS min_tid
  FROM orders
  GROUP BY customer_id, order_id
)
SELECT customer_id, order_id, total_units,
  LAG(total_units) OVER(PARTITION BY customer_id ORDER BY min_tid) AS prior_units,
  total_units - prior_units AS diff_units
FROM cot_orders;

-- COMMAND ----------

-- Statistical functions

WITH 
  tot_spend_p_customer AS (
    SELECT customer_id, SUM(units * unit_price) AS total_spend
    FROM orders LEFT JOIN products ON orders.product_id = products.product_id
    GROUP BY customer_id
  ),
  spending_pcts AS (
    SELECT customer_id, total_spend,
    NTILE(100) OVER(ORDER BY total_spend DESC) AS spend_pct
  FROM tot_spend_p_customer
  )
SELECT customer_id, total_spend, spend_pct
FROM spending_pcts
WHERE spend_pct = 1;
