-- Creating the database
CREATE DATABASE logistic_database;

-- Connecting to the database
\connect logistic_database;


-------------------------------------------------------------------------------
--                              Creating warehouses table
CREATE TABLE warehouses (
    warehouse_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0),
    location VARCHAR(500) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (created_at <= CURRENT_TIMESTAMP),
    deleted_at TIMESTAMPTZ CHECK (deleted_at IS NULL OR deleted_at > created_at)
);


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

-- Function tạo partition theo tháng cho bảng orders
CREATE OR REPLACE FUNCTION create_monthly_partition(parent_table TEXT, year INT, month INT)
RETURNS void AS $$
DECLARE
    start_date DATE := make_date(year, month, 1);
    end_date DATE := (make_date(year, month, 1) + INTERVAL '1 month')::DATE;
    partition_name TEXT := format('%I_%s', parent_table, to_char(start_date, 'YYYYMM'));
    sql TEXT;
BEGIN
    -- Kiểm tra nếu partition đã tồn tại
    IF EXISTS (
        SELECT 1 FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind = 'r'
        AND c.relname = partition_name
    ) THEN
        RAISE NOTICE 'Partition % already exists, skipping.', partition_name;
        RETURN;
    END IF;

    -- Tạo partition
    sql := format(
        'CREATE TABLE %I PARTITION OF %I
         FOR VALUES FROM (%L) TO (%L);',
        partition_name, parent_table, start_date, end_date
    );

    EXECUTE sql;
    RAISE NOTICE 'Created partition % for period % - %',
        partition_name, start_date, end_date;
END;
$$ LANGUAGE plpgsql;

SELECT create_monthly_partition('shipments', 2025, 8); -- Tạo partition cho tháng 8 năm 2025
SELECT create_monthly_partition('shipments', 2025, 9); -- Tạo partition cho tháng 9 năm 2025
SELECT create_monthly_partition('shipments', 2025, 10); -- Tạo partition cho tháng 10 năm 2025

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

-- Tạo partition cho bảng delivery_tracking
SELECT create_monthly_partition('delivery_tracking', 2025, 8); -- Tạo partition cho tháng 8 năm 2025
SELECT create_monthly_partition('delivery_tracking', 2025, 9); -- Tạo partition cho tháng 9 năm 2025
SELECT create_monthly_partition('delivery_tracking', 2025, 10); -- Tạo partition cho tháng 10 năm 2025

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


-------------------------------------------------------------------------------
--                              Creating indexes
CREATE INDEX inventory_product_id_idx ON inventory (product_id);
CREATE INDEX inventory_sku_id_idx ON inventory (sku_id);
CREATE INDEX shipments_order_id_idx ON shipments (order_id);
CREATE INDEX delivery_tracking_shipment_id_idx ON delivery_tracking (shipment_id);

-------------------------------------------------------------------------------
--                              Creating shipping_report_view
CREATE VIEW shipping_report_view AS
SELECT 
    s.shipment_id,
    s.order_id,
    s.warehouse_id,
    w.name AS warehouse_name,
    w.location,
    s.shipment_date,
    dt.checkpoint_time,
    dt.location AS checkpoint_location,
    s.status
FROM shipments s
JOIN warehouses w ON s.warehouse_id = w.warehouse_id
LEFT JOIN delivery_tracking dt ON s.shipment_id = dt.shipment_id
WHERE w.deleted_at IS NULL;

-- Creating inventory_report_view
CREATE VIEW inventory_report_view AS
SELECT 
    i.sku_id,
    i.product_id,
    i.stock_quantity,
    i.last_updated,
    i.warehouse_id,
    w.name AS warehouse_name,
    w.location
FROM inventory i
JOIN warehouses w ON i.warehouse_id = w.warehouse_id
WHERE w.deleted_at IS NULL;

--------------------------------------------------------------------------------
--                               Creating logging table

CREATE TABLE audit_log (
    log_id BIGSERIAL PRIMARY KEY,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    user_name TEXT NOT NULL,            -- ai thực hiện
    action_type TEXT NOT NULL,          -- INSERT, UPDATE, DELETE, CREATE TABLE, ALTER TABLE ...
    object_type TEXT,                   -- TABLE, INDEX, VIEW ...
    object_name TEXT,                   -- tên object tác động
    query TEXT                        -- câu lệnh SQL gốc
);


-- Trigger function to log changes
CREATE OR REPLACE FUNCTION audit_dml_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_log(user_name, action_type, object_type, object_name, query)
        VALUES (session_user, TG_OP, 'TABLE', TG_TABLE_NAME, current_query());
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_log(user_name, action_type, object_type, object_name, query)
        VALUES (session_user, TG_OP, 'TABLE', TG_TABLE_NAME, current_query());
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_log(user_name, action_type, object_type, object_name, query)
        VALUES (session_user, TG_OP, 'TABLE', TG_TABLE_NAME, current_query());
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit_ddl_trigger()
RETURNS event_trigger AS $$
BEGIN
    INSERT INTO audit_log(user_name, action_type, object_type, object_name, query)
    SELECT
        session_user,
        tg_tag,  -- ví dụ: CREATE TABLE, ALTER TABLE
        object_type,
        object_identity,
        current_query()
    FROM pg_event_trigger_ddl_commands();
END;
$$ LANGUAGE plpgsql;

-- Tạo trigger cho các bảng cần audit
CREATE EVENT TRIGGER ddl_audit
ON ddl_command_end
EXECUTE FUNCTION audit_ddl_trigger();

CREATE TRIGGER warehouses_audit
AFTER INSERT OR UPDATE OR DELETE ON warehouses
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();

CREATE TRIGGER inventory_audit
AFTER INSERT OR UPDATE OR DELETE ON inventory
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger(); 

CREATE TRIGGER shipments_audit
AFTER INSERT OR UPDATE OR DELETE ON shipments
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();

CREATE TRIGGER delivery_tracking_audit
AFTER INSERT OR UPDATE OR DELETE ON delivery_tracking
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();

--------------------------------------------------------------------------------