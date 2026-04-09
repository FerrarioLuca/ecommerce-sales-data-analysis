----------------------------------------------------
-- 00_create_views.sql
-- Project: E-commerce Sales and Customer Analysis
-- Purpose: create clean analytic views from raw tables
----------------------------------------------------

-- These views are the clean analytic layer used by the project queries.
-- Raw tables stay unchanged; simplification happens here.

drop view if exists customers;
drop view if exists orders;
drop view if exists order_items;
drop view if exists products;


-- customers:
-- use customer_unique_id as the customer identifier in the analytic layer
-- and keep one row per real customer
-- Grain: one row = one unique customer

create view customers as
select
    customer_unique_id as customer_id, min(customer_city) as customer_city, min(customer_state) as customer_state
from raw_customers
group by customer_unique_id;


-- orders:
-- resolve the raw customer_id -> customer_unique_id bridge once here
-- and rename the purchase timestamp as order_date
-- Grain: one row = one order

create view orders as
select
    o.order_id, c.customer_unique_id as customer_id, o.order_purchase_timestamp as order_date, o.order_status
from raw_orders o join raw_customers c
    on c.customer_id = o.customer_id;


-- order_items:
-- keep only the fields needed for the analysis
-- price is the core revenue field used in the project
-- Grain: one row = one item within an order

create view order_items as
select
    order_id, order_item_id, product_id, price
from raw_order_items;


-- products:
-- translate category names into English when available
-- otherwise keep the original value
-- Grain: one row = one product

create view products as
select
    p.product_id, coalesce(ct.product_category_name_english, p.product_category_name) as category
from raw_products p left join category_translation ct
    on ct.product_category_name = p.product_category_name;