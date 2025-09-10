--------------------------------------------------------------------------------
--                              Creating payment_types table
CREATE TABLE payment_types (
    payment_type_id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (updated_at <= CURRENT_TIMESTAMP)
);

-- function update payment_types
CREATE OR REPLACE FUNCTION update_payment_type(
    p_payment_type_id INT,
    p_name VARCHAR
)
RETURNS VOID AS $$
BEGIN
    -- Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM payment_types WHERE payment_type_id = p_payment_type_id) THEN
        RAISE EXCEPTION 'Payment type with id % does not exist', p_payment_type_id;
    END IF;

    -- Kiểm tra tên hợp lệ
    IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
        RAISE EXCEPTION 'Payment type name cannot be empty';
    END IF;

    -- Cập nhật
    UPDATE payment_types
    SET name = p_name
    WHERE payment_type_id = p_payment_type_id;
END;
$$ LANGUAGE plpgsql;


-- function insert payment_types
CREATE OR REPLACE FUNCTION insert_payment_type(
    p_name VARCHAR
)
RETURNS INT AS $$
DECLARE
    v_payment_type_id INT;
BEGIN
    -- Kiểm tra tên hợp lệ
    IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
        RAISE EXCEPTION 'Payment type name cannot be empty';
    END IF;

    -- Thêm bản ghi mới
    INSERT INTO payment_types(name)
    VALUES (p_name)
    RETURNING payment_type_id INTO v_payment_type_id;

    RETURN v_payment_type_id;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- Trigger: update column updated_at
-- ==========================================
CREATE OR REPLACE FUNCTION payment_type_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payment_type_set_timestamp_trigger ON payment_types;

CREATE TRIGGER payment_type_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON payment_types
FOR EACH ROW
EXECUTE FUNCTION payment_type_set_timestamp();