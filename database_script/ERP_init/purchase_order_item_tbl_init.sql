----------------------------------------------------------------------------------------------------
--          Creating purchase_order_items table with RANGE and HASH partitioning
CREATE TABLE purchase_order_items (
    po_item_id BIGINT  GENERATED ALWAYS AS IDENTITY,
    po_id BIGINT NOT NULL ,
    product_id VARCHAR(20) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
    order_date TIMESTAMPTZ NOT NULL CHECK (order_date <= CURRENT_TIMESTAMP),
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