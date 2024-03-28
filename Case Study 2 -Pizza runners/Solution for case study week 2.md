# Case Study #2 - Pizza Runner



<img src="https://8weeksqlchallenge.com/images/case-study-designs/2.png" alt="Mo ta anh" width="700" height="800">

# Introduction

Did you know that over 115 million kilograms of pizza is consumed daily worldwide??? (Well according to Wikipedia anyway…)

Danny was scrolling through his Instagram feed when something really caught his eye - “80s Retro Styling and Pizza Is The Future!”

Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire - so he had one more genius idea to combine with it - he was going to Uberize it - and so Pizza Runner was launched!

Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.

# Available Data

Because Danny had a few years of experience as a data scientist - he was very aware that data collection was going to be critical for his business’ growth.

He has prepared for us an entity relationship diagram of his database design but requires further assistance to clean his data and apply some basic calculations so he can better direct his runners and optimise Pizza Runner’s operations.

All datasets exist within the pizza_runner database schema - be sure to include this reference within your SQL scripts as you start exploring the data and answering the case study questions.

# Case Study Questions and Solutions

# Transform and cleaning data 

Based on the original `runner_orders` table, we observe that the units in the distance and duration columns are inconsistent. Therefore, we use the `UPDATE` statement to adjust the data to a consistent format by removing the units and retaining only the numeric values.

```sql
UPDATE runner_orders
SET 
distance = CASE 
                WHEN distance LIKE '%km' THEN SUBSTRING(distance, 1, CHARINDEX('km', distance) - 1)
                ELSE distance
              END,
duration = CASE 
                WHEN duration LIKE '%min%' THEN SUBSTRING(duration, 1, CHARINDEX('min', duration) - 1)
                ELSE duration
              END
```

Looking at the `runner_orders` table below, we can see that:

- In the `pickup_time` column, there are missing/blank spaces ' ' and null values.
- In the `distance`, `duration`, and `cancellation` columns, there are also missing/blank spaces ' ' and null values.

Therefore:
We will remove the 'null' values and replace them with blank '' for these columns.

```sql
UPDATE runner_orders 
SET 
    pickup_time = IIF(pickup_time = 'null', '', pickup_time),
    distance = IIF(distance = 'null', '', distance),
    duration = IIF(duration = 'null', '', duration),
    cancellation = CASE 
                        WHEN cancellation IS NULL OR cancellation = 'null' THEN ''
                        ELSE cancellation
                   END
```


Looking at the `customer_orders` table below, we can see that there are

In the `exclusions` column, there are missing/ blank spaces ' ' and null values.
In the `extras` column, there are missing/ blank spaces ' ' and null values.
Therefore: We will remove the 'null' values and replace them with blank '' for these columns.

```sql 
UPDATE customer_orders
SET 
    exclusions = CASE 
                    WHEN exclusions IS NULL OR exclusions = 'null' THEN ''
                    ELSE exclusions 
                END,
    extras = CASE 
                WHEN extras IS NULL OR extras = 'null' THEN ''
                ELSE extras 
            END
```

## A. Pizza Metrics

### 1. How many pizzas were ordered?

```sql
SELECT COUNT(*) as count_pizzas
FROM customer_orders
```

### 2.How many unique customer orders were made?

```sql 
SELECT COUNT(DISTINCT customer_id) as Customer
FROM customer_orders 
```

### 3. How many successful orders were delivered by each runner?

```sql 
SELECT runner_id, 
    COUNT(distinct co.order_id) as succes_order 
FROM customer_orders as co
LEFT JOIN runner_orders as ro
ON co.order_id=ro.order_id
WHERE cancellation ='' 
GROUP BY runner_id
```

### 4. How many of each type of pizza was delivered?

```sql 
SELECT pizza_name,
    COUNT(co.pizza_id)
FROM customer_orders AS co
LEFT JOIN pizza_names as pn
ON co.pizza_id=pn.pizza_id
JOIN runner_orders as ro
ON co.order_id=ro.order_id
WHERE cancellation ='' 
GROUP BY pizza_name
```

### 5. How many Vegetarian and Meatlovers were ordered by each customer?

```sql 
SELECT customer_id, 
pizza_name , count(pizza_name) as count_order 
FROM customer_orders as co
LEFT JOIN pizza_names as pn
ON co.pizza_id=pn.pizza_id
GROUP BY customer_id, pizza_name
ORDER BY  customer_id
```

### 6. What was the maximum number of pizzas delivered in a single order?

```sql
SELECT co.order_id, 
    COUNT(customer_id) as count_pizza
FROM customer_orders as co
JOIN runner_orders as ro
ON co.order_id = ro.order_id
WHERE cancellation=''
    GROUP BY co.order_id
    ORDER BY COUNT(customer_id) DESC
```

**Result**

| customer_id | count_pizza |
|:----------|:----------|
|    4     |    3     |
|    3     |    2     |
|    10    |    2     |
|    1     |    1     |
|    2     |    1     |
|    5     |    1     |
|    7     |    1     |
|    8     |    1     |


Based on the result, we can see that `maximum number of pizzas` deliveried in single order is 3 

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

```sql
SELECT 
  customer_id,
  SUM(
    CASE WHEN exclusions <> '' OR extras <> '' THEN 1
    ELSE 0
    END) AS at_least_1_change,
  SUM(
    CASE WHEN exclusions = '' AND extras = '' THEN 1 
    ELSE 0
    END) AS no_change
FROM customer_orders AS co
JOIN runner_orders AS ro
  ON co.order_id = ro.order_id
WHERE cancellation =''
GROUP BY customer_id
ORDER BY customer_id
```

**Result**

|   customer_id  | at_least_1_change | no_change |
|:--------|:----------|:----------|
|  101   |    0     |    2     |
|  102   |    0     |    3     |
|  103   |    3     |    0     |
|  104   |    2     |    1     |
|  105   |    1     |    0     |


### 8. How many pizzas were delivered that had both exclusions and extras?

```sql
SELECT  
  SUM(
    CASE WHEN exclusions <> '' and extras <> '' THEN 1
    ELSE 0
    END) AS exclu_extra_count
FROM customer_orders AS co
JOIN runner_orders AS ro
  ON co.order_id=ro.order_id
WHERE cancellation =''
  AND exclusions <> ''
  AND extras <> ''
```

**Result**

|exclu_extra_count|
|:-|
|1|

### 9. What was the total volume of pizzas ordered for each hour of the day?

```sql
SELECT 
DATEPART(hour,order_time) AS hour,
COUNT(*) AS count_pizza
FROM customer_orders
GROUP BY DATEPART(hour,order_time) 
```

**Result**

| hour | count_pizza |
|:---------|:--------|
|    11    |    1     |
|    13    |    3     |
|    18    |    3     |
|    19    |    1     |
|    21    |    3     |
|    23    |    3     |


### 10. What was the volume of orders for each day of the week?

```sql
SELECT 
FORMAT(order_time,'dddd') AS day_of_week,
COUNT(*) AS count_pizza 
FROM customer_orders
GROUP BY FORMAT(order_time,'dddd')
```

**Result**

|    day_of_week  | count_pizza |
|:-----------|:------|
|   Friday   |   1   |
|  Saturday  |   5   |
|  Thursday  |   3   |
| Wednesday  |   5   |


## B. Runner and Customer Experience

### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

```sql
SELECT DATEPART(week, registration_date) as week,
       COUNT(*) as number_runner_sign
FROM runners
GROUP BY DATEPART(week, registration_date)
```

**Result**

|week|runner_number_sign|
|:--|:--|
|1|1|
|2|2|
|3|1|

### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

```sql
with time_table as (
    SELECT distinct customer_orders.order_id, runner_id , 
    order_time , pickup_time
    FROM customer_orders 
    JOIN runner_orders 
    ON customer_orders.order_id = runner_orders.order_id
    WHERE cancellation=''
) 
SELECT 
    AVG(DATEDIFF(minute,  convert(datetime, order_time), convert(datetime, pickup_time))) as avg_time 
FROM time_table
```

**Result**

|avg_time|
|:--|
|16|

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

```sql
WITH table_time as (
    SELECT co.order_id,
    COUNT(customer_id) as pizza_count,
    MAX(DATEDIFF(MINUTE,order_time,pickup_time)) as total_time
FROM customer_orders as co 
LEFT JOIN runner_orders as ro
ON co.order_id=ro.order_id
WHERE cancellation=''
GROUP BY co.order_id) 
SELECT pizza_count, 
    AVG(total_time) as avg_time 
    FROM table_time 
GROUP BY pizza_count
```

**Result**

|pizza_count|avg_time|
|:-|:-|
|1|12|
|2|16|
|3|30

### 4. What was the average distance travelled for each customer?

```sql
SELECT
    customer_id,
    AVG(CONVERT(FLOAT, distance)) AS avg_distance
FROM
    customer_orders AS co
JOIN
    runner_orders AS ro ON co.order_id = ro.order_id
WHERE
    cancellation=''
GROUP BY
    customer_id;
```

**Result**

| customer_id | avg_distance|
|:------------|:-----------------|
| 101         | 20               |
| 102         | 16.7333333333333 |
| 103         | 23.4             |
| 104         | 10               |
| 105         | 25               |

### 5. What was the difference between the longest and shortest delivery times for all orders?

```sql
SELECT MAX(CONVERT(float,duration)) - MIN(CONVERT(float,duration)) AS delivery_time_difference
FROM runner_orders
WHERE cancellation=''
```

**Result**

|delivery_time_difference|
|:--|
|30|

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

```sql 
SELECT distinct 
    runner_id, customer_id ,
    CONVERT(FLOAT, distance)/(CONVERT(FLOAT,duration)/60) as avg_speed
FROM runner_orders
    JOIN customer_orders
ON runner_orders.order_id=customer_orders.order_id
WHERE cancellation =''
ORDER BY runner_id
```

**Result**

| runner_id | customer_id | avg_speed |
|:----------|:----------|:----------|
| 1        | 101      | 37.5     |
| 1        | 101      | 44.44 |
| 1        | 102      | 40.2     |
| 1        | 104      | 60       |
| 2        | 102      | 93.6     |
| 2        | 103      | 35.1     |
| 2        | 105      | 60       |
| 3        | 104      | 40       |


### 7.What is the successful delivery percentage for each runner?

```sql
SELECT 
    A.runner_id,
    B.count,
    A.total_count,
    FORMAT(B.count * 1.0 / A.total_count, 'p') AS percentage
FROM 
    (SELECT 
        runner_id, 
        COUNT(*) AS total_count 
    FROM 
        runner_orders 
    GROUP BY 
        runner_id) AS A
JOIN 
    (SELECT 
        runner_id,
        COUNT(*) AS count
    FROM 
        runner_orders
    WHERE 
        cancellation=''
    GROUP BY 
        runner_id) AS B
ON 
    A.runner_id = B.runner_id
```

**Result**

| runner_id | count | total_count | percentage |
|:----------|:------------------|:--------------|:-------------------|
| 1         | 4                 | 4            | 100.00%           |
| 2         | 3                 | 4            | 75.00%            |
| 3         | 1                 | 2            | 50.00%            |


# C. Ingredient Optimisation


```python

```

# D. Pricing and Ratings




```python

```


```python

```


```python

```
