--------------------------------------------------------------------------------
--                           Creating products table
CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0),
    category_id BIGINT NOT NULL REFERENCES categories(category_id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (created_at <= now()),
    deleted_at TIMESTAMPTZ CHECK (deleted_at IS NULL OR deleted_at > created_at)
);

---------------------------------------------------------------------------------- Creating trigger function for product_id
-- This function generates a unique product_id for each new product
CREATE FUNCTION generate_product_id() RETURNS TRIGGER AS $$
BEGIN
    NEW.product_id = 'PROD_' || LPAD(nextval('product_id_seq')::TEXT, 5, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE product_id_seq;
CREATE TRIGGER product_id_trigger
    BEFORE INSERT ON products
    FOR EACH ROW
    EXECUTE FUNCTION generate_product_id();

--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Creating indexes
CREATE INDEX products_name_idx ON products USING hash (name);
