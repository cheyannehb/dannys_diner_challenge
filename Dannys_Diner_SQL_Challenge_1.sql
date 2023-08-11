CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE dannys_diner.sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);
  
  INSERT INTO dannys_diner.sales
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
  
  CREATE TABLE dannys_diner.menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO dannys_diner.menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
  CREATE TABLE dannys_diner.members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO dannys_diner.members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
 
 
 ---1. What is the total amount each customer spent at the restaurant?
 
SELECT 
	s.customer_id,
   	SUM(m.price) AS customer_bill
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY customer_id, customer_bill;  


---2. How many days has each customer visited the restaurant?

SELECT
	s.customer_id,
	COUNT(EXTRACT(DAY FROM s.order_date)) AS days_ordered
FROM dannys_diner.sales AS s
GROUP BY s.customer_id
ORDER BY s.customer_id, days_ordered;


---3. What was the first item from the menu purchased by each customer?

SELECT s.customer_id, MIN(order_date), m.product_name
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name,s.order_date
ORDER BY s.order_date ASC
LIMIT 4	


--- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
	s.customer_id,
	m.product_name,
	COUNT (s.product_id) AS total_ordered
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
WHERE product_name = 'ramen'
GROUP BY s.customer_id, m.product_name
ORDER BY total_ordered DESC;


--- 5. Which item was the most popular for each customer?

WITH ranked_sales AS (
    SELECT 
        s.customer_id,
        m.product_name,
        COUNT(s.product_id) AS total_ordered,
        RANK() 
			OVER (PARTITION BY s.customer_id 
				  ORDER BY COUNT(s.product_id)DESC) AS occurrence
    FROM dannys_diner.sales AS s
    LEFT JOIN dannys_diner.menu AS m 
		ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT 
    customer_id,
    product_name,
    total_ordered,
    occurrence
FROM ranked_sales
WHERE occurrence = 1;


--- 6. Which item was purchased first by the customer after they became a member?

WITH first_purchase AS 
	(SELECT
		s.customer_id, 
		s.order_date,
		m.product_name, 
		m.product_id, 
		mem.join_date,
		RANK() 
			OVER(PARTITION BY s.customer_id 
			 ORDER BY s.order_date ASC) AS orders
	FROM dannys_diner.sales AS s
	INNER JOIN dannys_diner.members AS mem
		ON s.customer_id = mem.customer_id
	INNER JOIN dannys_diner.menu AS m
		ON s.product_id = m.product_id
	WHERE order_date > join_date)	
SELECT *
FROM first_purchase AS fp
WHERE fp.orders = 1;


---7. Which item was purchased just before the customer became a member?

WITH last_purchase AS 
	(SELECT
		s.customer_id, 
		s.order_date,
		m.product_name, 
		m.product_id, 
		mem.join_date,
		RANK() 
			OVER(PARTITION BY s.customer_id 
			 ORDER BY s.order_date DESC) AS orders
	FROM dannys_diner.sales AS s
	INNER JOIN dannys_diner.members AS mem
		ON s.customer_id = mem.customer_id
	INNER JOIN dannys_diner.menu AS m
		ON s.product_id = m.product_id
	WHERE order_date < join_date)	
SELECT *
FROM last_purchase AS lp
WHERE lp.orders = 1;


--- 8. What is the total items and amount spent for each member before they became a member?

SELECT 
	s.customer_id,
	COUNT(s.product_id) AS total_items,
	SUM(m.price) AS amt_spent
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.members AS mem
	ON s.customer_id = mem.customer_id
LEFT JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id;


--- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT
	s.customer_id,
	m.product_name,
	SUM(m.price) AS total_spent,
	CASE WHEN m.product_name = 'sushi' THEN (20 * SUM(m.price))
	ELSE (10 * SUM(m.price)) END AS points
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name;


--- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


WITH total_points AS
	(SELECT
	s.customer_id,
	 CASE WHEN m.product_name = 'sushi' 
	 THEN (20 * SUM(m.price))
	 WHEN s.order_date BETWEEN mem.join_date 
	 	AND (mem.join_date + INTERVAL '7 days')
	 THEN (20 * SUM(m.price))
	ELSE (10 * SUM(m.price)) END AS points
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
LEFT JOIN dannys_diner.members AS mem
	ON s.customer_id = mem.customer_id
WHERE s.order_date BETWEEN mem.join_date
	AND '2021-01-31'
	GROUP BY s.customer_id, 
	 		m.product_name, 
	 		s.order_date, 
	 		mem.join_date)
SELECT 
	customer_id,
	SUM(points) AS jan_points
FROM total_points
GROUP BY customer_id
ORDER BY jan_points DESC;
