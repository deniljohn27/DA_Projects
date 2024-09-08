--Pizza Dataset Analysis
-- Basic:
-- Retrieve the total number of orders placed.
select count(*) as Total_No_Orders from pizza_sales.orders;
-- Calculate the total revenue generated from pizza sales.
select 
round(sum(p.price* od.quantity),2) as Toatal_revenue 
from
pizza_sales.order_details od inner join
pizza_sales.pizzas p on od.pizza_id=p.pizza_id;
-- Identify the highest-priced pizza.
select 
* 
from pizza_sales.pizzas
order by price desc limit 1;
-- Identify the most common pizza size ordered.
select 
p.size as size,
count(od.order_id) order_count
from
pizza_sales.order_details od inner join
pizza_sales.pizzas p on od.pizza_id=p.pizza_id
group by 1
order by 2 desc;
-- List the top 5 most ordered pizza types along with their quantities.
select
pt.name,
count(od.order_id) order_count 
from
pizza_sales.order_details od inner join
pizza_sales.pizzas p on od.pizza_id=p.pizza_id
inner join pizza_sales.pizza_types pt on p.pizza_type_id=pt.pizza_type_id 
group by 1
order by 2 desc
limit 5;

-- Intermediate:
-- Join the necessary tables to find the total quantity of each pizza category ordered.
select
pt.category, 
sum(od.quantity) Total_quantity 
from
pizza_sales.order_details od inner join
pizza_sales.pizzas p on od.pizza_id=p.pizza_id
inner join pizza_sales.pizza_types pt on p.pizza_type_id=pt.pizza_type_id 
group by 1
order by 2 desc
;
-- Determine the distribution of orders by hour of the day.
select 
extract(hour from o.time) Hr_of_day,
count(*) Distribution
from pizza_sales.orders o
group by 1
order by 1;
-- Join relevant tables to find the category-wise distribution of pizzas.
select
pt.category, 
count(*) Distribution 
from
pizza_sales.order_details od inner join
pizza_sales.pizzas p on od.pizza_id=p.pizza_id
inner join pizza_sales.pizza_types pt on p.pizza_type_id=pt.pizza_type_id 
group by 1
order by 2 desc
;
-- Group the orders by date and calculate the average number of pizzas ordered per day.
select 
o.date,
round(avg(od.quantity),2) as avg_no_pizza
from 
pizza_sales.order_details od inner join
pizza_sales.orders o on od.order_id=o.order_id
group by 1;
-- Determine the top 3 most ordered pizza types based on revenue.
select
pt.name,
sum(od.quantity*p.price) total_revenue 
from
pizza_sales.order_details od inner join
pizza_sales.pizzas p on od.pizza_id=p.pizza_id
inner join pizza_sales.pizza_types pt on p.pizza_type_id=pt.pizza_type_id 
group by 1
order by 2 desc
limit 3;
-- Advanced:
-- Calculate the percentage contribution of each pizza type to total revenue.
with revenu_details as(select
pt.name name,
sum(od.quantity*p.price) total_revenue 
from
pizza_sales.order_details od inner join
pizza_sales.pizzas p on od.pizza_id=p.pizza_id
inner join pizza_sales.pizza_types pt on p.pizza_type_id=pt.pizza_type_id 
group by 1)
select 
name,
(total_revenue/sum(total_revenue) over()) * 100 as per_contribution
from revenu_details
order by 2 desc;
-- Analyze the cumulative revenue generated over time.
with cte as(
  select 
  o.date as order_date,
  round(sum(p.price* od.quantity),2) as Total_revenue 
  from
  pizza_sales.order_details od inner join
  pizza_sales.pizzas p on od.pizza_id=p.pizza_id
  inner join pizza_sales.orders o on od.order_id=o.order_id
  group by 1
)
select 
order_date,
Total_revenue,
round(sum(Total_revenue) over(order by order_date rows between unbounded preceding and current row),2) cumulative 
from cte
order by 1;
