---------------------------------------------------
-- 02_core_kpis.sql
-- Project: E-commerce Sales and Customer Analysis
-- Purpose: core business KPIs for 2017
---------------------------------------------------

-- Query 1: total delivered revenue in 2017
-- Logic:
--  revenue is defined as the sum of item prices
--  only delivered orders are included
--  customers and products are not needed here

select
    sum(oi.price) as total_revenue_2017
from orders o join order_items oi
    on oi.order_id = o.order_id
where o.order_date >= '2017-01-01' and o.order_date < '2018-01-01'
    and o.order_status = 'delivered';


-- Query 2: monthly delivered revenue in 2017
-- Logic:
--  revenue is calculated at item level
--  then aggregated by month
--  only delivered orders are included

select
    date_format(o.order_date, '%Y-%m') as order_month, sum(oi.price) as monthly_revenue
from orders o join order_items oi
    on oi.order_id = o.order_id
where o.order_date >= '2017-01-01' and o.order_date < '2018-01-01'
    and o.order_status = 'delivered'
group by date_format(o.order_date, '%Y-%m')
order by order_month;


-- Query 3: number of delivered orders per month in 2017
-- Logic:
--  count only delivered orders
--  no join required

select
    date_format(order_date, '%Y-%m') as order_month, count(order_id) as num_orders
from orders
where order_date >= '2017-01-01' and order_date < '2018-01-01'
    and order_status = 'delivered'
group by date_format(order_date, '%Y-%m')
order by order_month;


-- Query 4: delivered revenue by category in 2017
-- Logic:
--  category is stored in products
--  revenue comes from order_items
--  date and delivered filter come from orders

select
    p.category, sum(oi.price) as category_revenue
from orders o join order_items oi
    on oi.order_id = o.order_id
    join products p
    on p.product_id = oi.product_id
where o.order_date >= '2017-01-01' and o.order_date < '2018-01-01'
    and o.order_status = 'delivered'
group by p.category
order by category_revenue desc;


-- Query 5: average order value by month for delivered orders in 2017
-- Logic:
--  first move data to delivered order level
--  then calculate the average order value per month

with order_value_2017 as (
select
    o.order_id, o.order_date, sum(oi.price) as order_value
from orders o join order_items oi
    on oi.order_id = o.order_id
where o.order_date >= '2017-01-01' and o.order_date < '2018-01-01'
    and o.order_status = 'delivered'
group by o.order_id, o.order_date
)
select
    date_format(order_date, '%Y-%m') as order_month, avg(order_value) as avg_order_value
from order_value_2017
group by date_format(order_date, '%Y-%m')
order by order_month;


-- Query 6: non-delivered orders with items by status in 2017
-- Logic:
--  identify orders that are not delivered but still have order_items
--  these orders would affect revenue if no status filter were applied
--  group them by order_status and calculate their share

select
    o.order_status, count(distinct o.order_id) as num_orders, sum(oi.price) as non_delivered_value,
    round (count(distinct o.order_id) * 100.0 / sum(count(distinct o.order_id)) over (), 2) as pct_orders
from orders o join order_items oi
    on oi.order_id = o.order_id
where o.order_date >= '2017-01-01' and o.order_date < '2018-01-01'
    and o.order_status <> 'delivered'
group by o.order_status
order by non_delivered_value desc, o.order_status;
