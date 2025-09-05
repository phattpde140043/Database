--------------------------------------------------------------------------------
--                               Creating customers table
CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0),
    email BYTEA UNIQUE NOT NULL,
    phone BYTEA UNIQUE NOT NULL,
    address VARCHAR(500) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (created_at <= now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (updated_at <= now())
);

--------------------------------------------------------------------------------
-- Creating trigger to update updated_at on modification
CREATE OR REPLACE FUNCTION customer_update_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER customers_updated_at_trigger
BEFORE UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION customer_update_set_timestamp();

--------------------------------------------------------------------------------
-- Creating trigger function for customer_id
CREATE FUNCTION generate_customer_id() RETURNS TRIGGER AS $$
BEGIN
    NEW.customer_id = 'CUST_' || LPAD(nextval('customer_id_seq')::TEXT, 6, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE customer_id_seq;
CREATE TRIGGER customer_id_trigger
    BEFORE INSERT ON customers
    FOR EACH ROW
    EXECUTE FUNCTION generate_customer_id();

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-------------------------------------------------------------------------------
-- Trigger function sử dụng lại encrypt_text
CREATE OR REPLACE FUNCTION encrypt_customer_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Email
    IF NEW.email IS NOT NULL THEN
        NEW.email := encrypt_text(NEW.email::text);
    END IF;

    -- Phone
    IF NEW.phone IS NOT NULL THEN
        NEW.phone := encrypt_text(NEW.phone::text);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------------------------
-- Creating trigger to encrypt email and phone
CREATE TRIGGER trg_encrypt_customers
BEFORE INSERT OR UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION encrypt_customer_fields();
--------------------------------------------------------------------------------
-- Function to create a new customer
CREATE OR REPLACE FUNCTION insert_customer(
    p_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_address VARCHAR
)
RETURNS TEXT AS $$
DECLARE
    v_customer_id TEXT;
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

    -- Insert khách hàng
    INSERT INTO customers (name, email, phone, address)
    VALUES (p_name,encrypt_text(p_email),encrypt_text(p_phone), p_address)
    RETURNING customer_id INTO v_customer_id;

    RETURN v_customer_id;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------------------------
-- Function to update a customer
CREATE OR REPLACE FUNCTION update_customer(
    p_customer_id TEXT,
    p_name VARCHAR DEFAULT NULL,
    p_email VARCHAR DEFAULT NULL,
    p_phone VARCHAR DEFAULT NULL,
    p_address VARCHAR DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
    v_exists INT;
    v_updated INT;
BEGIN
    -- Kiểm tra customer tồn tại
    SELECT COUNT(*) INTO v_exists FROM customers WHERE customer_id = p_customer_id;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'Customer not found: %', p_customer_id;
    END IF;

    -- Update linh hoạt
    UPDATE customers
    SET 
        name = p_name,
        email = encrypt_text(p_email),
        phone = encrypt_text(p_phone),
        address = p_address,
        updated_at = now()
    WHERE customer_id = p_customer_id;

    -- Lấy số row bị ảnh hưởng
    GET DIAGNOSTICS v_updated = ROW_COUNT;

    RETURN v_updated;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Creating indexes
CREATE INDEX customers_email_idx ON customers USING hash (email);
CREATE INDEX customers_phone_idx ON customers USING hash (phone);
CREATE INDEX customers_name_idx ON customers USING hash (name);