-------------------------------------------------------------------------------
--                             Creating order_items table
-- Creating order_items table with RANGE and HASH partitioning
CREATE TABLE order_items (
    order_item_id BIGINT GENERATED ALWAYS AS IDENTITY,
    order_id BIGINT NOT NULL ,
    product_id VARCHAR(20) NOT NULL REFERENCES products(product_id),
    sku_id BIGINT NOT NULL REFERENCES products_sku(sku_id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
    order_date TIMESTAMPTZ NOT NULL ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (updated_at <= CURRENT_TIMESTAMP)
	PRIMARY KEY (order_id, order_item_id, order_date),
	FOREIGN KEY (order_id, order_date) REFERENCES orders(order_id, order_date)
) PARTITION BY RANGE (order_date);

---------------------------------------------------------------------------------
-- Creating monthly partitions for order_items table
SELECT create_monthly_partition('order_items', 2025, 8); -- Tạo partition cho tháng 8 năm 2025
SELECT create_monthly_partition('order_items', 2025, 9); -- Tạo partition cho tháng 9 năm 2025
SELECT create_monthly_partition('order_items', 2025, 10); -- Tạo partition cho tháng 10 năm 2025
--------------------------------------------------------------------------------
-- Creating indexes
CREATE INDEX order_items_order_id_idx ON order_items USING hash (order_id);

-- ==========================================
-- Trigger: update column updated_at
-- ==========================================
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