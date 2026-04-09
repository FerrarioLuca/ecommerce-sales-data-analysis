---------------------------------------------------
-- 01_data_checks.sql
-- Project: E-commerce Sales and Customer Analysis
-- Purpose: data quality checks before KPI analysis
---------------------------------------------------

-- Check 1: duplicate customer_id in customers
select
    customer_id, count(*) as num_rows
from customers
group by customer_id
having count(*) > 1;

-- Check 2: duplicate order_id in orders
select
    order_id, count(*) as num_rows
from orders
group by order_id
having count(*) > 1;

-- Check 3: duplicate product_id in products
select
    product_id, count(*) as num_rows
from products
group by product_id
having count(*) > 1;

-- Check 4: critical nulls in orders
select *
from orders
where order_id is null
   or customer_id is null
   or order_date is null;

-- Check 5: critical nulls in order_items
select *
from order_items
where order_id is null
   or order_item_id is null
   or product_id is null
   or price is null;

-- Check 6: critical nulls in products
select *
from products
where product_id is null
   or category is null;

-- Check 7: invalid values in order_items
select *
from order_items
where price <= 0;

-- Check 8: orphan orders without matching customer
select o.*
from orders o left join customers c
    on c.customer_id = o.customer_id
where c.customer_id is null;

-- Check 9: orphan order_items without matching order
select oi.*
from order_items oi left join orders o
    on o.order_id = oi.order_id
where o.order_id is null;

-- Check 10: orphan order_items without matching product
select oi.*
from order_items oi left join products p
    on p.product_id = oi.product_id
where p.product_id is null;

-- Check 11: orders without matching order_items
-- Note:
--  this is a data quality / model consistency check
--  it does not represent all failed or non-completed orders
select o.*
from orders o left join order_items oi
    on oi.order_id = o.order_id
where oi.order_id is null;

-- Check 12: row count by table
select 'customers' as table_name, count(*) as num_rows from customers
union all
select 'orders', count(*) from orders
union all
select 'order_items', count(*) from order_items
union all
select 'products', count(*) from products;
