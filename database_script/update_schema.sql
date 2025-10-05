-- erp database

ALTER TABLE accounts
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION account_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS account_set_timestamp_trigger ON accounts;

CREATE TRIGGER account_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON accounts
FOR EACH ROW
EXECUTE FUNCTION account_set_timestamp();

UPDATE accounts SET updated_at = now();

-------------------------------------------------------------------------
ALTER TABLE departments
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION department_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS department_set_timestamp_trigger ON departments;

CREATE TRIGGER department_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON departments
FOR EACH ROW
EXECUTE FUNCTION department_set_timestamp();

UPDATE departments SET updated_at = now();

------------------------------------------------------------------------

ALTER TABLE employees
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION employee_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS employee_set_timestamp_trigger ON employees;

CREATE TRIGGER employee_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON employees
FOR EACH ROW
EXECUTE FUNCTION employee_set_timestamp();

UPDATE employees SET updated_at = now();

---------------------------------------------------------------------------

ALTER TABLE financial_transactions
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION financial_transaction_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS financial_transaction_set_timestamp_trigger ON financial_transactions;

CREATE TRIGGER financial_transaction_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON financial_transactions
FOR EACH ROW
EXECUTE FUNCTION financial_transaction_set_timestamp();

UPDATE financial_transactions SET updated_at = now();

---------------------------------------------------------------------------

ALTER TABLE purchase_order_items
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION purchase_order_item_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS purchase_order_item_set_timestamp_trigger ON purchase_order_items;

CREATE TRIGGER purchase_order_item_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON purchase_order_items
FOR EACH ROW
EXECUTE FUNCTION purchase_order_item_set_timestamp();

UPDATE purchase_order_items SET updated_at = now();

---------------------------------------------------------------------------

ALTER TABLE purchase_orders
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION purchase_order_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS purchase_order_set_timestamp_trigger ON purchase_orders;

CREATE TRIGGER purchase_order_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON purchase_orders
FOR EACH ROW
EXECUTE FUNCTION purchase_order_set_timestamp();

UPDATE purchase_orders SET updated_at = now();

---------------------------------------------------------------------------

ALTER TABLE suppliers
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION supplier_order_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS supplier_set_timestamp_trigger ON suppliers;

CREATE TRIGGER supplier_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON suppliers
FOR EACH ROW
EXECUTE FUNCTION supplier_set_timestamp();

UPDATE suppliers SET updated_at = now();

---------------------------------------------------------------------------

ALTER TABLE delivery_tracking
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION delivery_tracking_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS delivery_tracking_set_timestamp_trigger ON delivery_tracking;

CREATE TRIGGER delivery_tracking_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON delivery_tracking
FOR EACH ROW
EXECUTE FUNCTION delivery_tracking_set_timestamp();

UPDATE delivery_tracking SET updated_at = now();

---------------------------------------------------------------------------

ALTER TABLE shipments
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION shipments_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS shipment_set_timestamp_trigger ON shipments;

CREATE TRIGGER shipment_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON shipments
FOR EACH ROW
EXECUTE FUNCTION shipment_set_timestamp();

UPDATE shipments SET updated_at = now();

---------------------------------------------------------------------------
ALTER TABLE warehouses
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION warehouse_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS warehouse_set_timestamp_trigger ON warehouses;

CREATE TRIGGER warehouse_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON warehouses
FOR EACH ROW
EXECUTE FUNCTION warehouse_set_timestamp();

UPDATE warehouses SET updated_at = now();

---------------------------------------------------------------------------
ALTER TABLE categories
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION categories_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS categories_set_timestamp_trigger ON categories;

CREATE TRIGGER categories_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON categories
FOR EACH ROW
EXECUTE FUNCTION categories_set_timestamp();

UPDATE categories SET updated_at = now();

---------------------------------------------------------------------------
ALTER TABLE order_items
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION order_items_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS order_items_set_timestamp_trigger ON order_items;

CREATE TRIGGER order_items_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION order_items_set_timestamp();

UPDATE order_items SET updated_at = now();

---------------------------------------------------------------------------
ALTER TABLE orders
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION order_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS order_set_timestamp_trigger ON orders;

CREATE TRIGGER order_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION order_set_timestamp();

UPDATE orders SET updated_at = now();

---------------------------------------------------------------------------
ALTER TABLE payment_types
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION payment_type_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payment_type_set_timestamp_trigger ON payment_types;

CREATE TRIGGER payment_type_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON payment_types
FOR EACH ROW
EXECUTE FUNCTION payment_type_set_timestamp();

UPDATE payment_types SET updated_at = now();

---------------------------------------------------------------------------
ALTER TABLE products_sku
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);
CREATE OR REPLACE FUNCTION products_sku_type_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS products_sku_set_timestamp_trigger ON products_sku;

CREATE TRIGGER products_sku_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON products_sku
FOR EACH ROW
EXECUTE FUNCTION products_sku_set_timestamp();

UPDATE products_sku SET updated_at = now();

---------------------------------------------------------------------------
ALTER TABLE products
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now() 
CHECK (updated_at <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION product_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS product_set_timestamp_trigger ON products;

CREATE TRIGGER product_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION product_set_timestamp();

UPDATE products SET updated_at = now();

---------------------------------------------------------------------------