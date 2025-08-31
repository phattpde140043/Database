--------------------------------------------------------------------------------
-- Creating shipments table with RANGE partitioning by month on shipment_date
CREATE TABLE shipments (
    shipment_id BIGINT GENERATED ALWAYS AS IDENTITY,
    order_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL REFERENCES warehouses(warehouse_id),
    shipment_date TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (shipment_date <= CURRENT_TIMESTAMP),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'in_transit', 'delivered', 'cancelled')) DEFAULT 'pending',
	PRIMARY KEY (shipment_id,shipment_date)
) PARTITION BY RANGE (shipment_date);

-----------------------------------------------------------------------------
SELECT create_monthly_partition('shipments', 2025, 8); -- Tạo partition cho tháng 8 năm 2025
SELECT create_monthly_partition('shipments', 2025, 9); -- Tạo partition cho tháng 9 năm 2025
SELECT create_monthly_partition('shipments', 2025, 10); -- Tạo partition cho tháng 10 năm 2025

-------------------------------------------------------------------------------
--                              Creating indexes
CREATE INDEX shipments_order_id_idx ON shipments (order_id);