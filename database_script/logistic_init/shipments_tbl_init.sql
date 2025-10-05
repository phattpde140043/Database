--------------------------------------------------------------------------------
-- Creating shipments table with RANGE partitioning by month on shipment_date
CREATE TABLE shipments (
    shipment_id BIGINT GENERATED ALWAYS AS IDENTITY,
    order_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL REFERENCES warehouses(warehouse_id),
    shipment_date TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (shipment_date <= CURRENT_TIMESTAMP),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'in_transit', 'delivered', 'cancelled')) DEFAULT 'pending',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (updated_at <= CURRENT_TIMESTAMP)
	PRIMARY KEY (shipment_id,shipment_date)
) PARTITION BY RANGE (shipment_date);

-----------------------------------------------------------------------------
SELECT create_monthly_partition('shipments', 2025, 8); -- Tạo partition cho tháng 8 năm 2025
SELECT create_monthly_partition('shipments', 2025, 9); -- Tạo partition cho tháng 9 năm 2025
SELECT create_monthly_partition('shipments', 2025, 10); -- Tạo partition cho tháng 10 năm 2025

-------------------------------------------------------------------------------
--                              Creating indexes
CREATE INDEX shipments_order_id_idx ON shipments (order_id);

-----------------------------------------------------------------------------
-- ==========================================
-- Function: Insert shipment
-- ==========================================
CREATE OR REPLACE FUNCTION insert_shipment(
    p_order_id BIGINT,
    p_warehouse_id BIGINT,
    p_shipment_date TIMESTAMPTZ DEFAULT now(),
    p_status VARCHAR DEFAULT 'pending'
)
RETURNS BIGINT AS $$
DECLARE
    v_shipment_id BIGINT;
BEGIN
    -- Validate status
    IF p_status NOT IN ('pending', 'in_transit', 'delivered', 'cancelled') THEN
        RAISE EXCEPTION 'Invalid status value: %', p_status;
    END IF;

    -- Validate thời gian
    IF p_shipment_date > now() THEN
        RAISE EXCEPTION 'Shipment date cannot be in the future';
    END IF;

    -- Insert dữ liệu
    INSERT INTO shipments(order_id, warehouse_id, shipment_date, status)
    VALUES (p_order_id, p_warehouse_id, p_shipment_date, p_status)
    RETURNING shipment_id INTO v_shipment_id;

    RETURN v_shipment_id;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- Trigger: update column updated_at
-- ==========================================
CREATE OR REPLACE FUNCTION shipment_set_timestamp()
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

--------------------------------  Test ----------------------------
Select * from shipments;
-- Insert shipment mới (tự động vào partition 2025-09)
SELECT insert_shipment(
    p_order_id := 101,
    p_warehouse_id := 1,
    p_shipment_date := '2025-09-01 09:30:00+07',
    p_status := 'in_transit'
);

SELECT * FROM pg_publication;
SELECT * FROM pg_publication_tables WHERE pubname = 'debezium_pub';
CREATE PUBLICATION debezium_pub FOR ALL TABLES;
\dRp+