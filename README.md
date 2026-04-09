# E-commerce Sales and Customer Analysis

## Project Overview

This project is an end-to-end data analysis portfolio project built on the Olist Brazilian E-commerce dataset.

The goal is to analyze sales performance and customer behavior through:
- SQL analysis
- Power BI dashboarding
- a small Excel deliverable for ad-hoc analysis and documentation

The project was designed with a junior Data Analyst role in mind, with a strong focus on:
- SQL
- data modeling logic
- KPI consistency
- analytical documentation
- dashboard communication

---

## Business Goal

The project aims to answer questions such as:
- How did sales evolve month by month in 2017?
- Which product categories generated the highest revenue?
- How many orders and customers contributed to sales performance?
- What customer behavior patterns can be identified from order history?

---

## Dataset

Source dataset: **Olist Brazilian E-commerce Public Dataset**

Main entities used in the project:
- customers
- orders
- order_items
- products
- product category translation table

The project uses a clean analytical layer built on top of the raw tables instead of querying raw tables directly in every analysis.

---

## Analytical Scope

This project focuses on **2017** and uses a **delivered-only KPI scope** for the main business metrics.

Core KPI logic:
- **Revenue** = sum of `order_items.price`
- **Orders** = delivered orders only
- **Customers** = customers with delivered orders only
- **AOV** = delivered revenue / delivered orders

This choice was made to keep all core business KPIs aligned to the same population of completed orders.

---

## Key Business Assumptions

### 1. Revenue definition
Revenue is defined as the sum of `order_items.price`.

Notes:
- shipping costs are not included
- payment installments are not used as revenue
- the project uses item-level price as the main sales measure

### 2. Delivered-only KPI scope
Main KPI analysis is restricted to orders with `order_status = 'delivered'`.

This avoids mixing completed sales with non-delivered orders that may still have rows in `order_items`.

### 3. Customer identifier
In the analytical layer, `customer_unique_id` is used as the customer identifier.

This simplifies customer-level analysis by resolving the raw `customer_id -> customer_unique_id` mapping once in the analytical layer.

### 4. Customer location assumption
The analytical `customers` view keeps one row per unique customer and retains representative location fields using aggregated values.

In practice, the view uses `min(customer_city)` and `min(customer_state)` to preserve one row per `customer_unique_id` while keeping customer-level analysis simple and consistent.

---

## Project Structure

```text
ecommerce-sales-customer-analysis/
├─ 01_sql/
│  ├─ 00_create_views.sql
│  ├─ 01_data_checks.sql
│  ├─ 02_core_kpis.sql
│  └─ 03_customer_analysis.sql
├─ 02_powerbi/
│  └─ ecommerce_dashboard.pbix
├─ 03_excel/
│  └─ e_commerce_excel.xlsx
├─ 04_data/
│  ├─ cleaned/
│  │  ├─ customers.csv
│  │  ├─ order_items.csv
│  │  ├─ orders.csv
│  │  └─ products.csv
│  └─ raw/
│     ├─ olist_customers_dataset.csv
│     ├─ olist_order_items_dataset.csv
│     ├─ olist_orders_dataset.csv
│     ├─ olist_products_dataset.csv
│     └─ product_category_name_translation.csv
├─ 05_images/
│  ├─ dashboard_powerbi.png
│  └─ pivot_table_excel.png
└─ README.md
```

---

## SQL Analysis

The SQL part of the project is organized into four files:

### `00_create_views.sql`
Creates the analytical views used throughout the project.

The analytical layer includes:
- a `customers` view with one row per unique customer
- an `orders` view that resolves the raw customer mapping and renames the purchase timestamp as `order_date`
- an `order_items` view with the item-level revenue field
- a `products` view with translated category names when available

### `01_data_checks.sql`
Runs data quality checks before KPI analysis.

The checks cover:
- duplicate keys in core analytical tables
- critical null values
- invalid item prices
- orphan records across joins
- orders without matching `order_items`
- final row counts by table

### `02_core_kpis.sql`
Calculates the main business KPIs for the 2017 delivered-order scope.

The file includes queries for:
- total delivered revenue in 2017
- monthly delivered revenue
- monthly delivered orders
- revenue by category
- average order value by month
- non-delivered orders with items, grouped by status

### `03_customer_analysis.sql`
Explores customer-level behavior for 2017.

The analysis includes:
- one-time vs repeat customers
- top 10 customers by revenue
- customers active in H1 but inactive in H2
- customers with H2 AOV higher than H1 AOV
- customers whose last active month outperformed the previous one
- customers whose top category accounts for more than 50% of their revenue

### SQL design notes
Particular attention was given to:
- analytical grain
- separating KPI logic from data quality checks
- keeping business definitions consistent across SQL, Power BI, and Excel
- using readable multi-step logic with CTEs where needed

---

## Data Quality Checks

The project includes dedicated data quality checks to validate the analytical layer before KPI reporting.

These checks verify:
- uniqueness of analytical identifiers
- completeness of critical fields
- price validity
- join consistency across customers, orders, order_items, and products
- table-level row counts after view creation

An important clarification is that the check on **orders without matching `order_items`** should be interpreted as a **data quality / model consistency check**, not as a proxy for failed orders.

This distinction matters because:
- order status analysis is a business topic
- missing item matches are a data consistency topic

The two should not be mixed.

---

## Power BI Dashboard

The Power BI dashboard provides a compact business overview for **delivered orders in 2017**.

### KPI cards
- Revenue
- Orders
- Customers
- AOV

### Visuals
- Revenue by Month
- Revenue by Category
- Orders by Month
- AOV by Month

### Filter scope
The dashboard uses:
- `Order Year = 2017`
- `order_status = delivered`

A cleaned category label was also created to remove underscores and improve chart readability.

![Power BI Dashboard](05_images/dashboard_powerbi.png)

---

## Excel Analysis

The Excel deliverable was created to provide a lightweight business-style summary outside SQL and Power BI.

The file contains three sheets:
1. `Order_Level_2017`
2. `Pivot_State_Analysis`
3. `Data_Dictionary`

### Excel dataset logic
The order-level sheet contains delivered orders from 2017 with:
- `order_id`
- `customer_id`
- `customer_state`
- `order_date`
- `order_value`

### Pivot summary
The pivot table aggregates performance by customer state using:
- **Revenue** = sum of `order_value`
- **Orders** = count of `order_id`
- **AOV** = average of `order_value`

### Data Dictionary
A small data dictionary was added to document:
- table names
- column meanings
- analytical grain
- important business notes

![Excel Pivot Analysis](05_images/pivot_table_excel.png)

---

## Business Insights

Based on the delivered-order scope for 2017, the analysis highlights a few clear business patterns.

- The business generated approximately **$5.96M** in delivered revenue from about **43K delivered orders** and **42K customers**, with an overall **AOV of $137.31**.
- Revenue and order volume increased across the year and peaked in **November**, pointing to strong late-year seasonality.
- AOV fluctuated within a relatively narrower range than revenue and orders, suggesting that growth was driven more by **order volume** than by a major increase in average ticket size.
- Revenue was concentrated in a limited set of categories, with **bed bath table**, **watches gifts**, **health beauty**, and **sports leisure** among the leading contributors.
- Performance was also geographically concentrated: **SP** was the leading state by revenue, followed by **RJ** and **MG**, showing that a few regions accounted for a substantial share of sales.
- Beyond descriptive KPIs, the SQL section also explores customer behavior patterns such as repeat purchasing, inactivity between H1 and H2, customer-level AOV changes, and category concentration.

---

## Skills Demonstrated

This project demonstrates:
- strong SQL foundations for junior data analytics
- understanding of KPI scope and analytical grain
- ability to separate business analysis from data quality checks
- basic but solid Power BI dashboard design
- clear Excel-based documentation and summary reporting

---

## How to Reproduce

1. Load the raw Olist dataset into MySQL.
2. Create the cleaned analytical views.
3. Run the data quality checks.
4. Run the KPI and customer analysis queries.
5. Open the Power BI file to explore the visual dashboard.
6. Open the Excel file to review the state-level pivot summary and data dictionary.

---

## Author Note

This project was built as a portfolio project for entry-level Data Analyst roles, with the intention of showing not only technical querying ability, but also business reasoning, metric consistency, and clear analytical communication.