----------------------------------------------------------------------------------------------------
--          Creating purchase_order_items table with RANGE and HASH partitioning
CREATE TABLE purchase_order_items (
    po_item_id BIGINT  GENERATED ALWAYS AS IDENTITY,
    po_id BIGINT NOT NULL ,
    product_id VARCHAR(20) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
    order_date TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (order_date <= CURRENT_TIMESTAMP),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (updated_at <= CURRENT_TIMESTAMP),
    PRIMARY KEY (po_item_id, order_date),
    FOREIGN KEY (po_id, order_date) REFERENCES purchase_orders(po_id, order_date)
) PARTITION BY RANGE (order_date);


-------------------------------------------------------------------------------
-- Creating sub-partitions with HASH on po_id
SELECT create_monthly_partition('purchase_order_items', 2025, 8);
SELECT create_monthly_partition('purchase_order_items', 2025, 9);
SELECT create_monthly_partition('purchase_order_items', 2025, 10);

----------------------------------------------------------------------------
CREATE INDEX purchase_order_items_po_id_idx ON purchase_order_items (po_id);

-- ==========================================
-- Function: Insert new purchase_order_item
-- ==========================================
CREATE OR REPLACE FUNCTION insert_purchase_order_item(
    p_po_id BIGINT,
    p_product_id VARCHAR,
    p_quantity INT,
    p_unit_price DECIMAL(10,2),
    p_order_date TIMESTAMPTZ DEFAULT now()
)
RETURNS BIGINT AS $$
DECLARE
    v_po_item_id BIGINT;
BEGIN
    -- Validate input
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be > 0';
    END IF;

    IF p_unit_price <= 0 THEN
        RAISE EXCEPTION 'Unit price must be > 0';
    END IF;

    -- Insert record
    INSERT INTO purchase_order_items (po_id, product_id, quantity, unit_price, order_date)
    VALUES (p_po_id, p_product_id, p_quantity, p_unit_price, p_order_date)
    RETURNING po_item_id INTO v_po_item_id;

    RETURN v_po_item_id;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- Function: Update purchase_order_item
-- ==========================================
CREATE OR REPLACE FUNCTION update_purchase_order_item(
    p_po_item_id BIGINT,
    p_order_date TIMESTAMPTZ,
    p_quantity INT DEFAULT NULL,
    p_unit_price DECIMAL(10,2) DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE purchase_order_items
    SET quantity   = COALESCE(p_quantity, quantity),
        unit_price = COALESCE(p_unit_price, unit_price)
    WHERE po_item_id = p_po_item_id
      AND order_date = p_order_date; -- xác định đúng partition

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Purchase order item % at % not found', p_po_item_id, p_order_date;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- Trigger: update column updated_at
-- ==========================================
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

----------------------------------  Test ------------------------------------
-- Insert item
SELECT insert_purchase_order_item(
    p_po_id := 1,
    p_product_id := 'PROD123',
    p_quantity := 10,
    p_unit_price := 25.50,
    p_order_date := '2025-08-15'::timestamptz
);

-- Update item
SELECT update_purchase_order_item(
    p_po_item_id := 1,
    p_order_date := '2025-08-15'::timestamptz,
    p_quantity := 12,
    p_unit_price := 26.00
);
