--------------------------------------------------------------------------------
--                             Creating categories table
CREATE TABLE categories (
    category_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (created_at <= now()),
    deleted_at TIMESTAMPTZ CHECK (deleted_at IS NULL OR deleted_at > created_at)
);