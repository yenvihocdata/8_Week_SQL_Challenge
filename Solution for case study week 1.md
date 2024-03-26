# 🍜 Case Study #1: Danny's Diner


<img src="https://8weeksqlchallenge.com/images/case-study-designs/1.png" alt="Mo ta anh" width="700" height="800">


# Introduction
   

Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.


# Problem Statement

Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

Danny has shared with you 3 key datasets for this case study:

- **sales**
- **menu**
- **members**

You can inspect the entity relationship diagram and example data below.


# Entity Relationship Diagram

# Question and Solution

### 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT customer_id, SUM(price) as total_spent 
FROM sales 
LEFT JOIN menu 
on sales.product_id = menu.product_id 
Group by customer_id


**Result**

| customer_id | total_spent |
|:------------|:------------|
|     A       |     76       |
|     B       |     74       |
|     C       |     36       |

***

### 2. How many days has each customer visited the restaurant?

```sql
SELECT 
    customer_id,
    COUNT(DISTINCT order_date) AS days
FROM 
    sales
GROUP BY 
    customer_id;


**Result**

|customer_id|days|
|:----------|:---|
|A|4|
|B|6|
|C|2|

### 3. What was the first item from the menu purchased by each customer?

**Method 1: Use window function FIRST_VALUE() to solve the question**

```sql
SELECT DISTINCT customer_id,
    FIRST_VALUE(product_name) OVER (PARTITION BY customer_id ORDER BY order_date) AS first_item 
    FROM sales 
    LEFT JOIN menu 
    ON sales.product_id = menu.product_id 


**Method 2: Use window function RANK() and ROW_NUMBER() to solve the question**


```sql
WITH CTE AS ( 
    SELECT customer_id, order_date, 
    product_name ,
    RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS rnk,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS rn
    FROM sales 
    LEFT JOIN menu 
    ON sales.product_id = menu.product_id
) 
SELECT customer_id, product_name 


**Result**

|customer_id|first_item|
|:----------|:---|
|A|sushi|
|B|curry|
|C|ramen|

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```sql
WITH COUNT_TABLE AS (
    SELECT 
        sales.product_id,
        product_name,
        customer_id,
        COUNT(product_name) OVER (PARTITION BY product_name, sales.product_id) AS count_total,
        COUNT(product_name) OVER (PARTITION BY customer_id, product_name) AS count
    FROM sales 
    LEFT JOIN menu ON sales.product_id = menu.product_id
)
SELECT DISTINCT product_name, count_total
FROM COUNT_TABLE
WHERE count_total = (SELECT MAX(count_total) FROM COUNT_TABLE)


**Result**


| product_name | count_total |
|:-------------|:------------|
| ramen        | 8           |


### 5. Which item was the most popular for each customer?

```sql
WITH volume_table AS (
    SELECT 
        customer_id, 
        order_date, 
        product_name,
        COUNT(*) OVER (PARTITION BY customer_id, product_name) AS volume 
    FROM 
        sales 
    LEFT JOIN 
        menu ON sales.product_id = menu.product_id
), 
volume2 AS (
    SELECT DISTINCT 
        customer_id, 
        product_name, 
        volume, 
        DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY volume DESC) AS rank
    FROM 
        volume_table
) 
SELECT 
    customer_id, 
    product_name, 
    volume 
FROM 
    volume2 
WHERE 
    rank = 1 


**Result**

| customer_id | product_name | volume|
|:----------|:----------|:----------|
| A | ramen  | 3  |
| B  | curry  | 2  |
| B  | ramen | 2  |
| B| sushi | 2 |
| C | ramen | 3 |


### 6. Which item was purchased first by the customer after they became a member?


```sql
WITH DAYDIFF AS (
    SELECT 
        sales.customer_id,
        join_date,
        order_date,
        product_name,
        DATEDIFF(day, join_date, order_date) AS daydiff
    FROM 
        sales 
    LEFT JOIN 
        members ON sales.customer_id = members.customer_id 
    LEFT JOIN 
        menu ON sales.product_id = menu.product_id 
    WHERE 
        DATEDIFF(day, join_date, order_date) > 0
),
table1 AS (
    SELECT DISTINCT 
        customer_id,
        product_name,
        RANK() OVER (PARTITION BY customer_id ORDER BY daydiff ASC) AS rnk,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY daydiff ASC) AS rn
    FROM 
        DAYDIFF
) 
SELECT 
    customer_id,
    product_name
FROM 
    table1
WHERE 
    rnk = 1 AND rn = 1;


**Result**

|customer_id|product_name|
|:----------|:-----------|
|A|ramen|
|B|sushi|

### 7. Which item was purchased just before the customer became a member?

```sql
WITH DAYDIFF AS (
    SELECT 
        sales.customer_id,
        order_date,
        join_date,
        product_name,
        DATEDIFF(day, order_date, join_date) AS daydiff
    FROM 
        sales 
    LEFT JOIN 
        members ON sales.customer_id = members.customer_id 
    LEFT JOIN 
        menu ON sales.product_id = menu.product_id 
    WHERE 
        DATEDIFF(day, order_date, join_date) > 0
),
table1 AS (
    SELECT DISTINCT 
        customer_id,
        product_name,
        RANK() OVER (PARTITION BY customer_id ORDER BY daydiff ASC) AS rnk,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY daydiff ASC) AS rn
    FROM 
        DAYDIFF
) 
SELECT DISTINCT
    customer_id,
    product_name
FROM 
    table1
WHERE 
    rnk = 1 AND rn = 1;


**Result**

|customer_id|product_name|
|:----------|:-----------|
|A|sushi|
|B|sushi|

### 8. What is the total items and amount spent for each member before they became a member?

```sql
WITH ITEM AS (
    SELECT 
        sales.customer_id,
        order_date,
        join_date,
        product_name,
        price,
        DATEDIFF(day, order_date, join_date) AS daydiff
    FROM sales 
    LEFT JOIN members ON sales.customer_id = members.customer_id 
    LEFT JOIN menu ON sales.product_id = menu.product_id 
    WHERE DATEDIFF(day, order_date, join_date) > 0
)
SELECT 
    customer_id,
    COUNT(product_name) AS total_item,
    SUM(price) AS total_price 
FROM ITEM 
GROUP BY customer_id 


**Result**

|customer_id|total_item|total_price|
|:--|:--|:--|
|A|2|25|
|B|3|40|

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?

```sql
WITH PRICE AS (
    SELECT 
        sales.customer_id,
        product_name,
        price,
        IIF(product_name='sushi', price*2, price) AS actual_price
    FROM sales 
    LEFT JOIN members ON sales.customer_id = members.customer_id 
    LEFT JOIN menu ON sales.product_id = menu.product_id
)
SELECT 
    customer_id,
    SUM(actual_price)*10 AS Score
FROM PRICE 
GROUP BY customer_id 


**Result**

|customer_id|score|
|:----------|:---|
|A|860|
|B|940|
|C|360|

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?

```sql 
SELECT 
    sales.customer_id, 
    SUM( 
        CASE 
            WHEN order_date BETWEEN join_date AND DATEADD(day, 6, join_date) THEN price * 2 * 10 
            WHEN product_name ='sushi' THEN price * 2 * 10 
            ELSE price * 10 
        END 
    ) AS score 
FROM 
    sales 
LEFT JOIN 
    members ON sales.customer_id = members.customer_id 
LEFT JOIN 
    menu ON sales.product_id = menu.product_id 
WHERE 
    MONTH(order_date) = 1 
    AND (sales.customer_id ='A' OR sales.customer_id='B') 
GROUP BY 
    sales.customer_id



**Result**

|customer_id|score|
|:----------|:---|
|A|1370|
|B|820|



```python

```
