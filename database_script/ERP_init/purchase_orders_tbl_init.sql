----------------------------------------------------------------------------------------------------
-- Creating purchase_orders table with RANGE partitioning by month on order_date
CREATE TABLE purchase_orders (
    po_id BIGINT GENERATED ALWAYS AS IDENTITY,
    supplier_id BIGINT NOT NULL REFERENCES suppliers(supplier_id),
    order_date TIMESTAMPTZ NOT NULL CHECK (order_date <= CURRENT_TIMESTAMP),
    status VARCHAR(20) NOT NULL CHECK (status IN ('draft', 'approved', 'received', 'cancelled')),
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    PRIMARY KEY (po_id, order_date)
) PARTITION BY RANGE (order_date);

-- Creating partitions for purchase_orders table (example for 2025)
SELECT create_monthly_partition('purchase_orders', 2025, 8);
SELECT create_monthly_partition('purchase_orders', 2025, 9);
SELECT create_monthly_partition('purchase_orders', 2025, 10);

-----------------------------------------------------------
CREATE INDEX purchase_orders_supplier_id_idx ON purchase_orders (supplier_id);