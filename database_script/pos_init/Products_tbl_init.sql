--------------------------------------------------------------------------------
--                           Creating products table
CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0),
    category_id BIGINT NOT NULL REFERENCES categories(category_id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (created_at <= now()),
    deleted_at TIMESTAMPTZ CHECK (deleted_at IS NULL OR deleted_at > created_at),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (updated_at <= CURRENT_TIMESTAMP)
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
-- insert product
CREATE OR REPLACE FUNCTION insert_product(
    p_name VARCHAR,
    p_category_id BIGINT,
    p_sku VARCHAR,
    p_price DECIMAL(10,2),
    p_color VARCHAR DEFAULT NULL,
    p_size VARCHAR DEFAULT NULL
)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id VARCHAR;
BEGIN
    -- Insert product (product_id được trigger generate)
    INSERT INTO products(name, category_id)
    VALUES (p_name, p_category_id)
    RETURNING product_id INTO v_product_id;

    -- Insert ít nhất 1 SKU (dùng tham số truyền vào)
    INSERT INTO products_sku(sku, product_id, color, size, price)
    VALUES (p_sku, v_product_id, p_color, p_size, p_price);

    -- Trả về product_id vừa tạo
    RETURN v_product_id;
END;
$$;


--------------------------------------------------------------------------------------------------------
-- Function to update product details
CREATE OR REPLACE FUNCTION update_product(
    p_product_id VARCHAR,
    p_name VARCHAR DEFAULT NULL,
    p_category_id BIGINT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_exists INT;
BEGIN
    -- Kiểm tra product tồn tại
    SELECT COUNT(*) INTO v_exists FROM products WHERE product_id = p_product_id AND deleted_at IS NULL;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'Product not found or already deleted: %', p_product_id;
    END IF;

    -- Kiểm tra category hợp lệ (nếu có truyền vào)
    IF p_category_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_exists FROM categories WHERE category_id = p_category_id;
        IF v_exists = 0 THEN
            RAISE EXCEPTION 'Category not found: %', p_category_id;
        END IF;
    END IF;

    -- Update
    UPDATE products
    SET 
        name = COALESCE(p_name, name),
        category_id = COALESCE(p_category_id, category_id)
    WHERE product_id = p_product_id;
END;
$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------
-- Soft-delete product
CREATE OR REPLACE PROCEDURE soft_delete_product(p_product_id VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_active_sku_count INT;
BEGIN
    -- Kiểm tra product tồn tại
    IF NOT EXISTS (SELECT 1 FROM products WHERE product_id = p_product_id AND deleted_at IS NULL) THEN
        RAISE EXCEPTION 'Product % not found or already deleted', p_product_id;
    END IF;

    -- Kiểm tra SKU active
    SELECT COUNT(*) INTO v_active_sku_count
    FROM products_sku
    WHERE product_id = p_product_id
      AND deleted_at IS NULL;

    IF v_active_sku_count > 0 THEN
        RAISE EXCEPTION 'Cannot delete product % because it still has active SKUs', p_product_id;
    END IF;

    -- Soft delete product
    UPDATE products
    SET deleted_at = NOW()
    WHERE product_id = p_product_id;
END;
$$;

--------------------------------------------------------------------------------
-- Creating indexes
CREATE INDEX products_name_idx ON products USING hash (name);

--------------------------------------------------------------
-- ==========================================
-- Trigger: update column updated_at
-- ==========================================
CREATE OR REPLACE FUNCTION product_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS product_set_timestamp_trigger ON products;

CREATE TRIGGER product_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION product_set_timestamp();