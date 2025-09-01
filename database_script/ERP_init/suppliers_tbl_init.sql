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

-- ==========================================
-- Function: Insert new supplier
-- ==========================================
CREATE OR REPLACE FUNCTION insert_supplier(
    p_name VARCHAR,
    p_contact_name VARCHAR,
    p_phone BYTEA,
    p_email BYTEA
)
RETURNS BIGINT AS $$
DECLARE
    v_supplier_id BIGINT;
BEGIN
    -- Validate dữ liệu
    IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
        RAISE EXCEPTION 'Supplier name cannot be empty';
    END IF;

    IF p_contact_name IS NULL OR LENGTH(TRIM(p_contact_name)) = 0 THEN
        RAISE EXCEPTION 'Contact name cannot be empty';
    END IF;

    -- Insert
    INSERT INTO suppliers(name, contact_name, phone, email)
    VALUES (p_name, p_contact_name, p_phone, p_email)
    RETURNING supplier_id INTO v_supplier_id;

    RETURN v_supplier_id;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- Function: Update supplier
-- ==========================================
CREATE OR REPLACE FUNCTION update_supplier(
    p_supplier_id BIGINT,
    p_name VARCHAR DEFAULT NULL,
    p_contact_name VARCHAR DEFAULT NULL,
    p_phone BYTEA DEFAULT NULL,
    p_email BYTEA DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE suppliers
    SET name = COALESCE(p_name, name),
        contact_name = COALESCE(p_contact_name, contact_name),
        phone = COALESCE(p_phone, phone),
        email = COALESCE(p_email, email)
    WHERE supplier_id = p_supplier_id
      AND deleted_at IS NULL;  -- chỉ update nếu chưa bị xóa mềm

    -- Nếu không có dòng nào bị ảnh hưởng
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Supplier % not found or already deleted', p_supplier_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- Function: Soft delete supplier
-- ==========================================
CREATE OR REPLACE FUNCTION soft_delete_supplier(
    p_supplier_id BIGINT
)
RETURNS VOID AS $$
BEGIN
    UPDATE suppliers
    SET deleted_at = now()
    WHERE supplier_id = p_supplier_id
      AND deleted_at IS NULL; -- tránh xóa lại nhiều lần

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Supplier % not found or already deleted', p_supplier_id;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Insert supplier mới
SELECT insert_supplier('ABC Co', 'John Doe', '0123456789'::bytea, 'john@abc.com'::bytea);

-- Update supplier
SELECT update_supplier(1, p_name := 'ABC International');

-- Soft delete supplier
SELECT soft_delete_supplier(1);
