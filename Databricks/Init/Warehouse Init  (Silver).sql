-- Databricks notebook source
CREATE CATALOG silver_layer;

-- COMMAND ----------

USE CATALOG  silver_layer;

-- COMMAND ----------

CREATE DATABASE IF NOT EXISTS silver_database;

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.customers (
  customer_id STRING COMMENT 'Unique identifier for customers, auto-generated as CUST_XXX via trigger',
  name STRING NOT NULL COMMENT 'Full name of the customer',
  email BINARY COMMENT 'Unique email address of the customer',
  phone BINARY COMMENT 'Unique phone number of the customer',
  address STRING NOT NULL COMMENT 'Customer primary address',
  created_at TIMESTAMP NOT NULL COMMENT 'Timestamp of customer record creation',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to customer record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');  -- Enable CDF for streaming and ELT

-- COMMAND ----------

-- Ràng buộc NOT NULL cho tất cả các cột
ALTER TABLE silver_database.customers ALTER COLUMN customer_id SET NOT NULL;
ALTER TABLE silver_database.customers ALTER COLUMN name SET NOT NULL;
ALTER TABLE silver_database.customers ALTER COLUMN email SET NOT NULL;
ALTER TABLE silver_database.customers ALTER COLUMN phone SET NOT NULL;
ALTER TABLE silver_database.customers ALTER COLUMN address SET NOT NULL;
ALTER TABLE silver_database.customers ALTER COLUMN created_at SET NOT NULL;
ALTER TABLE silver_database.customers ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE silver_database.customers ALTER COLUMN ingestion_time SET NOT NULL;

-- Ràng buộc CHECK cho các cột ngày tháng
ALTER TABLE silver_database.customers ADD CONSTRAINT chk_created_at CHECK (created_at < current_timestamp());
ALTER TABLE silver_database.customers ADD CONSTRAINT chk_updated_at CHECK (updated_at IS NULL OR updated_at < current_timestamp());
ALTER TABLE silver_database.customers ADD CONSTRAINT chk_ingestion_time CHECK (ingestion_time IS NULL OR ingestion_time < current_timestamp());

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.customers ADD CONSTRAINT chk_customer_id_length CHECK (length(customer_id) > 0);
ALTER TABLE silver_database.customers ADD CONSTRAINT chk_name_length CHECK (length(name) > 0);
ALTER TABLE silver_database.customers ADD CONSTRAINT chk_address_length CHECK (length(address) > 0);

-- Ràng buộc CHECK cho các cột binary (email, phone) nếu muốn kiểm tra độ dài
ALTER TABLE silver_database.customers ADD CONSTRAINT chk_email_length CHECK (length(email) > 0);
ALTER TABLE silver_database.customers ADD CONSTRAINT chk_phone_length CHECK (length(phone) > 0);

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.products_sku (
  sku_id BIGINT COMMENT 'Unique auto-incremented identifier for SKU',
  sku STRING COMMENT 'Unique stock keeping unit code',
  product_id STRING NOT NULL COMMENT 'References product_id in products table',
  color STRING COMMENT 'Color attribute of the SKU',
  size STRING COMMENT 'Size attribute of the SKU',
  price DECIMAL(10,2) NOT NULL COMMENT 'Price of the SKU',
  created_at TIMESTAMP NOT NULL COMMENT 'Timestamp of SKU record creation',
  deleted_at TIMESTAMP COMMENT 'Timestamp of product soft deletion, null if active',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to product sku record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

ALTER TABLE silver_database.products_sku ADD CONSTRAINT chk_created_at CHECK (created_at < current_timestamp());

ALTER TABLE silver_database.products_sku ADD CONSTRAINT chk_deleted_at CHECK (deleted_at IS NULL OR deleted_at < current_timestamp());

ALTER TABLE silver_database.products_sku ADD CONSTRAINT chk_updated_at CHECK (updated_at IS NULL OR updated_at < current_timestamp());

ALTER TABLE silver_database.products_sku ADD CONSTRAINT chk_ingestion_time CHECK (ingestion_time IS NULL OR ingestion_time < current_timestamp());

ALTER TABLE silver_database.products_sku ADD CONSTRAINT chk_price_non_negative CHECK (price >= 0);

ALTER TABLE silver_database.products_sku ADD CONSTRAINT chk_sku_length CHECK (length(sku) > 0);

ALTER TABLE silver_database.products_sku ADD CONSTRAINT chk_product_id_length CHECK (length(product_id) > 0);

ALTER TABLE silver_database.products_sku ADD CONSTRAINT chk_color_length CHECK (color IS NULL OR length(color) > 0);

ALTER TABLE silver_database.products_sku ADD CONSTRAINT chk_size_length CHECK (size IS NULL OR length(size) > 0);

ALTER TABLE silver_database.products_sku ALTER COLUMN sku_id SET NOT NULL;
ALTER TABLE silver_database.products_sku ALTER COLUMN sku SET NOT NULL;
ALTER TABLE silver_database.products_sku ALTER COLUMN color SET NOT NULL;
ALTER TABLE silver_database.products_sku ALTER COLUMN size SET NOT NULL;
ALTER TABLE silver_database.products_sku ALTER COLUMN price SET NOT NULL;
ALTER TABLE silver_database.products_sku ALTER COLUMN created_at SET NOT NULL;
ALTER TABLE silver_database.products_sku ALTER COLUMN product_id SET NOT NULL;

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.products (
  product_id STRING COMMENT 'Unique identifier for products, auto-generated as PROD_XXX via trigger',
  name STRING NOT NULL COMMENT 'Name of the product',
  category_id BIGINT NOT NULL COMMENT 'References category_id in categories table',
  created_at TIMESTAMP NOT NULL COMMENT 'Timestamp of product record creation',
  deleted_at TIMESTAMP COMMENT 'Timestamp of product soft deletion, null if active',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to product record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho tất cả các cột
ALTER TABLE silver_database.products ALTER COLUMN product_id SET NOT NULL;
ALTER TABLE silver_database.products ALTER COLUMN name SET NOT NULL;
ALTER TABLE silver_database.products ALTER COLUMN category_id SET NOT NULL;
ALTER TABLE silver_database.products ALTER COLUMN created_at SET NOT NULL;
ALTER TABLE silver_database.products ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE silver_database.products ALTER COLUMN ingestion_time SET NOT NULL;

-- Ràng buộc CHECK cho các cột ngày tháng
ALTER TABLE silver_database.products ADD CONSTRAINT chk_created_at CHECK (created_at < current_timestamp());
ALTER TABLE silver_database.products ADD CONSTRAINT chk_deleted_at CHECK (deleted_at IS NULL OR deleted_at < current_timestamp());
ALTER TABLE silver_database.products ADD CONSTRAINT chk_updated_at CHECK (updated_at < current_timestamp());
ALTER TABLE silver_database.products ADD CONSTRAINT chk_ingestion_time CHECK (ingestion_time < current_timestamp());

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.products ADD CONSTRAINT chk_product_id_length CHECK (length(product_id) > 0);
ALTER TABLE silver_database.products ADD CONSTRAINT chk_name_length CHECK (length(name) > 0);

-- COMMAND ----------

-- categories
CREATE TABLE IF NOT EXISTS silver_database.categories (
  category_id BIGINT COMMENT 'Unique auto-incremented identifier for categories',
  name STRING NOT NULL COMMENT 'Name of the product category',
  created_at TIMESTAMP NOT NULL COMMENT 'Timestamp of category record creation',
  deleted_at TIMESTAMP COMMENT 'Timestamp of category soft deletion, null if active',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to category record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho tất cả các cột
ALTER TABLE silver_database.categories ALTER COLUMN category_id SET NOT NULL;
ALTER TABLE silver_database.categories ALTER COLUMN name SET NOT NULL;
ALTER TABLE silver_database.categories ALTER COLUMN created_at SET NOT NULL;

-- Ràng buộc CHECK cho các cột ngày tháng
ALTER TABLE silver_database.categories ADD CONSTRAINT chk_created_at CHECK (created_at < current_timestamp());
ALTER TABLE silver_database.categories ADD CONSTRAINT chk_deleted_at CHECK (deleted_at IS NULL OR deleted_at < current_timestamp());
ALTER TABLE silver_database.categories ADD CONSTRAINT chk_updated_at CHECK (updated_at < current_timestamp());
ALTER TABLE silver_database.categories ADD CONSTRAINT chk_ingestion_time CHECK (ingestion_time < current_timestamp());

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.categories ADD CONSTRAINT chk_name_length CHECK (length(name) > 0);

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.accounts (
  account_id BIGINT COMMENT 'Unique auto-incremented identifier for accounts',
  account_name STRING NOT NULL COMMENT 'Name of the account',
  account_type STRING NOT NULL COMMENT 'Type of the account',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to category record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho các cột cần thiết
ALTER TABLE silver_database.accounts ALTER COLUMN account_id SET NOT NULL;
ALTER TABLE silver_database.accounts ALTER COLUMN account_name SET NOT NULL;
ALTER TABLE silver_database.accounts ALTER COLUMN account_type SET NOT NULL;

-- Ràng buộc CHECK cho các cột số
ALTER TABLE silver_database.accounts ADD CONSTRAINT chk_account_id_positive CHECK (account_id > 0);

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.accounts ADD CONSTRAINT chk_account_name_length CHECK (length(account_name) > 0);
ALTER TABLE silver_database.accounts ADD CONSTRAINT chk_account_type_length CHECK (length(account_type) > 0);

ALTER TABLE silver_database.accounts ADD CONSTRAINT chk_updated_at CHECK (updated_at IS NULL OR updated_at < current_timestamp());

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.delivery_tracking (
  tracking_id BIGINT COMMENT 'Unique auto-incremented identifier for tracking records',
  shipment_id BIGINT NOT NULL COMMENT 'References shipment_id in shipments table',
  shipment_date TIMESTAMP NOT NULL COMMENT 'Timestamp of shipment creation',
  checkpoint_time TIMESTAMP NOT NULL COMMENT 'Timestamp of tracking checkpoint',
  location STRING NOT NULL COMMENT 'Location of the tracking checkpoint',
  status STRING NOT NULL COMMENT 'Status of the tracking record',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to category record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
PARTITIONED BY (checkpoint_time)  -- Partition by checkpoint_time for range-based optimization
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho tất cả các cột
ALTER TABLE silver_database.delivery_tracking ALTER COLUMN tracking_id SET NOT NULL;
ALTER TABLE silver_database.delivery_tracking ALTER COLUMN shipment_id SET NOT NULL;
ALTER TABLE silver_database.delivery_tracking ALTER COLUMN shipment_date SET NOT NULL;
ALTER TABLE silver_database.delivery_tracking ALTER COLUMN checkpoint_time SET NOT NULL;
ALTER TABLE silver_database.delivery_tracking ALTER COLUMN location SET NOT NULL;
ALTER TABLE silver_database.delivery_tracking ALTER COLUMN status SET NOT NULL;

-- Ràng buộc CHECK cho các cột ngày tháng
ALTER TABLE silver_database.delivery_tracking ADD CONSTRAINT chk_shipment_date CHECK (shipment_date < current_timestamp());
ALTER TABLE silver_database.delivery_tracking ADD CONSTRAINT chk_checkpoint_time CHECK (checkpoint_time < current_timestamp());

-- Ràng buộc CHECK cho các cột số nguyên
ALTER TABLE silver_database.delivery_tracking ADD CONSTRAINT chk_tracking_id_positive CHECK (tracking_id > 0);
ALTER TABLE silver_database.delivery_tracking ADD CONSTRAINT chk_shipment_id_positive CHECK (shipment_id > 0);

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.delivery_tracking ADD CONSTRAINT chk_location_length CHECK (length(location) > 0);
ALTER TABLE silver_database.delivery_tracking ADD CONSTRAINT chk_status_length CHECK (length(status) > 0);


ALTER TABLE silver_database.delivery_tracking ADD CONSTRAINT chk_updated_at CHECK (updated_at IS NULL OR updated_at < current_timestamp());

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.departments (
  department_id BIGINT COMMENT 'Unique auto-incremented identifier for departments',
  name STRING NOT NULL COMMENT 'Name of the department',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to category record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho các cột cần thiết
ALTER TABLE silver_database.departments ALTER COLUMN department_id SET NOT NULL;
ALTER TABLE silver_database.departments ALTER COLUMN name SET NOT NULL;

-- Ràng buộc CHECK cho các cột số
ALTER TABLE silver_database.departments ADD CONSTRAINT chk_department_id_positive CHECK (department_id > 0);

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.departments ADD CONSTRAINT chk_name_length CHECK (length(name) > 0);

-- Thêm cột updated_at và constraint cho updated_at
ALTER TABLE silver_database.departments ADD CONSTRAINT chk_updated_at CHECK (updated_at IS NULL OR updated_at < current_timestamp());

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.employees (
  employee_id STRING COMMENT 'Unique identifier for employees, auto-generated as EMP_XXX via trigger',
  name STRING NOT NULL COMMENT 'Full name of the employee',
  email BINARY COMMENT 'Unique email address of the employee',
  department_id BIGINT NOT NULL COMMENT 'References department_id in departments table',
  hire_date TIMESTAMP NOT NULL COMMENT 'Timestamp of employee hire date',
  salary DECIMAL(12,2) NOT NULL COMMENT 'Salary of the employee',
  deleted_at TIMESTAMP COMMENT 'Timestamp of employee soft deletion, null if active',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to category record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho các cột cần thiết
ALTER TABLE silver_database.employees ALTER COLUMN employee_id SET NOT NULL;
ALTER TABLE silver_database.employees ALTER COLUMN name SET NOT NULL;
ALTER TABLE silver_database.employees ALTER COLUMN email SET NOT NULL;
ALTER TABLE silver_database.employees ALTER COLUMN department_id SET NOT NULL;
ALTER TABLE silver_database.employees ALTER COLUMN hire_date SET NOT NULL;
ALTER TABLE silver_database.employees ALTER COLUMN salary SET NOT NULL;

-- Ràng buộc CHECK cho các cột ngày tháng
ALTER TABLE silver_database.employees ADD CONSTRAINT chk_hire_date CHECK (hire_date < current_timestamp());
ALTER TABLE silver_database.employees ADD CONSTRAINT chk_deleted_at CHECK (deleted_at IS NULL OR deleted_at < current_timestamp());

-- Ràng buộc CHECK cho các cột số
ALTER TABLE silver_database.employees ADD CONSTRAINT chk_department_id_positive CHECK (department_id > 0);
ALTER TABLE silver_database.employees ADD CONSTRAINT chk_salary_non_negative CHECK (salary >= 0);

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.employees ADD CONSTRAINT chk_employee_id_length CHECK (length(employee_id) > 0);
ALTER TABLE silver_database.employees ADD CONSTRAINT chk_name_length CHECK (length(name) > 0);
ALTER TABLE silver_database.employees ADD CONSTRAINT chk_email_length CHECK (length(email) > 0);

-- Thêm cột updated_at và constraint cho updated_at
ALTER TABLE silver_database.employees ADD CONSTRAINT chk_updated_at CHECK (updated_at IS NULL OR updated_at < current_timestamp());

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.financial_transactions (
  transaction_id BIGINT COMMENT 'Unique auto-incremented identifier for financial transactions',
  transaction_date TIMESTAMP NOT NULL COMMENT 'Timestamp of the financial transaction',
  account_id BIGINT NOT NULL COMMENT 'References account_id in accounts table',
  amount DECIMAL(12,2) NOT NULL COMMENT 'Amount of the financial transaction',
  type STRING COMMENT 'Type of the financial transaction',
  status STRING COMMENT 'Status of the financial transaction',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to category record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
PARTITIONED BY (transaction_date)  -- Partition by transaction_date for range-based optimization
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho các cột cần thiết
ALTER TABLE silver_database.financial_transactions ALTER COLUMN transaction_id SET NOT NULL;
ALTER TABLE silver_database.financial_transactions ALTER COLUMN transaction_date SET NOT NULL;
ALTER TABLE silver_database.financial_transactions ALTER COLUMN account_id SET NOT NULL;
ALTER TABLE silver_database.financial_transactions ALTER COLUMN amount SET NOT NULL;

-- Ràng buộc CHECK cho các cột ngày tháng
ALTER TABLE silver_database.financial_transactions ADD CONSTRAINT chk_transaction_date CHECK (transaction_date < current_timestamp());

-- Ràng buộc CHECK cho các cột số
ALTER TABLE silver_database.financial_transactions ADD CONSTRAINT chk_transaction_id_positive CHECK (transaction_id > 0);
ALTER TABLE silver_database.financial_transactions ADD CONSTRAINT chk_account_id_positive CHECK (account_id > 0);
ALTER TABLE silver_database.financial_transactions ADD CONSTRAINT chk_amount_non_negative CHECK (amount >= 0);

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.financial_transactions ADD CONSTRAINT chk_type_length CHECK (type IS NULL OR length(type) > 0);
ALTER TABLE silver_database.financial_transactions ADD CONSTRAINT chk_status_length CHECK (status IS NULL OR length(status) > 0);

-- Thêm cột updated_at và constraint cho updated_at
ALTER TABLE silver_database.financial_transactions ADD CONSTRAINT chk_updated_at CHECK (updated_at IS NULL OR updated_at < current_timestamp());

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.inventory (
  inventory_id BIGINT COMMENT 'Unique auto-incremented identifier for inventory records',
  warehouse_id BIGINT NOT NULL COMMENT 'References warehouse_id in warehouses table',
  product_id STRING NOT NULL COMMENT 'Product identifier, validated via API',
  sku_id BIGINT NOT NULL COMMENT 'SKU identifier, validated via API',
  stock_quantity INT NOT NULL COMMENT 'Quantity of stock in the warehouse',
  last_updated TIMESTAMP NOT NULL COMMENT 'Timestamp of last inventory update',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to category record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
PARTITIONED BY (product_id)  -- Partition by product_id for hash-based optimization
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho tất cả các cột
ALTER TABLE silver_database.inventory ALTER COLUMN inventory_id SET NOT NULL;
ALTER TABLE silver_database.inventory ALTER COLUMN warehouse_id SET NOT NULL;
ALTER TABLE silver_database.inventory ALTER COLUMN product_id SET NOT NULL;
ALTER TABLE silver_database.inventory ALTER COLUMN sku_id SET NOT NULL;
ALTER TABLE silver_database.inventory ALTER COLUMN stock_quantity SET NOT NULL;
ALTER TABLE silver_database.inventory ALTER COLUMN last_updated SET NOT NULL;

-- Ràng buộc CHECK cho các cột ngày tháng
ALTER TABLE silver_database.inventory ADD CONSTRAINT chk_last_updated CHECK (last_updated < current_timestamp());

-- Ràng buộc CHECK cho các cột số
ALTER TABLE silver_database.inventory ADD CONSTRAINT chk_inventory_id_positive CHECK (inventory_id > 0);
ALTER TABLE silver_database.inventory ADD CONSTRAINT chk_warehouse_id_positive CHECK (warehouse_id > 0);
ALTER TABLE silver_database.inventory ADD CONSTRAINT chk_sku_id_positive CHECK (sku_id > 0);
ALTER TABLE silver_database.inventory ADD CONSTRAINT chk_stock_quantity_non_negative CHECK (stock_quantity >= 0);

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.inventory ADD CONSTRAINT chk_product_id_length CHECK (length(product_id) > 0);


ALTER TABLE silver_database.inventory ADD CONSTRAINT chk_updated_at CHECK (updated_at IS NULL OR updated_at < current_timestamp());

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.payment_types (
  payment_type_id INT COMMENT 'Unique auto-incremented identifier for payment types',
  name STRING NOT NULL COMMENT 'Name of the payment type',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to category record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho tất cả các cột
ALTER TABLE silver_database.payment_types ALTER COLUMN payment_type_id SET NOT NULL;
ALTER TABLE silver_database.payment_types ALTER COLUMN name SET NOT NULL;

-- Ràng buộc CHECK cho các cột số
ALTER TABLE silver_database.payment_types ADD CONSTRAINT chk_payment_type_id_positive CHECK (payment_type_id > 0);

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.payment_types ADD CONSTRAINT chk_name_length CHECK (length(name) > 0);

-- COMMAND ----------

-- orders
CREATE TABLE IF NOT EXISTS silver_database.orders (
  order_id BIGINT COMMENT 'Unique auto-incremented identifier for orders',
  customer_id STRING NOT NULL COMMENT 'References customer_id in customers table',
  order_date TIMESTAMP NOT NULL COMMENT 'Timestamp of order creation',
  total_amount DECIMAL(12,2) NOT NULL COMMENT 'Total amount of the order, calculated from order_items',
  shipping_address STRING NOT NULL COMMENT 'Shipping address for the order, defaults to customer address',
  payment_type_id INT NOT NULL COMMENT 'References payment_type_id in payment_types table',
  payment_status STRING NOT NULL COMMENT 'Payment status of the order',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to orders record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
PARTITIONED BY (order_date)  -- Partition by order_date for range-based optimization in streaming
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho tất cả các cột
ALTER TABLE silver_database.orders ALTER COLUMN order_id SET NOT NULL;
ALTER TABLE silver_database.orders ALTER COLUMN customer_id SET NOT NULL;
ALTER TABLE silver_database.orders ALTER COLUMN order_date SET NOT NULL;
ALTER TABLE silver_database.orders ALTER COLUMN total_amount SET NOT NULL;
ALTER TABLE silver_database.orders ALTER COLUMN shipping_address SET NOT NULL;
ALTER TABLE silver_database.orders ALTER COLUMN payment_type_id SET NOT NULL;
ALTER TABLE silver_database.orders ALTER COLUMN payment_status SET NOT NULL;

-- Ràng buộc CHECK cho các cột ngày tháng
ALTER TABLE silver_database.orders ADD CONSTRAINT chk_order_date CHECK (order_date < current_timestamp());

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.orders ADD CONSTRAINT chk_customer_id_length CHECK (length(customer_id) > 0);
ALTER TABLE silver_database.orders ADD CONSTRAINT chk_shipping_address_length CHECK (length(shipping_address) > 0);
ALTER TABLE silver_database.orders ADD CONSTRAINT chk_payment_status_length CHECK (length(payment_status) > 0);

-- Ràng buộc CHECK cho các cột số
ALTER TABLE silver_database.orders ADD CONSTRAINT chk_total_amount_non_negative CHECK (total_amount >= 0);
ALTER TABLE silver_database.orders ADD CONSTRAINT chk_payment_type_id_positive CHECK (payment_type_id >= 0);

-- COMMAND ----------

-- order_items
CREATE TABLE IF NOT EXISTS silver_database.order_items (
  order_item_id BIGINT COMMENT 'Unique auto-incremented identifier for order items',
  order_id BIGINT NOT NULL COMMENT 'References order_id in orders table',
  product_id STRING NOT NULL COMMENT 'References product_id in products table',
  sku_id BIGINT NOT NULL COMMENT 'References sku_id in products_sku table',
  quantity INT NOT NULL COMMENT 'Quantity of the product in the order',
  unit_price DECIMAL(10,2) NOT NULL COMMENT 'Unit price of the product, defaults to SKU price times quantity',
  order_date TIMESTAMP NOT NULL COMMENT 'Timestamp of order creation',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to order_items record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
PARTITIONED BY (order_date)  -- Partition by order_date with sub-hash consideration simulated via partitioning
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho tất cả các cột
ALTER TABLE silver_database.order_items ALTER COLUMN order_item_id SET NOT NULL;
ALTER TABLE silver_database.order_items ALTER COLUMN order_id SET NOT NULL;
ALTER TABLE silver_database.order_items ALTER COLUMN product_id SET NOT NULL;
ALTER TABLE silver_database.order_items ALTER COLUMN sku_id SET NOT NULL;
ALTER TABLE silver_database.order_items ALTER COLUMN quantity SET NOT NULL;
ALTER TABLE silver_database.order_items ALTER COLUMN unit_price SET NOT NULL;
ALTER TABLE silver_database.order_items ALTER COLUMN order_date SET NOT NULL;

-- Ràng buộc CHECK cho các cột ngày tháng
ALTER TABLE silver_database.order_items ADD CONSTRAINT chk_order_date CHECK (order_date < current_timestamp());

-- Ràng buộc CHECK cho các cột số
ALTER TABLE silver_database.order_items ADD CONSTRAINT chk_quantity_positive CHECK (quantity > 0);
ALTER TABLE silver_database.order_items ADD CONSTRAINT chk_unit_price_non_negative CHECK (unit_price >= 0);

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.order_items ADD CONSTRAINT chk_product_id_length CHECK (length(product_id) > 0);

-- Ràng buộc CHECK cho các cột số nguyên
ALTER TABLE silver_database.order_items ADD CONSTRAINT chk_order_id_positive CHECK (order_id > 0);
ALTER TABLE silver_database.order_items ADD CONSTRAINT chk_sku_id_positive CHECK (sku_id > 0);

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.warehouses (
  warehouse_id BIGINT COMMENT 'Unique auto-incremented identifier for warehouses',
  name STRING NOT NULL COMMENT 'Name of the warehouse',
  location STRING NOT NULL COMMENT 'Location of the warehouse',
  created_at TIMESTAMP NOT NULL COMMENT 'Timestamp of warehouse record creation',
  deleted_at TIMESTAMP COMMENT 'Timestamp of warehouse soft deletion, null if active',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to order_items record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho tất cả các cột
ALTER TABLE silver_database.warehouses ALTER COLUMN warehouse_id SET NOT NULL;
ALTER TABLE silver_database.warehouses ALTER COLUMN name SET NOT NULL;
ALTER TABLE silver_database.warehouses ALTER COLUMN location SET NOT NULL;
ALTER TABLE silver_database.warehouses ALTER COLUMN created_at SET NOT NULL;

-- Ràng buộc CHECK cho các cột ngày tháng
ALTER TABLE silver_database.warehouses ADD CONSTRAINT chk_created_at CHECK (created_at < current_timestamp());
ALTER TABLE silver_database.warehouses ADD CONSTRAINT chk_deleted_at CHECK (deleted_at IS NULL OR deleted_at < current_timestamp());

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.warehouses ADD CONSTRAINT chk_name_length CHECK (length(name) > 0);
ALTER TABLE silver_database.warehouses ADD CONSTRAINT chk_location_length CHECK (length(location) > 0);

-- Thêm cột updated_at và constraint cho updated_at
ALTER TABLE silver_database.warehouses ADD CONSTRAINT chk_updated_at CHECK (updated_at IS NULL OR updated_at < current_timestamp());

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.suppliers (
  supplier_id BIGINT COMMENT 'Unique auto-incremented identifier for suppliers',
  name STRING NOT NULL COMMENT 'Name of the supplier',
  contact_name STRING NOT NULL COMMENT 'Name of the supplier contact person',
  phone BINARY NOT NULL COMMENT 'Phone number of the supplier',
  email BINARY NOT NULL COMMENT 'Email address of the supplier',
  created_at TIMESTAMP NOT NULL COMMENT 'Timestamp of supplier record creation',
  deleted_at TIMESTAMP COMMENT 'Timestamp of supplier soft deletion, null if active',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to order_items record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho tất cả các cột cần thiết
ALTER TABLE silver_database.suppliers ALTER COLUMN supplier_id SET NOT NULL;
ALTER TABLE silver_database.suppliers ALTER COLUMN name SET NOT NULL;
ALTER TABLE silver_database.suppliers ALTER COLUMN contact_name SET NOT NULL;
ALTER TABLE silver_database.suppliers ALTER COLUMN phone SET NOT NULL;
ALTER TABLE silver_database.suppliers ALTER COLUMN email SET NOT NULL;
ALTER TABLE silver_database.suppliers ALTER COLUMN created_at SET NOT NULL;

-- Ràng buộc CHECK cho các cột ngày tháng
ALTER TABLE silver_database.suppliers ADD CONSTRAINT chk_created_at CHECK (created_at < current_timestamp());
ALTER TABLE silver_database.suppliers ADD CONSTRAINT chk_deleted_at CHECK (deleted_at IS NULL OR deleted_at < current_timestamp());

-- Ràng buộc CHECK cho các cột số
ALTER TABLE silver_database.suppliers ADD CONSTRAINT chk_supplier_id_positive CHECK (supplier_id > 0);

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.suppliers ADD CONSTRAINT chk_name_length CHECK (length(name) > 0);
ALTER TABLE silver_database.suppliers ADD CONSTRAINT chk_contact_name_length CHECK (length(contact_name) > 0);
ALTER TABLE silver_database.suppliers ADD CONSTRAINT chk_phone_length CHECK (length(phone) > 0);
ALTER TABLE silver_database.suppliers ADD CONSTRAINT chk_email_length CHECK (length(email) > 0);

-- Thêm cột updated_at và constraint cho updated_at
ALTER TABLE silver_database.suppliers ADD CONSTRAINT chk_updated_at CHECK (updated_at IS NULL OR updated_at < current_timestamp());

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.shipments (
  shipment_id BIGINT COMMENT 'Unique auto-incremented identifier for shipments',
  order_id BIGINT NOT NULL COMMENT 'Order identifier, validated via API',
  warehouse_id BIGINT NOT NULL COMMENT 'References warehouse_id in warehouses table',
  shipment_date TIMESTAMP NOT NULL COMMENT 'Timestamp of shipment creation',
  status STRING NOT NULL COMMENT 'Status of the shipment',  
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to order_items record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
PARTITIONED BY (shipment_date)  -- Partition by shipment_date for range-based optimization
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho tất cả các cột
ALTER TABLE silver_database.shipments ALTER COLUMN shipment_id SET NOT NULL;
ALTER TABLE silver_database.shipments ALTER COLUMN order_id SET NOT NULL;
ALTER TABLE silver_database.shipments ALTER COLUMN warehouse_id SET NOT NULL;
ALTER TABLE silver_database.shipments ALTER COLUMN shipment_date SET NOT NULL;
ALTER TABLE silver_database.shipments ALTER COLUMN status SET NOT NULL;

-- Ràng buộc CHECK cho các cột ngày tháng
ALTER TABLE silver_database.shipments ADD CONSTRAINT chk_shipment_date CHECK (shipment_date < current_timestamp());

-- Ràng buộc CHECK cho các cột số nguyên
ALTER TABLE silver_database.shipments ADD CONSTRAINT chk_shipment_id_positive CHECK (shipment_id > 0);
ALTER TABLE silver_database.shipments ADD CONSTRAINT chk_order_id_positive CHECK (order_id > 0);
ALTER TABLE silver_database.shipments ADD CONSTRAINT chk_warehouse_id_positive CHECK (warehouse_id > 0);

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.shipments ADD CONSTRAINT chk_status_length CHECK (length(status) > 0);

-- Thêm cột updated_at và constraint cho updated_at
ALTER TABLE silver_database.shipments ADD CONSTRAINT chk_updated_at CHECK (updated_at IS NULL OR updated_at < current_timestamp());

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.purchase_orders (
  po_id BIGINT COMMENT 'Unique auto-incremented identifier for purchase orders',
  supplier_id BIGINT NOT NULL COMMENT 'References supplier_id in suppliers table',
  order_date TIMESTAMP NOT NULL COMMENT 'Timestamp of purchase order creation',
  status STRING COMMENT 'Status of the purchase order',
  total_amount DECIMAL(12,2) NOT NULL COMMENT 'Total amount of the purchase order, calculated from items',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to order_items record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
PARTITIONED BY (order_date)  -- Partition by order_date for range-based optimization
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho các cột cần thiết
ALTER TABLE silver_database.purchase_orders ALTER COLUMN po_id SET NOT NULL;
ALTER TABLE silver_database.purchase_orders ALTER COLUMN supplier_id SET NOT NULL;
ALTER TABLE silver_database.purchase_orders ALTER COLUMN order_date SET NOT NULL;
ALTER TABLE silver_database.purchase_orders ALTER COLUMN total_amount SET NOT NULL;

-- Ràng buộc CHECK cho các cột ngày tháng
ALTER TABLE silver_database.purchase_orders ADD CONSTRAINT chk_order_date CHECK (order_date < current_timestamp());

-- Ràng buộc CHECK cho các cột số
ALTER TABLE silver_database.purchase_orders ADD CONSTRAINT chk_po_id_positive CHECK (po_id > 0);
ALTER TABLE silver_database.purchase_orders ADD CONSTRAINT chk_supplier_id_positive CHECK (supplier_id > 0);
ALTER TABLE silver_database.purchase_orders ADD CONSTRAINT chk_total_amount_non_negative CHECK (total_amount >= 0);

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.purchase_orders ADD CONSTRAINT chk_status_length CHECK (status IS NULL OR length(status) > 0);

-- Thêm cột updated_at và constraint cho updated_at
ALTER TABLE silver_database.purchase_orders ADD CONSTRAINT chk_updated_at CHECK (updated_at IS NULL OR updated_at < current_timestamp());

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.purchase_order_items (
  po_item_id BIGINT COMMENT 'Unique auto-incremented identifier for purchase order items',
  po_id BIGINT NOT NULL COMMENT 'References po_id in purchase_orders table',
  product_id STRING NOT NULL COMMENT 'Product identifier, validated via API',
  quantity INT NOT NULL COMMENT 'Quantity of the product in the purchase order',
  unit_price DECIMAL(10,2) NOT NULL COMMENT 'Unit price of the product in the purchase order',
  order_date TIMESTAMP NOT NULL COMMENT 'Timestamp of purchase order creation',
  updated_at TIMESTAMP COMMENT 'Timestamp of last update to order_items record',
  ingestion_time TIMESTAMP COMMENT 'Timestamp of data ingestion',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
PARTITIONED BY (order_date)  -- Partition by order_date with sub-hash simulation
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho các cột cần thiết
ALTER TABLE silver_database.purchase_order_items ALTER COLUMN po_item_id SET NOT NULL;
ALTER TABLE silver_database.purchase_order_items ALTER COLUMN po_id SET NOT NULL;
ALTER TABLE silver_database.purchase_order_items ALTER COLUMN product_id SET NOT NULL;
ALTER TABLE silver_database.purchase_order_items ALTER COLUMN quantity SET NOT NULL;
ALTER TABLE silver_database.purchase_order_items ALTER COLUMN unit_price SET NOT NULL;
ALTER TABLE silver_database.purchase_order_items ALTER COLUMN order_date SET NOT NULL;

-- Ràng buộc CHECK cho các cột ngày tháng
ALTER TABLE silver_database.purchase_order_items ADD CONSTRAINT chk_order_date CHECK (order_date < current_timestamp());

-- Ràng buộc CHECK cho các cột số
ALTER TABLE silver_database.purchase_order_items ADD CONSTRAINT chk_po_item_id_positive CHECK (po_item_id > 0);
ALTER TABLE silver_database.purchase_order_items ADD CONSTRAINT chk_po_id_positive CHECK (po_id > 0);
ALTER TABLE silver_database.purchase_order_items ADD CONSTRAINT chk_quantity_positive CHECK (quantity > 0);
ALTER TABLE silver_database.purchase_order_items ADD CONSTRAINT chk_unit_price_non_negative CHECK (unit_price >= 0);

-- Ràng buộc CHECK cho các cột string
ALTER TABLE silver_database.purchase_order_items ADD CONSTRAINT chk_product_id_length CHECK (length(product_id) > 0);

-- Thêm cột updated_at và constraint cho updated_at
ALTER TABLE silver_database.purchase_order_items ADD CONSTRAINT chk_updated_at CHECK (updated_at IS NULL OR updated_at < current_timestamp());

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS silver_database.audit_log (
  log_id BIGINT COMMENT 'Unique auto-incremented identifier for log',
  database_source STRING COMMENT 'Database source of the log',
  log_time TIMESTAMP COMMENT 'Timestamp of log creation',
  user_name STRING COMMENT 'User who created the log',
  action_type STRING COMMENT 'Type of action performed',
  object_type STRING COMMENT 'Type of object affected',
  object_name STRING COMMENT 'Name of the object affected',
  query STRING COMMENT 'SQL query associated with the log',
  ingestion_time TIMESTAMP COMMENT 'Timestamp when the record was ingested into the table',
  hash STRING COMMENT 'Hash value for the record'
) USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

-- COMMAND ----------

-- Ràng buộc NOT NULL cho các cột cần thiết
ALTER TABLE silver_database.audit_log ALTER COLUMN log_id SET NOT NULL;
ALTER TABLE silver_database.audit_log ALTER COLUMN log_time SET NOT NULL;
ALTER TABLE silver_database.audit_log ALTER COLUMN user_name SET NOT NULL;
ALTER TABLE silver_database.audit_log ALTER COLUMN action_type SET NOT NULL;
ALTER TABLE silver_database.audit_log ALTER COLUMN object_type SET NOT NULL;

ALTER TABLE silver_database.audit_log ALTER COLUMN query SET NOT NULL;
ALTER TABLE silver_database.audit_log ALTER COLUMN ingestion_time SET NOT NULL;

ALTER TABLE silver_database.audit_log ALTER COLUMN hash SET NOT NULL;

-- Ràng buộc CHECK cho các cột kiểu timestamp
ALTER TABLE silver_database.audit_log ADD CONSTRAINT chk_log_time CHECK (log_time < current_timestamp());
ALTER TABLE silver_database.audit_log ADD CONSTRAINT chk_ingestion_time CHECK (ingestion_time < current_timestamp());

-- Ràng buộc CHECK cho các cột kiểu string
ALTER TABLE silver_database.audit_log ADD CONSTRAINT chk_user_name_length CHECK (length(user_name) > 0);
ALTER TABLE silver_database.audit_log ADD CONSTRAINT chk_action_type_length CHECK (length(action_type) > 0);
ALTER TABLE silver_database.audit_log ADD CONSTRAINT chk_object_type_length CHECK (length(object_type) > 0);

ALTER TABLE silver_database.audit_log ADD CONSTRAINT chk_query_length CHECK (length(query) > 0);

ALTER TABLE silver_database.audit_log ADD CONSTRAINT chk_hash_length CHECK (length(hash) > 0);