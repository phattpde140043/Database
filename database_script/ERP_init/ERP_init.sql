-- Creating the database
CREATE DATABASE erp_database;

-- Connecting to the database
\connect erp_database;

CREATE EXTENSION IF NOT EXISTS pgcrypto;


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

------------------------------------------------------------------------------------------------------
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

CREATE TRIGGER departments_audit
AFTER INSERT OR UPDATE OR DELETE ON departments
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();

CREATE TRIGGER employees_audit
AFTER INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();

CREATE TRIGGER suppliers_audit
AFTER INSERT OR UPDATE OR DELETE ON suppliers
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();

CREATE TRIGGER accounts_audit
AFTER INSERT OR UPDATE OR DELETE ON accounts
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();

CREATE TRIGGER purchase_orders_audit
AFTER INSERT OR UPDATE OR DELETE ON purchase_orders
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();

CREATE TRIGGER purchase_order_items_audit
AFTER INSERT OR UPDATE OR DELETE ON purchase_order_items
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();

CREATE TRIGGER financial_transactions_audit
AFTER INSERT OR UPDATE OR DELETE ON financial_transactions
FOR EACH ROW EXECUTE FUNCTION audit_dml_trigger();
------------------------------------------------------------------------------------------------------