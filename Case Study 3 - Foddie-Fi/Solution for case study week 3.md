# Case Study #3 - Foodie-Fi


<img src="https://8weeksqlchallenge.com/images/case-study-designs/3.png" alt="Mo ta anh" width="700" height="800">

# Introduction

Subscription based businesses are super popular and Danny realised that there was a large gap in the market - he wanted to create a new streaming service that only had food related content - something like Netflix but with only cooking shows!

Danny finds a few smart friends to launch his new startup Foodie-Fi in 2020 and started selling monthly and annual subscriptions, giving their customers unlimited on-demand access to exclusive food videos from around the world!

Danny created Foodie-Fi with a data driven mindset and wanted to ensure all future investment decisions and new features were decided using data. This case study focuses on using subscription style digital data to answer important business questions.

# Available Data

Danny has shared the data design for `Foodie-Fi` and also short descriptions on each of the database tables - our case study focuses on only 2 tables but there will be a challenge to create a new table for the Foodie-Fi team.

All datasets exist within the `foodie_fi` database schema - be sure to include this reference within your SQL scripts as you start exploring the data and answering the case study questions.

# Questions and solutions


```python

```

# B. Data Analysis Questions

### 1. How many customers has Foodie-Fi ever had?

```sql
SELECT COUNT( distinct customer_id) AS total_customer
FROM subscriptions
```

**Result**

|total_customer|
|:-|
|1000|

### 2. What is the monthly distribution of `trial` plan `start_date` values for our dataset - use the start of the 
### month as the group by value

```sql 
SELECT 
    MONTH(start_date) as Month ,
    COUNT( customer_id) as Total_cus
FROM subscriptions
WHERE plan_id = 0
    GROUP BY MONTH(start_date)
    ORDER BY MONTH(start_date)
```

**Result**

| Month | Total_cus |
|:---------|:---------|
| 1        | 88       |
| 2        | 68       |
| 3        | 94       |
| 4        | 81       |
| 5        | 88       |
| 6        | 79       |
| 7        | 89       |
| 8        | 88       |
| 9        | 87       |
| 10       | 79       |
| 11       | 75       |
| 12       | 84       |


### 3. What plan `start_date` values occur after the year 2020 for our dataset? Show the breakdown by count of 
### events for each `plan_name`

```sql
SELECT plan_name, 
    COUNT(start_date) as Total_event
FROM plans 
LEFT JOIN subscriptions as sub 
ON plans.plan_id = sub.plan_id
WHERE YEAR(start_date) > 2020
    GROUP BY plan_name
    ORDER BY plan_name 
```

**Result**

| plan_name        | Total_event |
|:--------------|:------|
| basic monthly  | 8     |
| churn          | 71    |
| pro annual     | 63    |
| pro monthly    | 60    |


### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

```sql 
SELECT 
    COUNT(sub.customer_id) AS total_customers,
    FORMAT((COUNT(sub.customer_id)*1.0) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 'p') AS ratio
FROM subscriptions AS sub
LEFT JOIN plans 
ON sub.plan_id = plans.plan_id
WHERE sub.plan_id = 4
```

**Result**

|total_customers|ratio|
|:--|:--|
|307|30.70%|

### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

**Method 1**

```sql 
WITH TABLEA AS (
    SELECT 
        customer_id, 
        plan_name,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS rn
    FROM subscriptions AS sub
    LEFT JOIN plans 
    ON sub.plan_id = plans.plan_id), 
Churn_table AS (
    SELECT  
        SUM(CASE WHEN plan_name = 'churn' AND rn = 2 THEN 1 ELSE 0 END) AS churn_count 
    FROM TABLEA
) 
SELECT *, 
    FORMAT(churn_count * 1.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 'p') AS pct
FROM Churn_table;
```

**Method 2**

```sql
WITH TABLE1 AS (
    SELECT 
        customer_id, 
        plan_name, 
        LEAD(plan_name) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan
    FROM subscriptions AS sub
    LEFT JOIN plans 
    ON sub.plan_id = plans.plan_id
) 
SELECT COUNT(customer_id) AS churn_count, 
    FORMAT(COUNT(customer_id) * 1.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 'p') AS pct 
FROM TABLE1
WHERE (plan_name ='trial') AND (next_plan='churn');

```

**Result**

| churn_count | ptc|
|:-------|:-----------|
| 92     | 9.20%      |


### 6. What is the number and percentage of customer plans after their initial free trial?

```sql 
WITH LEAD_TABEL AS (
    SELECT 
        customer_id,
        plan_id, 
        LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan
    FROM subscriptions
)
SELECT 
    next_plan, 
    COUNT(*) AS count_plan, 
    FORMAT(COUNT(*) * 1.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 'p') AS pct
FROM LEAD_TABEL 
WHERE plan_id = 0
GROUP BY next_plan
ORDER BY next_plan
```

**Result**

| next_plan | count_plan | ptc|
|:-------|:------|:-----------|
| 1      | 546   | 54.60%     |
| 2      | 325   | 32.50%     |
| 3      | 37    | 3.70%      |
| 4      | 92    | 9.20%      |


### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

```sql 
WITH next_dates AS (
  SELECT
    customer_id,
    plan_id,
    start_date,
    LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_date
  FROM subscriptions
  WHERE start_date <= '2020-12-31')
SELECT
	plan_id, 
	COUNT(DISTINCT customer_id) AS customers,
	FORMAT(1.0*COUNT(DISTINCT customer_id)/ (SELECT COUNT(DISTINCT customer_id)FROM subscriptions),'p')  AS percentage
FROM next_dates
WHERE next_date IS NULL
GROUP BY plan_id
```

**Result**

| plan_id| customers | percentage |
|:-------|:-------|:------------|
| 0      | 19    | 1.90%      |
| 1      | 224   | 22.40%     |
| 2      | 326   | 32.60%     |
| 3      | 195   | 19.50%     |
| 4      | 236   | 23.60%     |


### 8. How many customers have upgraded to an annual plan in 2020?

```sql
SELECT COUNT(*) AS Count_customer
FROM subscriptions
WHERE YEAR(start_date) = 2020 and
plan_id = 3
```

**Result**

|Count_customer|
|:-|
|195|

### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

```sql 
WITH date_table as (
SELECT customer_id, 
    plan_id, 
    start_date, 
    LEAD(start_date) OVER (PARTITION BY customer_id Order by start_date) as after_date
FROM subscriptions
WHERE plan_id = 0 or plan_id = 3)
SELECT AVG(DATEDIFF(day,start_date, after_date)) as avg_day 
FROM date_table 
```

**Result**

|avg_day|
|:-|
|104|

### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

```sql
WITH date_table AS (
    SELECT 
        customer_id, 
        plan_id, 
        start_date, 
        LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS after_date
    FROM subscriptions
    WHERE plan_id = 0 OR plan_id = 3), 
diff_table AS (
    SELECT 
        customer_id, 
        plan_id, 
        DATEDIFF(day, start_date, after_date) AS daydiff
    FROM date_table
    WHERE DATEDIFF(day, start_date, after_date) IS NOT NULL),
bin_table AS (
    SELECT 
        CASE 
            WHEN daydiff <= 30 THEN '0-30 days' 
            WHEN daydiff <= 60 THEN '31-60 days'
            WHEN daydiff <= 90 THEN '61-90 days'
            WHEN daydiff <= 120 THEN '91-120 days'
            WHEN daydiff <= 150 THEN '121-150 days'
            WHEN daydiff <= 180 THEN '151-180 days'
            WHEN daydiff <= 210 THEN '181-210 days'
            WHEN daydiff <= 240 THEN '211-240 days'
            WHEN daydiff <= 270 THEN '241-270 days'
            WHEN daydiff <= 300 THEN '271-300 days'
            WHEN daydiff <= 330 THEN '301-330 days'
            WHEN daydiff <= 360 THEN '331-360 days'
        END AS Bins
    FROM 
        diff_table) 
SELECT 
    Bins,  
    COUNT(*) AS Count 
FROM bin_table
GROUP BY Bins
ORDER BY Bins
```

**Result**

| Bins      | Count|
|:-------------|:------|
| 0-30 days    | 49    |
| 31-60 days   | 24    |
| 61-90 days   | 34    |
| 91-120 days  | 35    |
| 121-150 days | 42    |
| 151-180 days | 36    |
| 181-210 days | 26    |
| 211-240 days | 4     |
| 241-270 days | 5     |
| 271-300 days | 1     |
| 301-330 days | 1     |
| 331-360 days | 1     |


### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

```sql
WITH next_plan AS (
SELECT  customer_id , plan_id ,
        LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS  next_plan_id
FROM subscriptions) 
SELECT * 
FROM next_plan
WHERE plan_id=2 and next_plan_id=1 
```

**Result**

In 2020, there were no instances where customers downgraded from a pro monthly plan to a basic monthly plan.



```python

```
