
-- Creating the database
CREATE DATABASE pos_database;

-- Connecting to the database
\connect pos_database;

--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
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