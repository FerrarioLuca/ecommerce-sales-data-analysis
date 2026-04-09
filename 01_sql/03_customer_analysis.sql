----------------------------------------------------
-- 03_customer_analysis.sql
-- Project: E-commerce Sales and Customer Analysis
-- Purpose: customer-level analysis for 2017
----------------------------------------------------

-- Query 1: one-time vs repeat customers in 2017
-- Logic:
--  first count delivered orders per customer in 2017
--  then classify customers as one-time or repeat
--  also calculate the percentage of customers in each group

with customer_orders_2017 as (
select
    customer_id, count(*) as num_orders_2017
from orders
where order_date >= '2017-01-01' and order_date < '2018-01-01'
    and order_status = 'delivered'
group by customer_id
)
select
    case when num_orders_2017 = 1 then 'one-time' else 'repeat' end as customer_type,
    count(*) as num_customers,
    round(count(*) * 100.0 / sum(count(*)) over (), 2) as pct_customers
from customer_orders_2017
group by
    case when num_orders_2017 = 1 then 'one-time' else 'repeat' end
order by num_customers desc;


-- Query 2: top 10 customers by total delivered revenue in 2017
-- Logic:
--  revenue is calculated from order_items
--  only delivered orders are included
--  results are aggregated at customer level

select
    o.customer_id, sum(oi.price) as total_revenue_2017
from orders o join order_items oi
    on oi.order_id = o.order_id
where o.order_date >= '2017-01-01' and o.order_date < '2018-01-01'
    and o.order_status = 'delivered'
group by o.customer_id
order by total_revenue_2017 desc
limit 10;


-- Query 3: customers active in H1 2017 but inactive in H2 2017
-- Logic:
--  use exists / not exists to identify customers who placed
--  delivered orders in the first half of the year but not in the second half
--  group results by customer_state for a more readable output

select
    c.customer_state, count(*) as num_customers
from customers c
where exists (
select 1
from orders o
where o.customer_id = c.customer_id
    and o.order_date >= '2017-01-01' and o.order_date < '2017-07-01'
    and o.order_status = 'delivered'
)
and not exists (
select 1
from orders o
where o.customer_id = c.customer_id
    and o.order_date >= '2017-07-01' and o.order_date < '2018-01-01'
    and o.order_status = 'delivered'
)
group by c.customer_state
order by num_customers desc, c.customer_state;


-- Query 4: customers with H2 AOV greater than H1 AOV
-- Logic:
--  first calculate delivered order_value at order level
--  then compare average order value between first half and second half of 2017
--  keep only customers with at least one delivered order in both periods

with order_value_2017 as (
select
    o.order_id, o.customer_id, o.order_date, sum(oi.price) as order_value
from orders o join order_items oi
    on oi.order_id = o.order_id
where o.order_date >= '2017-01-01' and o.order_date < '2018-01-01'
    and o.order_status = 'delivered'
group by o.order_id, o.customer_id, o.order_date
)
select
    customer_id,
    avg(case when month(order_date) between 1 and 6 then order_value end) as avg_order_value_h1_2017,
    avg(case when month(order_date) between 7 and 12 then order_value end) as avg_order_value_h2_2017
from order_value_2017
group by customer_id
having count(case when month(order_date) between 1 and 6 then 1 end) >= 1
    and count(case when month(order_date) between 7 and 12 then 1 end) >= 1
    and avg(case when month(order_date) between 7 and 12 then order_value end) 
    > avg(case when month(order_date) between 1 and 6 then order_value end);


-- Query 5: customers whose last active month revenue in 2017 is greater than their previous active month revenue
-- Logic:
--  first move data to customer-month level using delivered orders only
--  then use lag to compare the last active month with the previous one

with customer_month_2017 as (
select
    o.customer_id, date_format(o.order_date, '%Y-%m') as order_month, sum(oi.price) as month_revenue
from orders o join order_items oi
    on oi.order_id = o.order_id
where o.order_date >= '2017-01-01' and o.order_date < '2018-01-01'
    and o.order_status = 'delivered'
group by o.customer_id, date_format(o.order_date, '%Y-%m')
),
month_with_lag as (
select
    customer_id, order_month, month_revenue, 
    row_number() over (partition by customer_id order by order_month desc) as rn,
    lag(month_revenue) over (partition by customer_id order by order_month) as prev_month_revenue
from customer_month_2017
)
select
    customer_id, order_month as last_active_month, month_revenue as last_active_month_revenue, prev_month_revenue
from month_with_lag
where rn = 1
    and prev_month_revenue is not null
    and month_revenue > prev_month_revenue;


-- Query 6: customers whose top category accounts for more than 50% of their total revenue in 2017
-- Logic:
--  first move data to customer-category level using delivered orders only
--  then rank categories by revenue within each customer
--  keep top categories only, including ties
--  compare top category revenue with total customer revenue

with customer_category_2017 as (
select
    o.customer_id, p.category, sum(oi.price) as category_revenue
from orders o join order_items oi
    on oi.order_id = o.order_id
    join products p
    on p.product_id = oi.product_id
where o.order_date >= '2017-01-01'
    and o.order_date < '2018-01-01' and o.order_status = 'delivered'
group by o.customer_id, p.category
),
ranked_categories as (
select
    customer_id, category, category_revenue,
    sum(category_revenue) over (partition by customer_id) as total_revenue_2017,
    count(*) over (partition by customer_id) as num_categories,
    dense_rank() over (partition by customer_id order by category_revenue desc) as category_rank
from customer_category_2017
)
select
    customer_id, category as top_category, category_revenue as top_category_revenue_2017, total_revenue_2017,
    category_revenue * 1.0 / total_revenue_2017 as pct_of_total
from ranked_categories
where category_rank = 1
    and num_categories >= 2
    and category_revenue > total_revenue_2017 * 0.5;