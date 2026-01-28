-- Databricks notebook source
-- MAGIC %md
-- MAGIC IV. Data Analysis Applications

-- COMMAND ----------

-- Duplicate values

SELECT id, student_name, email
FROM (
  SELECT *,
  ROW_NUMBER() OVER(PARTITION BY student_name ORDER BY id DESC) AS top_latest_data
  FROM students
)
WHERE top_latest_data = 1;

-- COMMAND ----------

-- Min/max value filtering

WITH top_grades AS (
  SELECT student_id, student_name, MAX(final_grade) AS top_grade
  FROM student_grades sg
    INNER JOIN students snd ON sg.student_id = snd.id
  GROUP BY student_id, student_name
)
SELECT sg.student_id, student_name, top_grade, class_name
FROM top_grades tg
  INNER JOIN student_grades sg ON tg.student_id = sg.student_id AND tg.top_grade = sg.final_grade
ORDER BY sg.student_id

-- COMMAND ----------

-- Pivoting

SELECT department,
  ROUND(AVG(CASE WHEN grade_level = 9 THEN final_grade END)) AS freshman,
  ROUND(AVG(CASE WHEN grade_level = 10 THEN final_grade END)) AS sophomore,
  ROUND(AVG(CASE WHEN grade_level = 11 THEN final_grade END)) AS junior,
  ROUND(AVG(CASE WHEN grade_level = 12 THEN final_grade END)) AS senior
FROM student_grades sg INNER JOIN students s ON sg.student_id = s.id
GROUP BY department
ORDER BY department;

-- COMMAND ----------

-- Rolling calculations

WITH ymts AS (
  SELECT YEAR(order_date) AS yr, MONTH(order_date) AS mnth,
    SUM(units * unit_price) AS total_sales
  FROM orders o 
    LEFT JOIN products p ON o.product_id = p.product_id
  GROUP BY yr, mnth
)
SELECT *,
  SUM(total_sales) OVER(ORDER BY yr, mnth) AS cumulative_sum,
  AVG(total_sales) OVER(
    ORDER BY yr, mnth
    ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
  ) AS six_month_ma
FROM ymts
