----------------------------------------------------------------------------------------------------
-- Creating purchase_orders table with RANGE partitioning by month on order_date
CREATE TABLE purchase_orders (
    po_id BIGINT GENERATED ALWAYS AS IDENTITY,
    supplier_id BIGINT NOT NULL REFERENCES suppliers(supplier_id),
    order_date TIMESTAMPTZ DEFAULT now() CHECK (order_date <= CURRENT_TIMESTAMP),
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
-- ==========================================
-- Function: Insert new purchase order
-- ==========================================
CREATE OR REPLACE FUNCTION insert_purchase_order(
    p_supplier_id BIGINT,
	p_total_amount DECIMAL(12,2),
    p_order_date TIMESTAMPTZ DEFAULT now(),
	p_status VARCHAR DEFAULT 'draft'
)
RETURNS BIGINT AS $$
DECLARE
    v_po_id BIGINT;
BEGIN
    -- Validate dữ liệu
    IF p_total_amount < 0 THEN
        RAISE EXCEPTION 'Total amount must be >= 0';
    END IF;

    IF p_status NOT IN ('draft', 'approved', 'received', 'cancelled') THEN
        RAISE EXCEPTION 'Invalid status: %', p_status;
    END IF;

    -- Insert
    INSERT INTO purchase_orders(supplier_id, order_date, status, total_amount)
    VALUES (p_supplier_id, p_order_date, p_status, p_total_amount)
    RETURNING po_id INTO v_po_id;

    RETURN v_po_id;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- Function: Update purchase order
-- ==========================================
CREATE OR REPLACE FUNCTION update_purchase_order(
    p_po_id BIGINT,
    p_order_date TIMESTAMPTZ, -- bắt buộc để xác định đúng partition
    p_status VARCHAR DEFAULT NULL,
    p_total_amount DECIMAL(12,2) DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE purchase_orders
    SET status = COALESCE(p_status, status),
        total_amount = COALESCE(p_total_amount, total_amount)
    WHERE po_id = p_po_id
      AND order_date = p_order_date;  -- để tìm đúng partition

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Purchase order % at date % not found', p_po_id, p_order_date;
    END IF;
END;
$$ LANGUAGE plpgsql;
