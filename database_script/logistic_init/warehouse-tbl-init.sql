-------------------------------------------------------------------------------
--                              Creating warehouses table
CREATE TABLE warehouses (
    warehouse_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0),
    location VARCHAR(500) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (created_at <= CURRENT_TIMESTAMP),
    deleted_at TIMESTAMPTZ CHECK (deleted_at IS NULL OR deleted_at > created_at)
);

-- ===========================
-- Function: Insert Warehouse
-- ===========================
CREATE OR REPLACE FUNCTION insert_warehouse(
    p_name VARCHAR,
    p_location VARCHAR
)
RETURNS BIGINT AS $$
DECLARE
    v_warehouse_id BIGINT;
BEGIN
    -- Validate input
    IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
        RAISE EXCEPTION 'Warehouse name cannot be empty';
    END IF;

    IF p_location IS NULL OR LENGTH(TRIM(p_location)) = 0 THEN
        RAISE EXCEPTION 'Warehouse location cannot be empty';
    END IF;

    -- Insert data
    INSERT INTO warehouses(name, location)
    VALUES (p_name, p_location)
    RETURNING warehouse_id INTO v_warehouse_id;

    RETURN v_warehouse_id;
END;
$$ LANGUAGE plpgsql;

-- ===========================
-- Function: Update Warehouse
-- ===========================
CREATE OR REPLACE FUNCTION update_warehouse(
    p_warehouse_id BIGINT,
    p_name VARCHAR DEFAULT NULL,
    p_location VARCHAR DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- Check tồn tại
    IF NOT EXISTS (SELECT 1 FROM warehouses WHERE warehouse_id = p_warehouse_id AND deleted_at IS NULL) THEN
        RAISE EXCEPTION 'Warehouse with id % does not exist or is deleted', p_warehouse_id;
    END IF;

    -- Update dữ liệu
    UPDATE warehouses
    SET name = p_name,
        location = p_location
    WHERE warehouse_id = p_warehouse_id;
END;
$$ LANGUAGE plpgsql;

-- ===========================
-- Function: Soft Delete Warehouse
-- ===========================
CREATE OR REPLACE FUNCTION soft_delete_warehouse(
    p_warehouse_id BIGINT
)
RETURNS VOID AS $$
BEGIN
    -- Check tồn tại
    IF NOT EXISTS (SELECT 1 FROM warehouses WHERE warehouse_id = p_warehouse_id AND deleted_at IS NULL) THEN
        RAISE EXCEPTION 'Warehouse with id % does not exist or is already deleted', p_warehouse_id;
    END IF;

    -- Soft delete
    UPDATE warehouses
    SET deleted_at = now()
    WHERE warehouse_id = p_warehouse_id;
END;
$$ LANGUAGE plpgsql;

-- Insert
SELECT insert_warehouse('Kho Hà Nội', 'Hà Nội, Việt Nam');

-- Update
SELECT update_warehouse(1, 'Kho HN Mới', 'Hà Nam, Việt Nam');

-- Soft Delete
SELECT soft_delete_warehouse(1);

