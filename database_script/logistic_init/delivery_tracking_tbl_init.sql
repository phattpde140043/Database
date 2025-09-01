--------------------------------------------------------------------------------
-- Creating delivery_tracking table with RANGE partitioning by month on checkpoint_time
CREATE TABLE delivery_tracking (
    tracking_id BIGINT GENERATED ALWAYS AS IDENTITY,
    shipment_id BIGINT NOT NULL,
	shipment_date TIMESTAMPTZ NOT NULL CHECK (shipment_date <= CURRENT_TIMESTAMP),
    checkpoint_time TIMESTAMPTZ NOT NULL CHECK (checkpoint_time <= CURRENT_TIMESTAMP),
    location VARCHAR(500) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('in_transit', 'delivered', 'cancelled')) DEFAULT 'in_transit',
	PRIMARY KEY (tracking_id,checkpoint_time),
	FOREIGN KEY (shipment_id,shipment_date) REFERENCES shipments(shipment_id,shipment_date)
) PARTITION BY RANGE (checkpoint_time);


----------------------------------------------------------------------------
-- Tạo partition cho bảng delivery_tracking
SELECT create_monthly_partition('delivery_tracking', 2025, 8); -- Tạo partition cho tháng 8 năm 2025
SELECT create_monthly_partition('delivery_tracking', 2025, 9); -- Tạo partition cho tháng 9 năm 2025
SELECT create_monthly_partition('delivery_tracking', 2025, 10); -- Tạo partition cho tháng 10 năm 2025

---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_shipment_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Cập nhật status của shipment theo checkpoint_time mới nhất
    UPDATE shipments s
    SET status = sub.latest_status
    FROM (
        SELECT dt.shipment_id, dt.status AS latest_status
        FROM delivery_tracking dt
        WHERE dt.shipment_id = NEW.shipment_id
        ORDER BY dt.checkpoint_time DESC
        LIMIT 1
    ) sub
    WHERE s.shipment_id = sub.shipment_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_shipment_status
AFTER INSERT ON delivery_tracking
FOR EACH ROW
EXECUTE FUNCTION update_shipment_status();
--------------------------------------------------------------------------
CREATE INDEX delivery_tracking_shipment_id_idx ON delivery_tracking (shipment_id);

---------------------------------------------------------------------------
-- ========================================
-- Function: Insert vào delivery_tracking
-- ========================================
CREATE OR REPLACE FUNCTION insert_delivery_tracking(
    p_shipment_id BIGINT,
    p_shipment_date TIMESTAMPTZ,
    p_checkpoint_time TIMESTAMPTZ,
    p_location VARCHAR,
    p_status VARCHAR DEFAULT 'in_transit'
)
RETURNS BIGINT AS $$
DECLARE
    v_tracking_id BIGINT;
BEGIN
    -- Validate status
    IF p_status NOT IN ('in_transit', 'delivered', 'cancelled') THEN
        RAISE EXCEPTION 'Invalid status value: %', p_status;
    END IF;

    -- Validate thời gian
    IF p_shipment_date > now() THEN
        RAISE EXCEPTION 'Shipment date cannot be in the future';
    END IF;

    IF p_checkpoint_time > now() THEN
        RAISE EXCEPTION 'Checkpoint time cannot be in the future';
    END IF;

    -- Insert dữ liệu
    INSERT INTO delivery_tracking(shipment_id, shipment_date, checkpoint_time, location, status)
    VALUES (p_shipment_id, p_shipment_date, p_checkpoint_time, p_location, p_status)
    RETURNING tracking_id INTO v_tracking_id;

    RETURN v_tracking_id;
END;
$$ LANGUAGE plpgsql;


-- Insert bản ghi mới
SELECT insert_delivery_tracking(
    p_shipment_id := 1001,
    p_shipment_date := '2025-08-25 10:00:00+07',
    p_checkpoint_time := '2025-08-26 15:00:00+07',
    p_location := 'Hà Nội',
    p_status := 'in_transit'
);

