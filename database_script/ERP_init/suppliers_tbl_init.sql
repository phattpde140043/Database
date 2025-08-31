----------------------------------------------------------------------------------------------------
--                                  Creating suppliers table
CREATE TABLE suppliers (
    supplier_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0),
    contact_name VARCHAR(255) NOT NULL,
    phone BYTEA NOT NULL ,
    email BYTEA NOT NULL ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (created_at <= CURRENT_TIMESTAMP),
    deleted_at TIMESTAMPTZ CHECK (deleted_at IS NULL OR deleted_at > created_at)
);
------------------------------------------------------------
CREATE INDEX suppliers_name_idx ON suppliers (name);