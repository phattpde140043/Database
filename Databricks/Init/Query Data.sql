-- Databricks notebook source
USE CATALOG  bronze_layer;

-- COMMAND ----------

Select * from bronze_logistic.audit_log

-- COMMAND ----------

Select * from bronze_pos.audit_log

-- COMMAND ----------

USE CATALOG silver_layer;
delete from silver_database.audit_log;

-- COMMAND ----------

Select COUNT(*) from bronze_erp.audit_log

-- COMMAND ----------

Select * from bronze_erp.audit_log

-- COMMAND ----------

Select * from bronze_logistic.delivery_tracking

-- COMMAND ----------

Select * from bronze_pos.customers

-- COMMAND ----------

select * from bronze_pos.orders

-- COMMAND ----------

select * from bronze_pos.order_items

-- COMMAND ----------

select * from bronze_pos.financial_transactions

-- COMMAND ----------

select * from bronze_pos.purchase_order_items

-- COMMAND ----------

select * from bronze_pos.purchase_orders

-- COMMAND ----------

select * from bronze_pos.inventory

-- COMMAND ----------

select * from bronze_pos.delivery_tracking

-- COMMAND ----------

select * from bronze_pos.shipments