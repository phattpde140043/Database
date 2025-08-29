
-- Creating the database
CREATE DATABASE pos_database;

-- Connecting to the database
\connect pos_database;

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

-- Hàm tái sử dụng để mã hóa text
CREATE OR REPLACE FUNCTION encrypt_text(p_text VARCHAR)
RETURNS BYTEA AS $$
DECLARE
    secret_key TEXT := 'my_secret_key';
    v_encrypted BYTEA;
BEGIN
    IF p_text IS NULL THEN
        RETURN NULL;
    END IF;

    v_encrypted := pgp_sym_encrypt(p_text, secret_key);
    RETURN v_encrypted;
END;
$$ LANGUAGE plpgsql;

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

-- Trigger
CREATE TRIGGER trg_encrypt_customers
BEFORE INSERT OR UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION encrypt_customer_fields();


Select * from customers
INSERT INTO customers (name, email, phone, address)
VALUES ('Nguyen Van ZA', 'langtun@yahoo.com', '0973429584', '35 Do Huy Du, Ha Noi');

--------------------------------------------------------------------------------
--                             Creating categories table
CREATE TABLE categories (
    category_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (created_at <= now()),
    deleted_at TIMESTAMPTZ CHECK (deleted_at IS NULL OR deleted_at > created_at)
);



--------------------------------------------------------------------------------
--                           Creating products table
CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0),
    category_id BIGINT NOT NULL REFERENCES categories(category_id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (created_at <= now()),
    deleted_at TIMESTAMPTZ CHECK (deleted_at IS NULL OR deleted_at > created_at)
);

-- Creating trigger function for product_id
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
--                              Creating payment_types table
CREATE TABLE payment_types (
    payment_type_id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0)
);


--------------------------------------------------------------------------------
--                               Creating orders table
-- Creating orders table with RANGE partitioning by month on order_date
CREATE TABLE orders (
    order_id BIGINT GENERATED ALWAYS AS IDENTITY,
    customer_id VARCHAR(20) NOT NULL REFERENCES customers(customer_id),
    order_date TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (order_date <= now()),
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    shipping_address VARCHAR(500) NOT NULL,
    payment_type_id INT NOT NULL REFERENCES payment_types(payment_type_id),
    payment_status VARCHAR(20) NOT NULL CHECK (payment_status IN ('pending', 'completed', 'failed')) DEFAULT 'pending',
	PRIMARY KEY (order_id,order_date)
) PARTITION BY RANGE (order_date);

-- Trigger function to set default shipping_address from customers table
CREATE OR REPLACE FUNCTION set_default_shipping_address()
RETURNS TRIGGER AS $$
BEGIN
    -- Nếu chưa truyền shipping_address
    IF NEW.shipping_address IS NULL THEN
        SELECT c.address
        INTO NEW.shipping_address
        FROM customers c
        WHERE c.customer_id = NEW.customer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_set_shipping_address
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION set_default_shipping_address();

-- Function tạo partition theo tháng cho bảng orders
CREATE OR REPLACE FUNCTION create_monthly_partition(parent_table TEXT, year INT, month INT)
RETURNS void AS $$
DECLARE
    start_date DATE := make_date(year, month, 1);
    end_date DATE := (make_date(year, month, 1) + INTERVAL '1 month')::DATE;
    partition_name TEXT := format('%I_%s', parent_table, to_char(start_date, 'YYYYMM'));
    sql TEXT;
BEGIN
    -- Kiểm tra nếu partition đã tồn tại
    IF EXISTS (
        SELECT 1 FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind = 'r'
        AND c.relname = partition_name
    ) THEN
        RAISE NOTICE 'Partition % already exists, skipping.', partition_name;
        RETURN;
    END IF;

    -- Tạo partition
    sql := format(
        'CREATE TABLE %I PARTITION OF %I
         FOR VALUES FROM (%L) TO (%L);',
        partition_name, parent_table, start_date, end_date
    );

    EXECUTE sql;
    RAISE NOTICE 'Created partition % for period % - %',
        partition_name, start_date, end_date;
END;
$$ LANGUAGE plpgsql;

SELECT create_monthly_partition('orders', 2025, 8); -- Tạo partition cho tháng 8 năm 2025
SELECT create_monthly_partition('orders', 2025, 9); -- Tạo partition cho tháng 9 năm 2025
SELECT create_monthly_partition('orders', 2025, 10); -- Tạo partition cho tháng 10 năm 2025




--------------------------------------------------------------------------------
--                             Creating order_items table
-- Creating order_items table with RANGE and HASH partitioning
CREATE TABLE order_items (
    order_item_id BIGINT GENERATED ALWAYS AS IDENTITY,
    order_id BIGINT NOT NULL ,
    product_id VARCHAR(20) NOT NULL REFERENCES products(product_id),
    sku_id BIGINT NOT NULL REFERENCES products_sku(sku_id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
    order_date TIMESTAMPTZ NOT NULL ,
	PRIMARY KEY (order_id, order_item_id, order_date),
	FOREIGN KEY (order_id, order_date) REFERENCES orders(order_id, order_date)
) PARTITION BY RANGE (order_date);

SELECT create_monthly_partition('order_items', 2025, 8); -- Tạo partition cho tháng 8 năm 2025
SELECT create_monthly_partition('order_items', 2025, 9); -- Tạo partition cho tháng 9 năm 2025
SELECT create_monthly_partition('order_items', 2025, 10); -- Tạo partition cho tháng 10 năm 2025

--------------------------------------------------------------------------------
--                             Creating indexes and views
-- Creating indexes
CREATE INDEX customers_email_idx ON customers USING hash (email);
CREATE INDEX customers_phone_idx ON customers USING hash (phone);
CREATE INDEX customers_name_idx ON customers USING hash (name);
CREATE INDEX products_name_idx ON products USING hash (name);
CREATE INDEX products_sku_sku_idx ON products_sku USING hash (sku);
CREATE INDEX products_price_idx ON products_sku (price);
CREATE INDEX orders_customer_id_idx ON orders USING hash (customer_id);
CREATE INDEX orders_order_date_idx ON orders (order_date);
CREATE INDEX order_items_order_id_idx ON order_items USING hash (order_id);



-- Creating product_view
CREATE VIEW product_view AS
SELECT 
    ps.sku_id,
    ps.sku,
    ps.product_id,
    p.name AS product_name,
    p.category_id,
    c.name AS category_name,
    ps.color,
    ps.size,
    ps.price,
    ps.created_at
FROM products_sku ps
JOIN products p ON ps.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
WHERE p.deleted_at IS NULL AND c.deleted_at IS NULL;

-- Creating sales_report_view
CREATE OR REPLACE VIEW sales_report_view AS
SELECT 
    o.order_id,
    o.order_date,
    o.customer_id,
    c.name AS customer_name,
    o.total_amount,
    o.shipping_address,
    o.payment_status,
    pt.name AS payment_types,
    ps.sku,
    p.name AS product_name,
    oi.unit_price AS price,
    oi.quantity,
    COUNT(oi.order_item_id) OVER (PARTITION BY o.order_id) AS item_count
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products_sku ps ON oi.sku_id = ps.sku_id
JOIN products p ON oi.product_id = p.product_id
JOIN payment_types pt ON o.payment_type_id = pt.payment_type_id
WHERE c.created_at IS NOT NULL
ORDER BY o.order_date DESC, o.order_id, ps.sku;

--------------------------------------------------------------------------------
--                               Creating logging table

CREATE TABLE audit_log (
    log_id BIGSERIAL PRIMARY KEY,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    user_name TEXT NOT NULL,            -- ai thực hiện
    action_type TEXT NOT NULL,          -- INSERT, UPDATE, DELETE, CREATE TABLE, ALTER TABLE ...
    object_type TEXT,                   -- TABLE, INDEX, VIEW ...
    object_name TEXT,                   -- tên object tác động
    query TEXT                        -- câu lệnh SQL gốc
);


-- Trigger function to log changes
CREATE OR REPLACE FUNCTION audit_dml_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_log(user_name, action_type, object_type, object_name, query)
        VALUES (session_user, TG_OP, 'TABLE', TG_TABLE_NAME, current_query());
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_log(user_name, action_type, object_type, object_name, query)
        VALUES (session_user, TG_OP, 'TABLE', TG_TABLE_NAME, current_query());
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_log(user_name, action_type, object_type, object_name, query)
        VALUES (session_user, TG_OP, 'TABLE', TG_TABLE_NAME, current_query());
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit_ddl_trigger()
RETURNS event_trigger AS $$
BEGIN
    INSERT INTO audit_log(user_name, action_type, object_type, object_name, query)
    SELECT
        session_user,
        tg_tag,  -- ví dụ: CREATE TABLE, ALTER TABLE
        object_type,
        object_identity,
        current_query()
    FROM pg_event_trigger_ddl_commands();
END;
$$ LANGUAGE plpgsql;

-- Tạo trigger cho các bảng cần audit
CREATE EVENT TRIGGER ddl_audit
ON ddl_command_end
EXECUTE FUNCTION audit_ddl_trigger();

CREATE TRIGGER orders_audit
AFTER INSERT OR UPDATE OR DELETE ON orders
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();

CREATE TRIGGER customers_audit
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();

CREATE TRIGGER products_audit
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();

CREATE TRIGGER products_sku_audit
AFTER INSERT OR UPDATE OR DELETE ON products_sku
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();  


CREATE TRIGGER order_items_audit
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();

CREATE TRIGGER categories_audit
AFTER INSERT OR UPDATE OR DELETE ON categories
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();

CREATE TRIGGER payment_types_audit
AFTER INSERT OR UPDATE OR DELETE ON payment_types
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();

--------------------------------------------------------------------------------
--                               Retention policy


