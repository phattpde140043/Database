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