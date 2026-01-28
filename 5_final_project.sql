-- Databricks notebook source
-- MAGIC %md
-- MAGIC # V. Final Project

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## School analysis

-- COMMAND ----------

-- a) In each decade, how many schools were there that produced MLB players?

SELECT FLOOR(yearID / 10) * 10 AS decade,
  COUNT(schoolID) AS num_schools
FROM schools
GROUP BY decade
ORDER BY decade;

-- COMMAND ----------

-- b) What are the names of the top 5 schools that produced the most players?

SELECT sd.name_full, COUNT(DISTINCT playerID) AS num_players
FROM schools s
  LEFT JOIN school_details sd ON s.schoolID = sd.schoolID
GROUP BY sd.name_full
ORDER BY num_players DESC
LIMIT 5;

-- COMMAND ----------

-- c) For each decade, what were the names of the top 3 schools that produced the most players?

WITH 
  plyrs_schl_dcd AS (
    SELECT FLOOR(yearID / 10) * 10 AS decade, 
      schoolID, 
      COUNT(DISTINCT playerID) AS num_players
    FROM schools
    GROUP BY decade, schoolID
  ),
  schls_dcd_rn AS (
    SELECT decade, 
      ROW_NUMBER() OVER (PARTITION BY decade ORDER BY num_players DESC) AS rn,
      CASE WHEN rn = 1 THEN name_full END AS fst_school,
      CASE WHEN rn = 2 THEN name_full END AS snd_school,
      CASE WHEN rn = 3 THEN name_full END AS trd_school
    FROM plyrs_schl_dcd
      LEFT JOIN school_details ON plyrs_schl_dcd.schoolID = school_details.schoolID
  )
  SELECT decade,
    MAX(fst_school) AS first_school, 
    MAX(snd_school) AS second_school, 
    MAX(trd_school) AS third_school
  FROM schls_dcd_rn
  GROUP BY decade
  ORDER BY decade;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Salary Analysis

-- COMMAND ----------

-- a) Return the top 20% of teams in terms of average annual spending

WITH
  teams_annual_total_spending AS (
    SELECT teamID, SUM(salary) AS total_annual_spending
    FROM salaries
    GROUP BY teamID, yearID
  ),
  teams_avg_annual_spending AS (
    SELECT teamID, 
      AVG(total_annual_spending) AS avg_annual_spending
    FROM teams_annual_total_spending
    GROUP BY teamID
  ),
  teams_avg_annual_spending_pct AS (
    SELECT teamID, avg_annual_spending,
      NTILE(5) OVER (ORDER BY avg_annual_spending DESC) AS percentile
    FROM teams_avg_annual_spending
  )
SELECT teamID, 
  ROUND(avg_annual_spending / 1000000, 1) AS avg_annual_spending_million_dollars
FROM teams_avg_annual_spending_pct
WHERE percentile = 1
ORDER BY avg_annual_spending DESC;

-- COMMAND ----------

-- b) For each team, show the cumulative sum of spending over the years

WITH yearly_annual_spending AS (
  SELECT yearID AS year, teamID, 
    SUM(salary) AS annual_spending
  FROM salaries
  GROUP BY yearID, teamID
)
SELECT teamID, year,
  ROUND(SUM(annual_spending) OVER(
    PARTITION BY teamID ORDER BY year
  ) / 1000000, 1) AS cumulative_sum_yearly_spending_million_dollars
FROM yearly_annual_spending
ORDER BY teamID, year;

-- COMMAND ----------

-- c) Return the first year that each team's cumulative spending surpassed 1 billion

WITH 
  yearly_annual_spending AS (
    SELECT yearID, teamID,
      SUM(SUM(salary)) OVER(
        PARTITION BY teamID ORDER BY yearID
      ) AS cumulative_sum_yearly_spending
    FROM salaries
    GROUP BY yearID, teamID
  ),
  yearly_annual_spending_rn AS (
    SELECT *,
      ROW_NUMBER() OVER(PARTITION BY teamID ORDER BY yearID) AS rn
    FROM yearly_annual_spending
    WHERE cumulative_sum_yearly_spending > 1000000000
  )
  SELECT teamID, yearID AS year, 
    ROUND(
      cumulative_sum_yearly_spending / 1000000000, 2
    ) AS cumulative_sum_yearly_spending_billion_dollars
  FROM yearly_annual_spending_rn
  WHERE rn = 1
  ORDER BY teamID;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Player Career Analysis

-- COMMAND ----------

-- a) For each player, calculate their age at their first (debut) game, their last game, and their career length (all in years). 
-- Sort from longest career to shortest career.

WITH player_date_highs AS (
  SELECT playerID, nameGiven, debut, finalGame,
    DATE(CONCAT(birthYear, '-', birthMonth, '-', birthDay)) AS dof
  FROM players
)
SELECT nameGiven, 
  DATEDIFF(YEAR, dof, debut) AS debut_age,
  DATEDIFF(YEAR, dof, finalGame) AS final_game_age,
  DATEDIFF(YEAR, debut, finalGame) AS career_length
FROM player_date_highs
WHERE dof IS NOT NULL AND debut IS NOT NULL
ORDER BY career_length DESC;

-- COMMAND ----------

-- b) What team did each player play on for their starting and ending years?

SELECT p.playerID, nameGiven, 
  s1.teamID AS start_teamID, s2.teamID AS end_teamID
FROM players p
  INNER JOIN salaries s1 ON YEAR(p.debut) = s1.yearID AND p.playerID = s1.playerID
  LEFT JOIN salaries s2 ON YEAR(p.finalGame) = s2.yearID AND p.playerID = s2.playerID
ORDER BY nameGiven;

-- COMMAND ----------

-- c) How many players started and ended on the same team and also played for over a decade?

SELECT COUNT(*)
FROM players p
LEFT JOIN salaries s1 ON YEAR(p.debut) = s1.yearID AND p.playerID = s1.playerID
LEFT JOIN salaries s2 ON YEAR(p.finalGame) = s2.yearID AND p.playerID = s2.playerID
WHERE s1.teamID = s2.teamID AND DATEDIFF(YEAR, debut, finalGame) >= 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Player Comparison Analysis

-- COMMAND ----------

-- a) Which players have the same birthday?

SELECT birthDay, birthMonth, 
  LISTAGG(nameGiven, ', ') AS players
FROM players
WHERE birthDay IS NOT NULL AND birthMonth IS NOT NULL
GROUP BY birthDay, birthMonth
ORDER BY birthDay;

-- COMMAND ----------

-- b) Create a summary table that shows for each team, what percent of players bat right, left and both.

SELECT teamID,
  ROUND(SUM((CASE WHEN bats = 'R' THEN 1 END)) / COUNT(bats) * 100) AS right,
  ROUND(SUM((CASE WHEN bats = 'L' THEN 1 END)) / COUNT(bats) * 100) AS left,
  ROUND(SUM((CASE WHEN bats = 'B' THEN 1 END)) / COUNT(bats) * 100) AS both
FROM players p
  INNER JOIN salaries s ON p.playerID = s.playerID
GROUP BY teamID
ORDER BY teamID;

-- COMMAND ----------

-- c) How have average height and weight at debut game changed over the years, and what's the decade-over-decade difference?

WITH avg_w_h_at_debut (
  SELECT FLOOR(YEAR(debut) / 10) * 10 AS decade, 
    ROUND(AVG(weight)) AS avg_weight,
    ROUND(AVG(height)) AS avg_height
  FROM players
  WHERE debut IS NOT NULL
  GROUP BY decade
)
SELECT *,
  avg_weight - LAG(avg_weight) OVER (ORDER BY decade) AS decade_diff_weight,
  avg_height - LAG(avg_height) OVER (ORDER BY decade) AS decade_diff_height
FROM avg_w_h_at_debut
ORDER BY decade;
