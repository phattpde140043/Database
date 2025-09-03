-- Create databases for bronze layer corresponding to source databases
CREATE DATABASE IF NOT EXISTS bronze_pos;
CREATE DATABASE IF NOT EXISTS bronze_logistic;
CREATE DATABASE IF NOT EXISTS bronze_erp;

-- Bronze tables for PoS_Database (raw data load, Delta format for streaming ELT)
-- Tables are created as Delta tables to support streaming loads and merges in Databricks

-- customers
CREATE TABLE IF NOT EXISTS bronze_pos.customers (
  customer_id STRING COMMENT 'Unique identifier for customers, auto-generated as CUST_XXX via trigger',
  name STRING NOT NULL COMMENT 'Full name of the customer',
  email BINARY COMMENT 'Unique email address of the customer',
  phone BINARY COMMENT 'Unique phone number of the customer',
  address STRING NOT NULL COMMENT 'Customer''s primary address',
  created_at TIMESTAMP NOT NULL COMMENT 'Timestamp of customer record creation',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to customer record'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');  -- Enable CDF for streaming and ELT

-- products
CREATE TABLE IF NOT EXISTS bronze_pos.products (
  product_id STRING COMMENT 'Unique identifier for products, auto-generated as PROD_XXX via trigger',
  name STRING NOT NULL COMMENT 'Name of the product',
  category_id BIGINT NOT NULL COMMENT 'References category_id in categories table',
  created_at TIMESTAMP NOT NULL COMMENT 'Timestamp of product record creation',
  deleted_at TIMESTAMP COMMENT 'Timestamp of product soft deletion, null if active'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- products_sku
CREATE TABLE IF NOT EXISTS bronze_pos.products_sku (
  sku_id BIGINT COMMENT 'Unique auto-incremented identifier for SKU',
  sku STRING COMMENT 'Unique stock keeping unit code',
  product_id STRING NOT NULL COMMENT 'References product_id in products table',
  color STRING COMMENT 'Color attribute of the SKU',
  size STRING COMMENT 'Size attribute of the SKU',
  price DECIMAL(10,2) NOT NULL COMMENT 'Price of the SKU',
  created_at TIMESTAMP NOT NULL COMMENT 'Timestamp of SKU record creation',
  deleted_at TIMESTAMP COMMENT 'Timestamp of product soft deletion, null if active'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- categories
CREATE TABLE IF NOT EXISTS bronze_pos.categories (
  category_id BIGINT COMMENT 'Unique auto-incremented identifier for categories',
  name STRING NOT NULL COMMENT 'Name of the product category',
  created_at TIMESTAMP NOT NULL COMMENT 'Timestamp of category record creation',
  deleted_at TIMESTAMP COMMENT 'Timestamp of category soft deletion, null if active'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- orders
CREATE TABLE IF NOT EXISTS bronze_pos.orders (
  order_id BIGINT COMMENT 'Unique auto-incremented identifier for orders',
  customer_id STRING NOT NULL COMMENT 'References customer_id in customers table',
  order_date TIMESTAMP NOT NULL COMMENT 'Timestamp of order creation',
  total_amount DECIMAL(12,2) NOT NULL COMMENT 'Total amount of the order, calculated from order_items',
  shipping_address STRING NOT NULL COMMENT 'Shipping address for the order, defaults to customer address',
  payment_type_id INT NOT NULL COMMENT 'References payment_type_id in payment_types table',
  payment_status STRING NOT NULL COMMENT 'Payment status of the order'
) USING DELTA
PARTITIONED BY (order_date)  -- Partition by order_date for range-based optimization in streaming
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- order_items
CREATE TABLE IF NOT EXISTS bronze_pos.order_items (
  order_item_id BIGINT COMMENT 'Unique auto-incremented identifier for order items',
  order_id BIGINT NOT NULL COMMENT 'References order_id in orders table',
  product_id STRING NOT NULL COMMENT 'References product_id in products table',
  sku_id BIGINT NOT NULL COMMENT 'References sku_id in products_sku table',
  quantity INT NOT NULL COMMENT 'Quantity of the product in the order',
  unit_price DECIMAL(10,2) NOT NULL COMMENT 'Unit price of the product, defaults to SKU price times quantity',
  order_date TIMESTAMP NOT NULL COMMENT 'Timestamp of order creation'
) USING DELTA
PARTITIONED BY (order_date)  -- Partition by order_date with sub-hash consideration simulated via partitioning
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- payment_types
CREATE TABLE IF NOT EXISTS bronze_pos.payment_types (
  payment_type_id INT COMMENT 'Unique auto-incremented identifier for payment types',
  name STRING NOT NULL COMMENT 'Name of the payment type'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- product_view (treated as materialized view in bronze for raw load, but as table for simplicity)
CREATE TABLE IF NOT EXISTS bronze_pos.product_view (
  sku_id BIGINT COMMENT 'Identifier for SKU (inherited from source table)',
  sku STRING COMMENT 'Unique stock keeping unit code',
  product_id STRING COMMENT 'References product_id in products table (logical only)',
  color STRING COMMENT 'Color attribute of the SKU',
  size STRING COMMENT 'Size attribute of the SKU',
  price DECIMAL(10,2) COMMENT 'Price of the SKU',
  created_at TIMESTAMP COMMENT 'Timestamp of SKU record creation',
  product_name STRING COMMENT 'Name of the product',
  category_id BIGINT COMMENT 'References category_id in categories table (logical only)',
  category_name STRING COMMENT 'Name of the product category'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- sales_report_view (treated as materialized view in bronze for raw load, but as table for simplicity)
CREATE TABLE IF NOT EXISTS bronze_pos.sales_report_view (
  order_id BIGINT COMMENT 'Identifier for the order (inherited from source table)',
  order_date TIMESTAMP COMMENT 'Timestamp of order creation',
  customer_id STRING COMMENT 'References customer_id in customers table (logical only)',
  customer_name STRING COMMENT 'Full name of the customer',
  total_amount DECIMAL(12,2) COMMENT 'Total amount of the order',
  shipping_address STRING COMMENT 'Shipping address for the order',
  payment_status STRING COMMENT 'Payment status of the order',
  payment_types STRING COMMENT 'Name of the payment type',
  item_count INT COMMENT 'Total number of items in the order (calculated)',
  sku STRING COMMENT 'Unique stock keeping unit code',
  product_name STRING COMMENT 'Name of the product',
  price DECIMAL(10,2) COMMENT 'Price of the SKU',
  quantity INT COMMENT 'Quantity of the product in the order'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- Bronze tables for Logistic_Database

-- warehouses
CREATE TABLE IF NOT EXISTS bronze_logistic.warehouses (
  warehouse_id BIGINT COMMENT 'Unique auto-incremented identifier for warehouses',
  name STRING NOT NULL COMMENT 'Name of the warehouse',
  location STRING NOT NULL COMMENT 'Location of the warehouse',
  created_at TIMESTAMP NOT NULL COMMENT 'Timestamp of warehouse record creation',
  deleted_at TIMESTAMP COMMENT 'Timestamp of warehouse soft deletion, null if active'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- inventory
CREATE TABLE IF NOT EXISTS bronze_logistic.inventory (
  inventory_id BIGINT COMMENT 'Unique auto-incremented identifier for inventory records',
  warehouse_id BIGINT NOT NULL COMMENT 'References warehouse_id in warehouses table',
  product_id STRING NOT NULL COMMENT 'Product identifier, validated via API',
  sku_id BIGINT NOT NULL COMMENT 'SKU identifier, validated via API',
  stock_quantity INT NOT NULL COMMENT 'Quantity of stock in the warehouse',
  last_updated TIMESTAMP NOT NULL COMMENT 'Timestamp of last inventory update'
) USING DELTA
PARTITIONED BY (product_id)  -- Partition by product_id for hash-based optimization
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- shipments
CREATE TABLE IF NOT EXISTS bronze_logistic.shipments (
  shipment_id BIGINT COMMENT 'Unique auto-incremented identifier for shipments',
  order_id BIGINT NOT NULL COMMENT 'Order identifier, validated via API',
  warehouse_id BIGINT NOT NULL COMMENT 'References warehouse_id in warehouses table',
  shipment_date TIMESTAMP NOT NULL COMMENT 'Timestamp of shipment creation',
  status STRING NOT NULL COMMENT 'Status of the shipment'
) USING DELTA
PARTITIONED BY (shipment_date)  -- Partition by shipment_date for range-based optimization
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- delivery_tracking
CREATE TABLE IF NOT EXISTS bronze_logistic.delivery_tracking (
  tracking_id BIGINT COMMENT 'Unique auto-incremented identifier for tracking records',
  shipment_id BIGINT NOT NULL COMMENT 'References shipment_id in shipments table',
  shipment_date TIMESTAMP NOT NULL COMMENT 'Timestamp of shipment creation',
  checkpoint_time TIMESTAMP NOT NULL COMMENT 'Timestamp of tracking checkpoint',
  location STRING NOT NULL COMMENT 'Location of the tracking checkpoint',
  status STRING NOT NULL COMMENT 'Status of the tracking record'
) USING DELTA
PARTITIONED BY (checkpoint_time)  -- Partition by checkpoint_time for range-based optimization
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- shipping_report_view (treated as table for simplicity)
CREATE TABLE IF NOT EXISTS bronze_logistic.shipping_report_view (
  shipment_id BIGINT COMMENT 'Unique auto-incremented identifier for shipments',
  order_id BIGINT COMMENT 'Order identifier, validated via API',
  warehouse_id BIGINT COMMENT 'References warehouse_id in warehouses table',
  warehouse_name STRING COMMENT 'Name of the warehouse',
  location STRING COMMENT 'Location of the warehouse',
  shipment_date TIMESTAMP COMMENT 'Timestamp of shipment creation',
  checkpoint_time TIMESTAMP COMMENT 'Timestamp of tracking checkpoint',
  checkpoint_location STRING COMMENT 'Location of the tracking checkpoint',
  status STRING COMMENT 'Status of the shipment'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- inventory_report_view (treated as table for simplicity)
CREATE TABLE IF NOT EXISTS bronze_logistic.inventory_report_view (
  sku_id BIGINT COMMENT 'Identifier for SKU (inherited from source table)',
  product_id STRING COMMENT 'References product_id in products table (logical only)',
  stock_quantity INT COMMENT 'Quantity of stock in the warehouse',
  last_updated TIMESTAMP COMMENT 'Timestamp of last inventory update',
  warehouse_id BIGINT COMMENT 'References warehouse_id in warehouses table (logical only)',
  warehouse_name STRING COMMENT 'Name of the warehouse',
  location STRING COMMENT 'Location of the warehouse'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- Bronze tables for ERP_Database

-- employees
CREATE TABLE IF NOT EXISTS bronze_erp.employees (
  employee_id STRING COMMENT 'Unique identifier for employees, auto-generated as EMP_XXX via trigger',
  name STRING NOT NULL COMMENT 'Full name of the employee',
  email STRING COMMENT 'Unique email address of the employee',
  department_id BIGINT NOT NULL COMMENT 'References department_id in departments table',
  hire_date TIMESTAMP NOT NULL COMMENT 'Timestamp of employee hire date',
  salary DECIMAL(12,2) NOT NULL COMMENT 'Salary of the employee',
  deleted_at TIMESTAMP COMMENT 'Timestamp of employee soft deletion, null if active'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- departments
CREATE TABLE IF NOT EXISTS bronze_erp.departments (
  department_id BIGINT COMMENT 'Unique auto-incremented identifier for departments',
  name STRING NOT NULL COMMENT 'Name of the department'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- suppliers
CREATE TABLE IF NOT EXISTS bronze_erp.suppliers (
  supplier_id BIGINT COMMENT 'Unique auto-incremented identifier for suppliers',
  name STRING NOT NULL COMMENT 'Name of the supplier',
  contact_name STRING NOT NULL COMMENT 'Name of the supplier''s contact person',
  phone STRING NOT NULL COMMENT 'Phone number of the supplier',
  email STRING NOT NULL COMMENT 'Email address of the supplier',
  created_at TIMESTAMP NOT NULL COMMENT 'Timestamp of supplier record creation',
  deleted_at TIMESTAMP COMMENT 'Timestamp of supplier soft deletion, null if active'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- purchase_orders
CREATE TABLE IF NOT EXISTS bronze_erp.purchase_orders (
  po_id BIGINT COMMENT 'Unique auto-incremented identifier for purchase orders',
  supplier_id BIGINT NOT NULL COMMENT 'References supplier_id in suppliers table',
  order_date TIMESTAMP NOT NULL COMMENT 'Timestamp of purchase order creation',
  status STRING COMMENT 'Status of the purchase order',
  total_amount DECIMAL(12,2) NOT NULL COMMENT 'Total amount of the purchase order, calculated from items'
) USING DELTA
PARTITIONED BY (order_date)  -- Partition by order_date for range-based optimization
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- purchase_order_items
CREATE TABLE IF NOT EXISTS bronze_erp.purchase_order_items (
  po_item_id BIGINT COMMENT 'Unique auto-incremented identifier for purchase order items',
  po_id BIGINT NOT NULL COMMENT 'References po_id in purchase_orders table',
  product_id STRING NOT NULL COMMENT 'Product identifier, validated via API',
  quantity INT NOT NULL COMMENT 'Quantity of the product in the purchase order',
  unit_price DECIMAL(10,2) NOT NULL COMMENT 'Unit price of the product in the purchase order',
  order_date TIMESTAMP NOT NULL COMMENT 'Timestamp of purchase order creation'
) USING DELTA
PARTITIONED BY (order_date)  -- Partition by order_date with sub-hash simulation
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- financial_transactions
CREATE TABLE IF NOT EXISTS bronze_erp.financial_transactions (
  transaction_id BIGINT COMMENT 'Unique auto-incremented identifier for financial transactions',
  transaction_date TIMESTAMP NOT NULL COMMENT 'Timestamp of the financial transaction',
  account_id BIGINT NOT NULL COMMENT 'References account_id in accounts table',
  amount DECIMAL(12,2) NOT NULL COMMENT 'Amount of the financial transaction',
  type STRING COMMENT 'Type of the financial transaction',
  status STRING COMMENT 'Status of the financial transaction'
) USING DELTA
PARTITIONED BY (transaction_date)  -- Partition by transaction_date for range-based optimization
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- accounts
CREATE TABLE IF NOT EXISTS bronze_erp.accounts (
  account_id BIGINT COMMENT 'Unique auto-incremented identifier for accounts',
  account_name STRING NOT NULL COMMENT 'Name of the account',
  account_type STRING NOT NULL COMMENT 'Type of the account'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');