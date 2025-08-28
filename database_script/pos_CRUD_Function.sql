------------------------------------------------------------------------------------
-- Script Name: CRUD_Function.sql
-- Description: This script contains SQL functions to perform Create, Read, Update,
--              and Delete (CRUD) operations on the database tables.
-------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--                                  Pos_Database
-----------------------------------------------------------------------------------
--                      Customer Table CRUD Operations
-----------------------------------------------------------------------------------

-- Function to create a new customer
CREATE OR REPLACE FUNCTION insert_customer(
    p_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_address VARCHAR
)
RETURNS BIGINT AS $$
DECLARE
    v_customer_id BIGINT;
    v_exists INT;
BEGIN
    -- Kiểm tra email có hợp lệ không
    IF p_email !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION 'Invalid email format: %', p_email;
    END IF;

    -- Kiểm tra số điện thoại có hợp lệ không (chỉ cho phép số)
    IF p_phone !~ '^[0-9]{8,15}$' THEN
        RAISE EXCEPTION 'Invalid phone number: %', p_phone;
    END IF;

    -- Kiểm tra email có bị trùng không
    SELECT COUNT(*) INTO v_exists FROM customers WHERE email = p_email;
    IF v_exists > 0 THEN
        RAISE EXCEPTION 'Email already exists: %', p_email;
    END IF;

    -- Insert khách hàng
    INSERT INTO customers (name, email, phone, address, created_at)
    VALUES (p_name, p_email, p_phone, p_address, now())
    RETURNING customer_id INTO v_customer_id;

    RETURN v_customer_id;
END;
$$ LANGUAGE plpgsql;


-- Function to read customer details by ID
CREATE OR REPLACE FUNCTION get_customer_by_id(p_customer_id BIGINT)
RETURNS TABLE (
    customer_id BIGINT,
    name VARCHAR,
    email VARCHAR,
    phone VARCHAR,
    address VARCHAR,
    created_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT customer_id, name, email, phone, address, created_at
    FROM customers
    WHERE customer_id = p_customer_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update customer details
CREATE OR REPLACE FUNCTION update_customer(
    p_customer_id BIGINT,
    p_name VARCHAR DEFAULT NULL,
    p_email VARCHAR DEFAULT NULL,
    p_phone VARCHAR DEFAULT NULL,
    p_address VARCHAR DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_exists INT;
BEGIN
    -- Kiểm tra customer tồn tại
    SELECT COUNT(*) INTO v_exists FROM customers WHERE customer_id = p_customer_id;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'Customer not found: %', p_customer_id;
    END IF;

    -- Update linh hoạt (chỉ update nếu field khác NULL)
    UPDATE customers
    SET 
        name = COALESCE(p_name, name),
        email = COALESCE(p_email, email),
        phone = COALESCE(p_phone, phone),
        address = COALESCE(p_address, address),
        updated_at = now()
    WHERE customer_id = p_customer_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete a customer by ID
CREATE OR REPLACE FUNCTION soft_delete_customer(p_customer_id BIGINT)
RETURNS VOID AS $$
DECLARE
    v_exists INT;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM customers WHERE customer_id = p_customer_id;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'Customer not found: %', p_customer_id;
    END IF;

    UPDATE customers
    SET deleted_at = now()
    WHERE customer_id = p_customer_id;
END;
$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--                      Product Table CRUD Operations
-----------------------------------------------------------------------------------
-- insert product
CREATE OR REPLACE FUNCTION insert_product(
    p_name VARCHAR,
    p_category_id BIGINT
)
RETURNS VARCHAR AS $$
DECLARE
    v_product_id VARCHAR(20);
    v_exists INT;
BEGIN
    -- Kiểm tra tên sản phẩm hợp lệ
    IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
        RAISE EXCEPTION 'Product name cannot be empty';
    END IF;

    -- Kiểm tra category có tồn tại không
    SELECT COUNT(*) INTO v_exists FROM categories WHERE category_id = p_category_id;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'Category not found: %', p_category_id;
    END IF;

    -- Insert (product_id sẽ tự sinh bởi trigger generate_product_id)
    INSERT INTO products (name, category_id)
    VALUES (p_name, p_category_id)
    RETURNING product_id INTO v_product_id;

    RETURN v_product_id;
END;
$$ LANGUAGE plpgsql;


-- Function to read product details by ID
CREATE OR REPLACE FUNCTION get_product_by_id(p_product_id VARCHAR)
RETURNS TABLE (
    product_id VARCHAR,
    name VARCHAR,
    category_id BIGINT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT product_id, name, category_id, created_at, updated_at, deleted_at
    FROM products
    WHERE product_id = p_product_id;
END;
$$ LANGUAGE plpgsql;   

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

-- Function to delete a product by ID (soft delete)
CREATE OR REPLACE FUNCTION soft_delete_product(p_product_id VARCHAR)
RETURNS VOID AS $$
DECLARE
    v_exists INT;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM products WHERE product_id = p_product_id AND deleted_at IS NULL;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'Product not found or already deleted: %', p_product_id;
    END IF;

    UPDATE products
    SET deleted_at = now()
    WHERE product_id = p_product_id;
END;
$$ LANGUAGE plpgsql;

-- Function to restore a soft-deleted product
CREATE OR REPLACE FUNCTION restore_product(p_product_id VARCHAR)
RETURNS VOID AS $$
DECLARE
    v_exists INT;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM products WHERE product_id = p_product_id AND deleted_at IS NOT NULL;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'Product not found or not deleted: %', p_product_id;
    END IF;

    UPDATE products
    SET deleted_at = NULL
    WHERE product_id = p_product_id;
END;
$$ LANGUAGE plpgsql;

-- search products by name (case insensitive, partial match)
CREATE OR REPLACE FUNCTION search_products_by_name(p_name VARCHAR)
RETURNS TABLE (
    product_id VARCHAR,
    name VARCHAR,
    category_id BIGINT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT product_id, name, category_id, created_at, updated_at, deleted_at
    FROM products
    WHERE name ILIKE '%' || p_name || '%' AND deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql;

-- get all products by category
CREATE OR REPLACE FUNCTION get_products_by_category(p_category_id BIGINT)
RETURNS TABLE(product_id VARCHAR, name VARCHAR, created_at TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT product_id, name, created_at
    FROM products
    WHERE category_id = p_category_id
      AND deleted_at IS NULL
    ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------------
--                      Product SKU Table CRUD Operations
-----------------------------------------------------------------------------------
-- Insert SKU
CREATE OR REPLACE FUNCTION insert_sku(
    p_sku VARCHAR,
    p_product_id VARCHAR,
    p_color VARCHAR DEFAULT NULL,
    p_size VARCHAR DEFAULT NULL,
    p_price DECIMAL(10,2)
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

-- update SKU
CREATE OR REPLACE FUNCTION update_sku(
    p_sku_id BIGINT,
    p_sku VARCHAR DEFAULT NULL,
    p_color VARCHAR DEFAULT NULL,
    p_size VARCHAR DEFAULT NULL,
    p_price DECIMAL(10,2) DEFAULT NULL
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
        sku = COALESCE(p_sku, sku),
        color = COALESCE(p_color, color),
        size = COALESCE(p_size, size),
        price = COALESCE(p_price, price)
    WHERE sku_id = p_sku_id;
END;
$$ LANGUAGE plpgsql;

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


-- restore soft-deleted SKU
CREATE OR REPLACE FUNCTION restore_sku(p_sku_id BIGINT)
RETURNS VOID AS $$
DECLARE
    v_exists INT;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM products_sku WHERE sku_id = p_sku_id AND deleted_at IS NOT NULL;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'SKU not found or not deleted: %', p_sku_id;
    END IF;

    UPDATE products_sku
    SET deleted_at = NULL
    WHERE sku_id = p_sku_id;
END;
$$ LANGUAGE plpgsql;

-- get SKU by product_id
CREATE OR REPLACE FUNCTION get_skus_by_product_id(p_product_id VARCHAR)
RETURNS TABLE (
    sku_id BIGINT,
    sku VARCHAR,
    color VARCHAR,
    size VARCHAR,
    price DECIMAL(10,2),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT sku_id, sku, color, size, price, created_at, updated_at, deleted_at
    FROM products_sku
    WHERE product_id = p_product_id AND deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql;

-- get SKU by price range

CREATE OR REPLACE FUNCTION search_skus_by_price(p_min DECIMAL, p_max DECIMAL)
RETURNS TABLE(sku_id BIGINT, sku VARCHAR, price DECIMAL(10,2), product_id VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT sku_id, sku, price, product_id
    FROM products_sku
    WHERE deleted_at IS NULL
      AND price BETWEEN p_min AND p_max
    ORDER BY price ASC;
END;
$$ LANGUAGE plpgsql;


------------------------------------------------------------------------------------
--                      Categories Table CRUD Operations
-----------------------------------------------------------------------------------

-- insert category
CREATE OR REPLACE FUNCTION insert_category(
    p_name VARCHAR
)
RETURNS BIGINT AS $$
DECLARE
    v_category_id BIGINT;
    v_exists INT;
BEGIN
    -- Kiểm tra tên hợp lệ
    IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
        RAISE EXCEPTION 'Category name cannot be empty';
    END IF;

    -- Kiểm tra trùng tên category (chưa bị xóa)
    SELECT COUNT(*) INTO v_exists 
    FROM categories 
    WHERE LOWER(name) = LOWER(p_name) AND deleted_at IS NULL;
    IF v_exists > 0 THEN
        RAISE EXCEPTION 'Category already exists: %', p_name;
    END IF;

    -- Insert
    INSERT INTO categories (name)
    VALUES (p_name)
    RETURNING category_id INTO v_category_id;

    RETURN v_category_id;
END;
$$ LANGUAGE plpgsql;

-- update category
CREATE OR REPLACE FUNCTION update_category(
    p_category_id BIGINT,
    p_name VARCHAR DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_exists INT;
BEGIN
    -- Kiểm tra category tồn tại
    SELECT COUNT(*) INTO v_exists 
    FROM categories 
    WHERE category_id = p_category_id AND deleted_at IS NULL;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'Category not found or deleted: %', p_category_id;
    END IF;

    -- Kiểm tra tên không rỗng
    IF p_name IS NOT NULL AND LENGTH(TRIM(p_name)) = 0 THEN
        RAISE EXCEPTION 'Category name cannot be empty';
    END IF;

    -- Kiểm tra trùng tên
    IF p_name IS NOT NULL THEN
        SELECT COUNT(*) INTO v_exists 
        FROM categories 
        WHERE LOWER(name) = LOWER(p_name) AND category_id <> p_category_id AND deleted_at IS NULL;
        IF v_exists > 0 THEN
            RAISE EXCEPTION 'Category name already exists: %', p_name;
        END IF;
    END IF;

    -- Update
    UPDATE categories
    SET name = COALESCE(p_name, name)
    WHERE category_id = p_category_id;
END;
$$ LANGUAGE plpgsql;

-- get all categories
CREATE OR REPLACE FUNCTION get_all_categories()
RETURNS TABLE(category_id BIGINT, name VARCHAR, created_at TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT category_id, name, created_at
    FROM categories
    WHERE deleted_at IS NULL
    ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------------
--                      Orders Table CRUD Operations
-----------------------------------------------------------------------------------





------------------------------------------------------------------------------------
--                      Payment_types Table CRUD Operations
-----------------------------------------------------------------------------------






