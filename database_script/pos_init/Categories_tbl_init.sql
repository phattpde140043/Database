--------------------------------------------------------------------------------
--                             Creating categories table
CREATE TABLE categories (
    category_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (created_at <= now()),
    deleted_at TIMESTAMPTZ CHECK (deleted_at IS NULL OR deleted_at > created_at),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (updated_at <= CURRENT_TIMESTAMP)
);

----------------------------------------------------------------------------------
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


-------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------------
-- Soft delete category
CREATE OR REPLACE FUNCTION soft_delete_category(
    p_category_id BIGINT
)
RETURNS VOID AS $$
DECLARE
    v_exists INT;
BEGIN
    -- Kiểm tra category tồn tại và chưa bị xóa
    SELECT COUNT(*) INTO v_exists 
    FROM categories 
    WHERE category_id = p_category_id AND deleted_at IS NULL;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'Category not found or already deleted: %', p_category_id;
    END IF;

    -- Soft delete (đánh dấu deleted_at)
    UPDATE categories
    SET deleted_at = NOW()
    WHERE category_id = p_category_id;
END;
$$ LANGUAGE plpgsql;


-- ==========================================
-- Trigger: update column updated_at
-- ==========================================
CREATE OR REPLACE FUNCTION categories_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS categories_set_timestamp_trigger ON categories;

CREATE TRIGGER categories_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON categories
FOR EACH ROW
EXECUTE FUNCTION categories_set_timestamp();
