--------------------------------------------------------------------------------
--                               Creating products_sku table
CREATE TABLE products_sku (
    sku_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    sku VARCHAR(50) UNIQUE NOT NULL,
    product_id VARCHAR(20) NOT NULL REFERENCES products(product_id),
    color VARCHAR(50),
    size VARCHAR(50),
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (created_at <= now()),
    deleted_at TIMESTAMPTZ CHECK (deleted_at IS NULL OR deleted_at > created_at)
);
--------------------------------------------------------------------------------
-- Creating indexes
CREATE INDEX products_sku_sku_idx ON products_sku USING hash (sku);
CREATE INDEX products_price_idx ON products_sku (price);