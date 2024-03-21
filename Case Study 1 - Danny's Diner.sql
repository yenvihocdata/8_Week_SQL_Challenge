-- CREATE DATASET 
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
SELECT * FROM sales
SELECT * FROM menu
SELECT * FROM members
  
-- What is the total amount each customer spent at the restaurant?
  
SELECT customer_id, SUM(price) as total_spent 
FROM sales 
LEFT JOIN menu 
on sales.product_id = menu.product_id 
Group by customer_id
  
-- How many days has each customer visited the restaurant?
  
SELECT customer_id , 
COUNT(DISTINCT order_date) as days
FROM sales
GROUP BY customer_id
  
-- What was the first item from the menu purchased by each customer?
-- First way
SELECT distinct customer_id,
FIRST_VALUE(product_name) over ( partition by customer_id ORDER BY order_date) as first_item 
FROM sales 
LEFT JOIN menu 
on sales.product_id = menu.product_id 
-- Second way 
WITH CTE AS ( 
SELECT customer_id, order_date, 
product_name ,
RANK() OVER (PARTITION  BY customer_id order by order_date ASC) AS rnk,
ROW_NUMBER() OVER ( PARTITION BY customer_id order by order_date ASC) AS rn
FROM sales 
LEFT JOIN menu 
on sales.product_id = menu.product_id) 
SELECT customer_id, product_name 
FROM CTE 
WHERE rnk=1 and rn=1  
-- What is the most purchased item on the menu and how many times was it purchased by all customers?
-- first way   
with TB1 as ( 
SELECT sales.product_id,
product_name ,
customer_id 
FROM sales 
LEFT JOIN menu 
on sales.product_id = menu.product_id ),
TB2 AS (
SELECT 
customer_id , product_id , product_name,
COUNT(customer_id) over ( partition by product_id,customer_id) as count,
COUNT(product_id) over ( partition by product_id) AS total_count
FROM TB1 
) 
SELECT distinct 
customer_id, product_name, count , total_count 
from TB2
where total_count=8
--second way 
WITH COUNT_TABLE AS(
SELECT 
sales.product_id,
product_name ,
customer_id ,
count(product_name) over ( partition by product_name, sales.product_id) as count_total, 
count(product_name) over (partition by customer_id, product_name) as count 
FROM sales 
LEFT JOIN menu 
on sales.product_id = menu.product_id
)
SELECT distinct * 
FROM COUNT_TABLE 
WHERE count_total = (select max(count_total) from COUNT_TABLE) 
  
-- Which item was the most popular for each customer? --> rank, rownumber 
WITH volume_table as ( 
SELECT distinct 
customer_id, order_date, 
product_name ,
count(product_name) over (partition by customer_id, product_name) as volume 
FROM sales 
LEFT JOIN menu 
on sales.product_id = menu.product_id ) ,
volume2 as (
SELECT distinct 
customer_id,	
product_name, volume , 
RANK() OVER ( PARTITION BY customer_id order by volume) as rank
FROM volume_table ) 
select customer_id, 
product_name, volume 
from volume2
where rank=1 

-- Which item was purchased first by the customer after they became a member?
  
WITH DAYDIFF AS (
SELECT sales.customer_id ,
order_date,
join_date, 
product_name , 
DATEDIFF(day, order_date, join_date) as daydiff
FROM sales 
LEFT JOIN members
on sales.customer_id = members.customer_id 
LEFT JOIN menu
on sales.product_id = menu.product_id 
Where DATEDIFF(day, order_date, join_date) <=0 )
, table1 as (
SELECT distinct 
customer_id, 
product_name,
RANK() OVER ( PARTITION BY customer_id ORDER BY daydiff DESC) AS rnk, 
ROW_NUMBER() OVER ( PARTITION BY customer_id ORDER BY daydiff DESC) as rn
FROM DAYDIFF ) 
SELECT customer_id, product_name
FROM table1
Where rnk=1 and rn=1
  
--Which item was purchased just before the customer became a member?
  
WITH DAYDIFF AS (
SELECT sales.customer_id ,
order_date,
join_date, 
product_name , 
DATEDIFF(day, order_date, join_date) as daydiff
FROM sales 
LEFT JOIN members
on sales.customer_id = members.customer_id 
LEFT JOIN menu
on sales.product_id = menu.product_id 
Where DATEDIFF(day, order_date, join_date) > 0) 
, table1 as (
SELECT distinct 
customer_id, 
product_name,
RANK() OVER ( PARTITION BY customer_id ORDER BY daydiff ASC ) AS rnk 
FROM DAYDIFF ) 
SELECT distinct
customer_id, product_name
FROM table1
Where rnk=1 
--What is the total items and amount spent for each member before they became a member?
-- create a table before theay becam a member. we  have: 
  
WITH ITEM AS ( 
SELECT sales.customer_id ,
order_date,
join_date, 
product_name , 
price, 
DATEDIFF(day, order_date, join_date) as daydiff
FROM sales 
LEFT JOIN members
on sales.customer_id = members.customer_id 
LEFT JOIN menu
on sales.product_id = menu.product_id 
Where DATEDIFF(day, order_date, join_date) > 0) 
SELECT 
customer_id, 
COUNT(product_name) as total_item, 
SUM(price) as total_price 
FROM ITEM 
GROUP BY customer_id 
  
--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
  
WITH PRICE AS ( 
SELECT sales.customer_id ,
product_name , 
price, 
IIF(product_name='sushi',price*2,price) as actual_price
FROM sales 
LEFT JOIN members
on sales.customer_id = members.customer_id 
LEFT JOIN menu
on sales.product_id = menu.product_id ) 
SELECT customer_id, 
SUM(actual_price)*10 as Score
FROM PRICE 
GROUP BY customer_id 
  
/* In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
not just sushi - how many points do customer A and B have at the end of January? */
  
WITH AFTER_TABLE AS (
SELECT sales.customer_id ,
order_date,
join_date, 
product_name , 
price*2 as actual_price,
DATEDIFF(day, order_date, join_date) as daydiff
FROM sales 
LEFT JOIN members
on sales.customer_id = members.customer_id 
LEFT JOIN menu
on sales.product_id = menu.product_id 
Where DATEDIFF(day, order_date, join_date) <=0 
and month(order_date)=1 ) ,
BEFORE_TABLE AS (
SELECT sales.customer_id ,
order_date,
join_date, 
product_name , 
IIF(product_name='sushi', price*2, price) as actual_price ,
DATEDIFF(day, order_date, join_date) as daydiff
FROM sales 
LEFT JOIN members
on sales.customer_id = members.customer_id 
LEFT JOIN menu
on sales.product_id = menu.product_id 
Where DATEDIFF(day, order_date, join_date) > 0 ),
UNION_TABLE AS (
SELECT * 
FROM BEFORE_TABLE 
UNION ALL 
SELECT * FROM AFTER_TABLE ) 
SELECT customer_id, 
sum(actual_price)*2 as score 
FROM UNION_TABLE
GROUP BY customer_id 
