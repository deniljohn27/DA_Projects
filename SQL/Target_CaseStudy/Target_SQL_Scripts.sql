--Target Data Set 
--Data type of all columns in the “customers” table.
SELECT
  column_name,
  data_type
FROM
  target.INFORMATION_SCHEMA.COLUMNS
WHERE
  table_name = 'customers';

--Get the time range between which the orders were placed.
select
min(order_purchase_timestamp),
max(order_purchase_timestamp)
from target.orders;

--Count the Cities & States of customers who ordered during the given period.
select 
count(distinct customer_city) as city,
count(distinct customer_state) as state
from target.orders o
inner join target.customers c
on o.customer_id=c.customer_id;

--Is there a growing trend in the no. of orders placed over the past years?
select 
extract (year from c.order_purchase_timestamp) as year,
count(distinct order_id) as count_of_orders
from target.orders c
group by 1
order by count_of_orders;

--Can we see some kind of monthly seasonality in terms of the no. of orders being placed?
select 
extract (month from c.order_purchase_timestamp) as month,
count(distinct order_id) as count_of_orders
from target.orders c
group by 1
order by count_of_orders desc;

--During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night) 

--Confirming no duplicates in order_id table
select 
order_id ,
count(order_id)
from target.orders
group by 1
having count(order_id)>=2;

with time_of_order as 
(
select 
c.order_id,
extract (time from c.order_purchase_timestamp) as time,
case 
when extract (time from c.order_purchase_timestamp) between '00:00:00' and '06:00:00' THEN 'Dawn'
when extract (time from c.order_purchase_timestamp)  between '07:00:00' and '12:00:00' THEN 'Morning'
when extract (time from c.order_purchase_timestamp) between '13:00:00' and '18:00:00' THEN 'Afternoon'
else 'Night'
end as time_of_day
from target.orders c
)
select 
time_of_day,
count(time_of_day) as order_count
from time_of_order
group by 1
order by order_count desc;

--Get the month on month no. of orders placed in each state.
select 
c.customer_state,
extract(month from o.order_purchase_timestamp) month,
count(distinct o.order_id) as order_count
from target.orders o
inner join target.customers c
on o.customer_id=c.customer_id
group by 1,2
order by 1,2 desc;

--Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only). 
--You can use the “payment_value” column in the payments table to get the cost of orders.

select 
extract (month from o.order_purchase_timestamp) month,
round((
  sum(case when extract(year from o.order_purchase_timestamp) IN (2018) 
  AND extract(month from o.order_purchase_timestamp)  between 1 and 8 
  then p.payment_value end)
-
  sum(case when extract(year from o.order_purchase_timestamp) IN (2017) 
  AND extract(month from o.order_purchase_timestamp)  between 1 and 8 
  then p.payment_value end))
  /sum(case when extract(year from o.order_purchase_timestamp) IN (2017) 
  AND extract(month from o.order_purchase_timestamp)  between 1 and 8 
  then p.payment_value end) * 100,2) as per_increase
from target.orders o
inner join target.payments p
on o.order_id=p.order_id
where extract(year from o.order_purchase_timestamp) IN (2017,2018) AND cast(extract(month from o.order_purchase_timestamp) as int) between 1 and 8
group by 1
order by 1;

--Calculate the Total & Average value of order price for each state.
--Calculate the Total & Average value of order freight for each state.
select 
c.customer_state,
round(sum(oi.price),2) Total_value,
round(avg(oi.price),2) Average_value,
round(sum(oi.freight_value),2) Total_freight_value,
round(avg(oi.freight_value),2) Average_freight_value
from target.orders o
inner join target.order_items oi
on o.order_id=oi.order_id
inner join target.customers c
on o.customer_id=c.customer_id
group by 1
order by 1;

-- Find the no. of days taken to deliver each order from the order’s purchase date as delivery time.
-- Also, calculate the difference (in days) between the estimated & actual delivery date of an order.
-- Do this in a single query.
-- You can calculate the delivery time and the difference between the estimated & actual delivery date using the given formula:
-- time_to_deliver = order_delivered_customer_date - order_purchase_timestamp
-- diff_estimated_delivery = order_estimated_delivery_date - order_delivered_customer_date
-- Calculate the delivery status of orders
with delvry_dtl as
(select 
o.order_id,
date_diff(o.order_delivered_customer_date, o.order_purchase_timestamp,DAY) time_to_deliver,
date_diff(o.order_estimated_delivery_date, o.order_delivered_customer_date,DAy)
diff_estimated_delivery
from target.orders o
order by time_to_deliver desc),
delvry_cat as(
select 
case when diff_estimated_delivery=0 then "OnTime"
when diff_estimated_delivery>0 then "Early"
else "Late"
end as delivery_completed
from delvry_dtl)
select 
dc.delivery_completed as status,
count(*) as countOfStatus
from delvry_cat dc
group by 1;

--which region has the most late delivery
with delvry_dtl as
(select 
o.order_id as order_id,
o.customer_id as customer_id,
date_diff(o.order_delivered_customer_date, o.order_purchase_timestamp,DAY) time_to_deliver,
date_diff(o.order_estimated_delivery_date, o.order_delivered_customer_date,DAy)
diff_estimated_delivery
from target.orders o
order by time_to_deliver desc),
delvry_cat as(
select 
order_id,
customer_id,
case when diff_estimated_delivery=0 then "OnTime"
when diff_estimated_delivery>0 then "Early"
else "Late"
end as delivery_completed
from delvry_dtl )
select 
dc.delivery_completed,
c.customer_state,
c.customer_city,
count(*) as countOf
from delvry_cat dc
inner join target.customers c
on dc.customer_id=c.customer_id
where dc.delivery_completed='Late'
group by 1,2,3
order by 4 desc;

--Find out the top 5 states with the highest & lowest average freight value.
with freight_details as(
select 
c.customer_state as state,
round(avg(oi.freight_value),2) Average_freight_value
from target.orders o
inner join target.order_items oi
on o.order_id=oi.order_id
inner join target.customers c
on o.customer_id=c.customer_id
group by 1),
ranked_table as(
select 
fd.state,
fd.Average_freight_value,
rank() over(order by fd.Average_freight_value desc) as highest_freight,
rank() over(order by fd.Average_freight_value) as lowest_freight
from freight_details fd)
select * from ranked_table 
where (highest_freight between 1 and 5) 
OR (lowest_freight between 1 and 5)
order by 3;

--Find out the top 5 states with the highest & lowest average delivery time.
with state_delivery_detl as(
  select 
  c.customer_state as state,
  round(avg(date_diff(o.order_delivered_customer_date, o.order_purchase_timestamp,DAY)),2) avg_time_to_deliver
  from  target.orders o
  inner join  target.customers c on
  c.customer_id=o.customer_id
  group by 1
),
ranked_states as(
  select 
  *,
  rank() over(order by avg_time_to_deliver desc) as highest_deliver_time,
  rank() over(order by avg_time_to_deliver) as lowest_delivery_time
  from state_delivery_detl
) 
select 
state,
avg_time_to_deliver,
highest_deliver_time,
lowest_delivery_time
 from ranked_states 
where (highest_deliver_time between 1 and 5) 
OR (lowest_delivery_time between 1 and 5)
order by 4;

--Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.
with state_delivery_detl as(
  select 
  c.customer_state as state,
  round(avg(date_diff(o.order_estimated_delivery_date, o.order_delivered_customer_date,DAy)),0) avg_ftime_to_deliver
  from  target.orders o
  inner join  target.customers c on
  c.customer_id=o.customer_id
  group by 1
),
ranked_states as(
  select 
  *,
  rank() over(order by avg_ftime_to_deliver desc) as lowest_avg_delivery_time
  from state_delivery_detl
) 
select 
state,
avg_ftime_to_deliver,
lowest_avg_delivery_time
 from ranked_states 
where (lowest_avg_delivery_time between 1 and 5) 
order by 3;

--Find the month on month no. of orders placed using different payment types.
select 
extract(month from o.order_purchase_timestamp) as month,
count(distinct p.payment_type) diff_paymenn_type
from target.orders o
inner join target.payments p
on o.order_id=p.order_id
group by 1
order by 1;
