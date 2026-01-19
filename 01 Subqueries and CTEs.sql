-- Databricks notebook source
---------------------
-- Basic joins

SELECT p.product_id, p.product_name, o.product_id AS product_id_in_orders
FROM products p
  LEFT JOIN orders o
    ON p.product_id = o.product_id
WHERE o.product_id IS NULL;

-- COMMAND ----------

---------------------
-- Self joins

SELECT
  p1.product_name,
  p1.unit_price,
  p2.product_name,
  p2.unit_price,
  p1.unit_price - p2.unit_price AS price_diff
FROM products p1 CROSS JOIN products p2
WHERE
  ABS(p1.unit_price - p2.unit_price) < 0.25
  AND p1.product_name < p2.product_name
ORDER BY price_diff DESC;

-- COMMAND ----------

---------------------
-- Subqueries in the SELECT clause

SELECT
  product_id,
  product_name,
  unit_price,
  unit_price - (SELECT AVG(unit_price) FROM products) AS diff_price,
  (SELECT AVG(unit_price) FROM products) AS avg_unit_price
FROM products
ORDER BY unit_price DESC;

-- COMMAND ----------

---------------------
-- Subqueries in the FROM clause

SELECT
  p.factory,
  p.product_name,
  sub.num_products
FROM products p
  INNER JOIN (SELECT factory, COUNT(product_name) AS num_products FROM products GROUP BY factory) sub
    ON p.factory = sub.factory;

-- COMMAND ----------

---------------------
-- Subqueries in the WHERE clause

SELECT product_id, product_name,  factory, division, unit_price
FROM products
WHERE unit_price < (SELECT MIN(unit_price) FROM products WHERE factory LIKE 'Wicked Choccys');

-- COMMAND ----------

---------------------
-- CTEs

WITH oitas AS (
  SELECT order_id, SUM((
        SELECT unit_price
        FROM products
        WHERE product_id = o.product_id
        LIMIT 1
      ) * units
    ) AS total_amount_spent
  FROM orders o
  GROUP BY order_id
)
SELECT COUNT(*)
FROM oitas
WHERE total_amount_spent > 200;

-- COMMAND ----------

---------------------
-- Multiple CTEs

WITH 
  fp AS (
    SELECT factory, product_name
    FROM products
  ),
  sub AS (
  SELECT factory, COUNT(product_name) AS num_products 
  FROM products 
  GROUP BY factory
)
SELECT fp.factory, fp.product_name, sub.num_products 
FROM fp INNER JOIN  sub
  ON fp.factory = sub.factory;
