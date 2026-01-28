-- Databricks notebook source
-- MAGIC %md
-- MAGIC III. Functions By Data Type

-- COMMAND ----------

-- Numeric functions

WITH 
  tot_spend_p_customer AS (
    SELECT customer_id, SUM(units * unit_price) AS total_spend
    FROM orders LEFT JOIN products ON orders.product_id = products.product_id
    GROUP BY customer_id
  )
SELECT FLOOR(total_spend / 10) * 10 AS total_spend_bin, COUNT(*) AS num_customers
FROM tot_spend_p_customer
GROUP BY total_spend_bin
ORDER BY total_spend_bin;

-- COMMAND ----------

-- Datetime functions

SELECT order_id, order_date, 
  DATE_ADD(order_date, 2) AS ship_date
FROM orders
WHERE YEAR(order_date) = 2024
  AND MONTH(order_date) BETWEEN 4 AND 6;

-- COMMAND ----------

-- String functions

SELECT factory, product_id, 
  CONCAT(REPLACE(factory, ' ', '-'), '-', product_id) AS factory_product_id 
FROM products;

-- COMMAND ----------

-- Pattern matching

SELECT product_name,
  REPLACE(product_name, 'Wonka Bar - ' ) AS new_product_name
FROM products;

-- COMMAND ----------

-- NULL functions

WITH 
  num_prod_per_fact AS (
    SELECT factory, division,
      COUNT(*) AS num_products
    FROM products
    GROUP BY factory, division
  ),
  max_per_fact AS (
    SELECT factory, division, num_products,
      MAX(num_products) OVER (PARTITION BY factory) AS max_num_products
    FROM num_prod_per_fact
    WHERE division IS NOT NULL
  ),
  mode_per_fact AS (
    SELECT factory, division
    FROM max_per_fact
    WHERE num_products = max_num_products
  )
SELECT p.product_name, p.factory, p.division,
  COALESCE(p.division, 'Other') AS division_other,
  COALESCE(p.division, mpf.division) AS division_top
FROM products p LEFT JOIN mode_per_fact mpf ON p.factory = mpf.factory;
