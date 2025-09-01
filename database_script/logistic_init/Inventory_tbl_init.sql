-------------------------------------------------------------------------------
--          Creating inventory table with HASH partitioning on product_id
CREATE TABLE inventory (
    inventory_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    warehouse_id BIGINT NOT NULL REFERENCES warehouses(warehouse_id),
    product_id VARCHAR(20) NOT NULL,
    sku_id BIGINT NOT NULL,
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
    last_updated TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_inventory UNIQUE (warehouse_id, product_id, sku_id)
);

-----------------------------------------------------------------------
-- Creating trigger to update updated_at on modification
CREATE OR REPLACE FUNCTION inventory_update_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.last_updated = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER inventory_last_updated_trigger
BEFORE UPDATE ON inventory
FOR EACH ROW
EXECUTE FUNCTION inventory_update_set_timestamp();

----------------------------------------------------------------------

CREATE INDEX inventory_product_id_idx ON inventory (product_id);
CREATE INDEX inventory_sku_id_idx ON inventory (sku_id);
--------------------------------------------------------------------

-- function update dữ liệu stock_quantity theo sku_id
CREATE OR REPLACE FUNCTION update_stock_by_sku(
    p_sku_id BIGINT,
    p_new_quantity INT
)
RETURNS VOID AS $$
BEGIN
    IF p_new_quantity < 0 THEN
        RAISE EXCEPTION 'Stock quantity cannot be negative';
    END IF;

    UPDATE inventory
    SET stock_quantity = p_new_quantity,
        last_updated = now()
    WHERE sku_id = p_sku_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'SKU % not found in inventory', p_sku_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- function insert dữ liệu mới
CREATE OR REPLACE FUNCTION insert_inventory(
    p_warehouse_id BIGINT,
    p_product_id VARCHAR,
    p_sku_id BIGINT,
    p_stock_quantity INT
)
RETURNS BIGINT AS $$
DECLARE
    v_inventory_id BIGINT;
BEGIN
    IF p_stock_quantity < 0 THEN
        RAISE EXCEPTION 'Stock quantity cannot be negative';
    END IF;

    INSERT INTO inventory(warehouse_id, product_id, sku_id, stock_quantity)
    VALUES (p_warehouse_id, p_product_id, p_sku_id, p_stock_quantity)
    RETURNING inventory_id INTO v_inventory_id;

    RETURN v_inventory_id;
END;
$$ LANGUAGE plpgsql;
-- function update dữ liệu

CREATE OR REPLACE FUNCTION update_inventory(
    p_inventory_id BIGINT,
    p_stock_quantity INT DEFAULT NULL,
    p_sku_id BIGINT DEFAULT NULL,
    p_product_id VARCHAR DEFAULT NULL,
    p_warehouse_id BIGINT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE inventory
    SET stock_quantity = COALESCE(p_stock_quantity, stock_quantity),
        sku_id = COALESCE(p_sku_id, sku_id),
        product_id = COALESCE(p_product_id, product_id),
        warehouse_id = COALESCE(p_warehouse_id, warehouse_id),
        last_updated = now()
    WHERE inventory_id = p_inventory_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Inventory ID % not found', p_inventory_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 1. Update stock theo SKU
SELECT update_stock_by_sku(101, 200);

-- 2. Insert inventory mới
SELECT insert_inventory(1, 'PROD001', 101, 150);

-- 3. Update dữ liệu inventory
SELECT update_inventory(5, p_stock_quantity := 300, p_sku_id := 105);