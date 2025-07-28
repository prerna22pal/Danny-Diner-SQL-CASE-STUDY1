/*
Author - Prerna Pal
Tool used = MYSQL Workbench 8.0 CE
Created on - July 2025 
*/

  ------------------------------------------------------------------
                         -- CASE STUDY QUESTIONS --
  ------------------------------------------------------------------



-- Q1.What is the total amount each customer spent at the restaurant?*/ 

select s.customer_id, sum(m.price)
from sales s join menu m on s.product_id = m.product_id
group by s.customer_id

  ------------------------------------------------------------------

-- Q2. How many days has each customer visited the restaurant?

select customer_id, count(distinct order_date )
from sales 
group by customer_id


  ------------------------------------------------------------------

-- Q3. What was the first item from the menu purchased by each customer?
select customer_id, product_name
from (select s.customer_id, product_name,
dense_rank() over(partition by s.customer_id order by s.order_date ) as rnk
from sales s join menu m on s.product_id = m.product_id) a
where a.rnk = 1
group by customer_id,product_name;

  ------------------------------------------------------------------
-- Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select s.customer_id,s.product_id, count(s.product_id) as most_purchased
from sales s join menu m on s.product_id = m.product_id
where s.product_id =
(select top 1 product_id
from sales
group by product_id
order by count(product_id) desc)
group by s.customer_id,s.product_id
order by customer_id;
  ------------------------------------------------------------------
-- Q5. Which item was the most popular for each customer?
select customer_id, product_name as ordered_product
from(select s.customer_id,product_name,
	count(s.product_id) as total_count,
    dense_rank() over(partition by customer_id 
    order by count(s.product_id) desc) as rnk
	from sales s
	join menu m on s.product_id = m.product_id
    group by 1,2)a
where a.rnk = 1
group by customer_id,product_name ;
  ------------------------------------------------------------------

-- Q6. Which item was purchased first by the customer after they became a member?
select customer_id, order_date, product_name
from 
(select distinct s.customer_id, s.order_date, mn.product_name
from members m 
join sales s on s.customer_id = m.customer_id
join menu mn on s.product_id = mn.product_id
where s.order_date >= m.join_date
)a

  ------------------------------------------------------------------

-- Q7. Which item was purchased just before the customer became a member?
select customer_id, product_name
from 
(select s.customer_id, s.order_date, mn.product_name,
dense_rank() over(partition by s.customer_id order by s.order_date) rnk
from members m 
join sales s on s.customer_id = m.customer_id
join menu mn on s.product_id = mn.product_id
where s.order_date < m.join_date
)a

  ------------------------------------------------------------------


-- Q8. What are the total items and amount spent for each member before they became a member?

select customer_id, count( product_id),sum(price)
from 
(select  s.customer_id, s.order_date,  s.product_id, mn.price
from members m 
join sales s on s.customer_id = m.customer_id
join menu mn on s.product_id = mn.product_id
where s.order_date < m.join_date

)a
group by a.customer_id

  ------------------------------------------------------------------
  
/* Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
--how many points would each customer have?*/

select customer_id,sum(m.points) as total_points
from sales s join (select product_id,
case when product_name = 'sushi' then price*20 else price*10 end as points
from menu) m on s.product_id = m.product_id
group by s.customer_id;
  ------------------------------------------------------------------

/*-- Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
not just sushi - how many points do customer A and B have at the end of January?*/
with joined_orders as (
    SELECT 
        s.customer_id,
        s.order_date,
        m.price,
        c.join_date,
        CASE 
            WHEN s.order_date BETWEEN c.join_date AND DATEADD(DAY, 6, c.join_date) THEN 2 
            ELSE 1 
        END AS multiplier
    FROM sales s
    JOIN menu m 
        ON s.product_id = m.product_id
    JOIN members c 
        ON s.customer_id = c.customer_id
)
SELECT 
    customer_id,
    SUM(price * multiplier) AS total_points
FROM joined_orders
WHERE order_date <= '2021-01-31'
GROUP BY customer_id;

------------------------------------------------------------------

/*Q11  Join All The Things
The following questions are related creating basic data tables that Danny and 
his team can use to quickly derive insights without needing to join the underlying 
tables using SQL.

Recreate the following table output using the available data:
*/

with cte as(
    select s.customer_id, s.order_date, m.product_name, m.price
    from sales s left join menu m on s.product_id = m.product_id
)
select c.customer_id, c.order_date, c.product_name, c.price,
case when c.order_date>=mb.join_Date then 'Y' else 'N' end as members
from cte c  left join members mb on c.customer_id = mb.customer_id;

------------------------------------------------------------------

/*Q12  Rank All The Things
Danny also requires further information about the ranking of customer products, but 
he purposely does not need the ranking for non-member purchases so he expects null
ranking values for the records when customers are not yet part of the loyalty program.
*/

with cte as(
    select s.customer_id, s.order_date, m.product_name, m.price
    from sales s left join menu m on s.product_id = m.product_id
),
cte1 as(
select c.customer_id, c.order_date, c.product_name, c.price,
case when c.order_date>=mb.join_Date then 'Y' else 'N' end as members
from cte c  left join members mb on c.customer_id = mb.customer_id
)
select d.customer_id, d.order_date, d.product_name, d.price,d.members,
case when d.members = 'Y' then dense_rank() over(partition by d.customer_id order by d.order_date) else null end as ranking
from cte1 d;

