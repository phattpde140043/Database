-- Creating the database
CREATE DATABASE erp_database;

-- Connecting to the database
\connect erp_database;

-------------------------------------------------------------------------------------------------
--                              Creating departments table
CREATE TABLE departments (
    department_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0)
);

----------------------------------------------------------------------------------------------------
--                              Creating employees table
CREATE TABLE employees (
    employee_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0),
    email BYTEA UNIQUE NOT NULL ,
    department_id BIGINT NOT NULL REFERENCES departments(department_id),
    hire_date TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (hire_date <= CURRENT_TIMESTAMP),
    salary DECIMAL(12,2) NOT NULL CHECK (salary > 0),
    deleted_at TIMESTAMPTZ CHECK (deleted_at IS NULL OR deleted_at > hire_date)
);

-- Creating trigger function for employee_id
CREATE FUNCTION generate_employee_id() RETURNS TRIGGER AS $$
BEGIN
    NEW.employee_id = 'EMP_' || LPAD(nextval('employee_id_seq')::TEXT, 4, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE employee_id_seq;
CREATE TRIGGER employee_id_trigger
    BEFORE INSERT ON employees
    FOR EACH ROW
    EXECUTE FUNCTION generate_employee_id();



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



----------------------------------------------------------------------------------------------------
--                                   Creating accounts table
CREATE TABLE accounts (
    account_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    account_name VARCHAR(255) NOT NULL CHECK (LENGTH(account_name) > 0),
    account_type VARCHAR(50) NOT NULL
);





----------------------------------------------------------------------------------------------------
-- Creating purchase_orders table with RANGE partitioning by month on order_date
CREATE TABLE purchase_orders (
    po_id BIGINT GENERATED ALWAYS AS IDENTITY,
    supplier_id BIGINT NOT NULL REFERENCES suppliers(supplier_id),
    order_date TIMESTAMPTZ NOT NULL CHECK (order_date <= CURRENT_TIMESTAMP),
    status VARCHAR(20) NOT NULL CHECK (status IN ('draft', 'approved', 'received', 'cancelled')),
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    PRIMARY KEY (po_id, order_date)
) PARTITION BY RANGE (order_date);

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

-- Creating partitions for purchase_orders table (example for 2025)
SELECT create_monthly_partition('purchase_orders', 2025, 8);
SELECT create_monthly_partition('purchase_orders', 2025, 9);
SELECT create_monthly_partition('purchase_orders', 2025, 10);
-- Add more partitions as needed




----------------------------------------------------------------------------------------------------
--          Creating purchase_order_items table with RANGE and HASH partitioning
CREATE TABLE purchase_order_items (
    po_item_id BIGINT  GENERATED ALWAYS AS IDENTITY,
    po_id BIGINT NOT NULL ,
    product_id VARCHAR(20) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
    order_date TIMESTAMPTZ NOT NULL CHECK (order_date <= CURRENT_TIMESTAMP),
    PRIMARY KEY (po_item_id, order_date),
    FOREIGN KEY (po_id, order_date) REFERENCES purchase_orders(po_id, order_date)
) PARTITION BY RANGE (order_date);

-- Creating sub-partitions with HASH on po_id
SELECT create_monthly_partition('purchase_order_items', 2025, 8);
SELECT create_monthly_partition('purchase_order_items', 2025, 9);
SELECT create_monthly_partition('purchase_order_items', 2025, 10);



-----------------------------------------------------------------------------------------------
-- Creating financial_transactions table with RANGE partitioning by month on transaction_date
CREATE TABLE financial_transactions (
    transaction_id BIGINT GENERATED ALWAYS AS IDENTITY,
    transaction_date TIMESTAMPTZ NOT NULL CHECK (transaction_date <= CURRENT_TIMESTAMP),
    account_id BIGINT NOT NULL REFERENCES accounts(account_id),
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    type VARCHAR(20) NOT NULL CHECK( type IN ('debit', 'credit')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('draft', 'approved', 'received', 'cancelled')),
    PRIMARY KEY (transaction_id, transaction_date)
) PARTITION BY RANGE (transaction_date);

-- Creating partitions for financial_transactions table (example for 2025)
SELECT create_monthly_partition('financial_transactions', 2025, 8);
SELECT create_monthly_partition('financial_transactions', 2025, 9);
SELECT create_monthly_partition('financial_transactions', 2025, 10);
-- Add more partitions as needed





------------------------------------------------------------------------------------------------------
--                                            Creating indexes
CREATE INDEX employees_hire_date_idx ON employees (hire_date);
CREATE INDEX suppliers_name_idx ON suppliers (name);
CREATE INDEX purchase_orders_supplier_id_idx ON purchase_orders (supplier_id);
CREATE INDEX purchase_order_items_po_id_idx ON purchase_order_items (po_id);
CREATE INDEX financial_transactions_transaction_date_idx ON financial_transactions (transaction_date);

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