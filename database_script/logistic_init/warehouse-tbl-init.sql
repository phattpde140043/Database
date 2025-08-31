-------------------------------------------------------------------------------
--                              Creating warehouses table
CREATE TABLE warehouses (
    warehouse_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0),
    location VARCHAR(500) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (created_at <= CURRENT_TIMESTAMP),
    deleted_at TIMESTAMPTZ CHECK (deleted_at IS NULL OR deleted_at > created_at)
);

