--------------------------------------------------------------------------------
--                               Creating orders table
-- Creating orders table with RANGE partitioning by month on order_date
CREATE TABLE orders (
    order_id BIGINT GENERATED ALWAYS AS IDENTITY,
    customer_id VARCHAR(20) NOT NULL REFERENCES customers(customer_id),
    order_date TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (order_date <= now()),
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    shipping_address VARCHAR(500) NOT NULL,
    payment_type_id INT NOT NULL REFERENCES payment_types(payment_type_id),
    payment_status VARCHAR(20) NOT NULL CHECK (payment_status IN ('pending', 'completed', 'failed')) DEFAULT 'pending',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (updated_at <= CURRENT_TIMESTAMP),
	PRIMARY KEY (order_id,order_date)
) PARTITION BY RANGE (order_date);

---------------------------------------------------------------------------------
-- Trigger function to set default shipping_address from customers table
CREATE OR REPLACE FUNCTION set_default_shipping_address()
RETURNS TRIGGER AS $$
BEGIN
    -- Nếu chưa truyền shipping_address
    IF NEW.shipping_address IS NULL THEN
        SELECT c.address
        INTO NEW.shipping_address
        FROM customers c
        WHERE c.customer_id = NEW.customer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_set_shipping_address
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION set_default_shipping_address();

--------------------------------------------------------------------------------
-- Creating monthly partitions for orders table
SELECT create_monthly_partition('orders', 2025, 8); -- Tạo partition cho tháng 8 năm 2025
SELECT create_monthly_partition('orders', 2025, 9); -- Tạo partition cho tháng 9 năm 2025
SELECT create_monthly_partition('orders', 2025, 10); -- Tạo partition cho tháng 10 năm 2025
---------------------------------------------------------------------------------
-- Creating indexes
CREATE INDEX orders_customer_id_idx ON orders USING hash (customer_id);
CREATE INDEX orders_order_date_idx ON orders (order_date);


-- ==========================================
-- Trigger: update column updated_at
-- ==========================================
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

