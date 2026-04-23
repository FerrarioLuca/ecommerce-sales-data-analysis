import pandas as pd


# Read a CSV file into a pandas DataFrame
def read_csv(path):
    df = pd.read_csv(path)
    return df


# Write a pandas DataFrame to CSV without the index column
def write_csv(df, path):
    df.to_csv(path, index=False)


# Build the cleaned customers layer:
# - keep only analytical columns
# - trim text fields
# - keep one row per real customer
# - rename customer_unique_id to customer_id
def build_customers(raw_customers):
    customers = raw_customers[[
        "customer_unique_id",
        "customer_city",
        "customer_state"
    ]].copy()

    customers["customer_city"] = customers["customer_city"].astype(str).str.strip()
    customers["customer_state"] = customers["customer_state"].astype(str).str.strip()

    # Data quality check: Brazilian state code should have length 2
    invalid_state_length_count = (customers["customer_state"].str.len() != 2).sum()

    customers = customers.drop_duplicates(subset=["customer_unique_id"])

    customers = customers.rename(columns={
        "customer_unique_id": "customer_id"
    })

    return customers, invalid_state_length_count


# Build the cleaned orders layer:
# - map raw customer_id to customer_unique_id
# - validate order_status values
# - parse order date
# - drop rows with missing customer mapping or invalid date
def build_orders(raw_orders, raw_customers):
    # Bridge table used to replace raw customer_id with customer_unique_id
    customer_bridge = raw_customers[[
        "customer_id",
        "customer_unique_id"
    ]].copy()

    orders = raw_orders.merge(
        customer_bridge,
        on="customer_id",
        how="left"
    )

    orders = orders[[
        "order_id",
        "customer_unique_id",
        "order_purchase_timestamp",
        "order_status"
    ]].copy()

    orders["order_status"] = orders["order_status"].astype(str).str.strip()

    expected_statuses = {
        "created",
        "approved",
        "invoiced",
        "processing",
        "shipped",
        "delivered",
        "canceled",
        "unavailable"
    }

    # Count status values outside the expected set
    invalid_status_count = (~orders["order_status"].isin(expected_statuses)).sum()

    # Convert raw timestamp to datetime; invalid values become NaT
    orders["order_purchase_timestamp"] = pd.to_datetime(
        orders["order_purchase_timestamp"],
        errors="coerce"
    )

    invalid_order_date_count = orders["order_purchase_timestamp"].isna().sum()

    # Keep only rows with valid customer mapping and valid order date
    orders = orders.dropna(subset=["customer_unique_id", "order_purchase_timestamp"]).copy()

    orders = orders.rename(columns={
        "customer_unique_id": "customer_id",
        "order_purchase_timestamp": "order_date"
    })

    return orders, invalid_status_count, invalid_order_date_count


# Build the cleaned order_items layer:
# - keep only analytical columns
# - convert price to numeric
# - remove invalid or non-positive prices
def build_order_items(raw_order_items):
    order_items = raw_order_items[[
        "order_id",
        "order_item_id",
        "product_id",
        "price"
    ]].copy()

    order_items["price"] = pd.to_numeric(order_items["price"], errors="coerce")

    # Count prices that cannot be converted to numeric
    invalid_price_count = order_items["price"].isna().sum()

    order_items = order_items.dropna(subset=["price"]).copy()

    # Count prices that are numeric but not valid for analysis
    non_positive_price_count = (order_items["price"] <= 0).sum()

    order_items = order_items[order_items["price"] > 0].copy()

    return order_items, invalid_price_count, non_positive_price_count


# Build the cleaned products layer:
# - translate product categories to English when possible
# - keep original category as fallback if translation is missing
def build_products(raw_products, category_translation):
    translation = category_translation.rename(columns={
        "product_category_name": "raw_category",
        "product_category_name_english": "category"
    }).copy()

    translation["raw_category"] = translation["raw_category"].astype(str).str.strip()
    translation["category"] = translation["category"].astype(str).str.strip()

    products = raw_products[[
        "product_id",
        "product_category_name"
    ]].copy()

    products = products.rename(columns={
        "product_category_name": "raw_category"
    })

    products["raw_category"] = products["raw_category"].astype(str).str.strip()

    products = products.merge(
        translation,
        on="raw_category",
        how="left"
    )

    # Count translated and untranslated categories before fallback
    translated_count = products["category"].notna().sum()
    untranslated_count = products["category"].isna().sum()

    products["category"] = products["category"].fillna(products["raw_category"])

    products = products[[
        "product_id",
        "category"
    ]].copy()

    return products, translated_count, untranslated_count


# Main ETL flow:
# - read raw CSV files
# - build cleaned analytical layers
# - write cleaned CSV outputs
# - print a small ETL summary
def main():
    raw_customers_path = "04_data/raw/olist_customers_dataset.csv"
    raw_orders_path = "04_data/raw/olist_orders_dataset.csv"
    raw_order_items_path = "04_data/raw/olist_order_items_dataset.csv"
    raw_products_path = "04_data/raw/olist_products_dataset.csv"
    translation_path = "04_data/raw/product_category_name_translation.csv"

    customers_output_path = "04_data/cleaned/customers.csv"
    orders_output_path = "04_data/cleaned/orders.csv"
    order_items_output_path = "04_data/cleaned/order_items.csv"
    products_output_path = "04_data/cleaned/products.csv"

    raw_customers = read_csv(raw_customers_path)
    raw_orders = read_csv(raw_orders_path)
    raw_order_items = read_csv(raw_order_items_path)
    raw_products = read_csv(raw_products_path)
    category_translation = read_csv(translation_path)

    customers, invalid_state_length_count = build_customers(raw_customers)
    orders, invalid_status_count, invalid_order_date_count = build_orders(raw_orders, raw_customers)
    order_items, invalid_price_count, non_positive_price_count = build_order_items(raw_order_items)
    products, translated_count, untranslated_count = build_products(raw_products, category_translation)

    write_csv(customers, customers_output_path)
    write_csv(orders, orders_output_path)
    write_csv(order_items, order_items_output_path)
    write_csv(products, products_output_path)

    print("Clean layer created successfully")
    print("Raw customers rows:", len(raw_customers))
    print("Clean customers rows:", len(customers))
    print("Invalid customer_state length:", invalid_state_length_count)
    print("Raw orders rows:", len(raw_orders))
    print("Clean orders rows:", len(orders))
    print("Invalid order_status values:", invalid_status_count)
    print("Invalid order_date values:", invalid_order_date_count)
    print("Raw order_items rows:", len(raw_order_items))
    print("Clean order_items rows:", len(order_items))
    print("Invalid price rows removed:", invalid_price_count)
    print("Non-positive price rows removed:", non_positive_price_count)
    print("Raw products rows:", len(raw_products))
    print("Clean products rows:", len(products))
    print("Translated categories:", translated_count)
    print("Untranslated categories:", untranslated_count)


if __name__ == "__main__":
    main()