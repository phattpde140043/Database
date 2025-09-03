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

-----------------------------------------------------------------------------------
-- Insert SKU
CREATE OR REPLACE FUNCTION insert_sku(
    p_sku VARCHAR,
    p_product_id VARCHAR,
	p_price DECIMAL(10,2),
    p_color VARCHAR DEFAULT NULL,
    p_size VARCHAR DEFAULT NULL
    
)
RETURNS BIGINT AS $$
DECLARE
    v_sku_id BIGINT;
    v_exists INT;
BEGIN
    -- Kiểm tra SKU code hợp lệ
    IF p_sku IS NULL OR LENGTH(TRIM(p_sku)) = 0 THEN
        RAISE EXCEPTION 'SKU code cannot be empty';
    END IF;

    -- Kiểm tra SKU có bị trùng không
    SELECT COUNT(*) INTO v_exists FROM products_sku WHERE sku = p_sku AND deleted_at IS NULL;
    IF v_exists > 0 THEN
        RAISE EXCEPTION 'SKU already exists: %', p_sku;
    END IF;

    -- Kiểm tra product_id tồn tại và chưa bị xóa
    SELECT COUNT(*) INTO v_exists FROM products WHERE product_id = p_product_id AND deleted_at IS NULL;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'Product not found or deleted: %', p_product_id;
    END IF;

    -- Kiểm tra giá > 0
    IF p_price <= 0 THEN
        RAISE EXCEPTION 'Price must be greater than 0';
    END IF;

    -- Insert
    INSERT INTO products_sku (sku, product_id, color, size, price)
    VALUES (p_sku, p_product_id, p_color, p_size, p_price)
    RETURNING sku_id INTO v_sku_id;

    RETURN v_sku_id;
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------------
-- update SKU
CREATE OR REPLACE FUNCTION update_sku(
    p_sku_id BIGINT,
    p_sku VARCHAR ,
    p_color VARCHAR ,
    p_size VARCHAR ,
    p_price DECIMAL(10,2)
)
RETURNS VOID AS $$
DECLARE
    v_exists INT;
BEGIN
    -- Kiểm tra SKU tồn tại
    SELECT COUNT(*) INTO v_exists FROM products_sku WHERE sku_id = p_sku_id AND deleted_at IS NULL;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'SKU not found or deleted: %', p_sku_id;
    END IF;

    -- Kiểm tra SKU code trùng (nếu có thay đổi)
    IF p_sku IS NOT NULL THEN
        SELECT COUNT(*) INTO v_exists FROM products_sku WHERE sku = p_sku AND sku_id <> p_sku_id AND deleted_at IS NULL;
        IF v_exists > 0 THEN
            RAISE EXCEPTION 'SKU already exists: %', p_sku;
        END IF;
    END IF;

    -- Kiểm tra giá hợp lệ
    IF p_price IS NOT NULL AND p_price <= 0 THEN
        RAISE EXCEPTION 'Price must be greater than 0';
    END IF;

    -- Update
    UPDATE products_sku
    SET 
        sku = p_sku,
        color = p_color,
        size = p_size,
        price = p_price
    WHERE sku_id = p_sku_id;
END;
$$ LANGUAGE plpgsql;

---------------------------------------------------------------------------------------------------------
-- soft delete SKU
CREATE OR REPLACE FUNCTION soft_delete_sku(p_sku_id BIGINT)
RETURNS VOID AS $$
DECLARE
    v_exists INT;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM products_sku WHERE sku_id = p_sku_id AND deleted_at IS NULL;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'SKU not found or already deleted: %', p_sku_id;
    END IF;

    UPDATE products_sku
    SET deleted_at = now()
    WHERE sku_id = p_sku_id;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------------------------
-- get SKU by price range
CREATE OR REPLACE FUNCTION search_skus_by_price(p_min DECIMAL, p_max DECIMAL)
RETURNS TABLE(sku_id BIGINT, sku VARCHAR,product_id VARCHAR,color VARCHAR,size VARCHAR, price DECIMAL(10,2),created_at TIMESTAMPTZ) AS $$
BEGIN
    RETURN QUERY
    SELECT ps.sku_id, ps.sku,ps.product_id,ps.color,ps.size, ps.price,ps.created_at
    FROM products_sku ps
    WHERE ps.deleted_at IS NULL
      AND ps.price BETWEEN p_min AND p_max
    ORDER BY ps.price ASC;
END;
$$ LANGUAGE plpgsql;


Select * from products_sku
Select insert_sku('SKU_SMART_002','PROD_00001',599.9,'White','256GB')
Select update_sku(14,'SKU_SMART_003','Gray','256GB',599.9)
Select soft_delete_sku(15)
Select search_skus_by_price(17,30)
