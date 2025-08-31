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
