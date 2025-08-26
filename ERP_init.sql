-- Creating the database
CREATE DATABASE erp_database;

-- Connecting to the database
\connect erp_database;

-- Creating departments table
CREATE TABLE departments (
    department_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0)
);

-- Creating employees table
CREATE TABLE employees (
    employee_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0),
    email VARCHAR(255) UNIQUE NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    department_id BIGINT NOT NULL REFERENCES departments(department_id),
    hire_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP CHECK (hire_date <= CURRENT_TIMESTAMP),
    salary DECIMAL(12,2) NOT NULL CHECK (salary > 0),
    deleted_at TIMESTAMP CHECK (deleted_at IS NULL OR deleted_at > hire_date)
);

-- Creating trigger function for employee_id
CREATE FUNCTION generate_employee_id() RETURNS TRIGGER AS $$
BEGIN
    NEW.employee_id = 'EMP_' || LPAD(nextval('employee_id_seq')::TEXT, 3, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE employee_id_seq;
CREATE TRIGGER employee_id_trigger
    BEFORE INSERT ON employees
    FOR EACH ROW
    EXECUTE FUNCTION generate_employee_id();

-- Creating suppliers table
CREATE TABLE suppliers (
    supplier_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0),
    contact_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL CHECK (phone ~* '^\+?[0-9]{7,15}$'),
    email VARCHAR(255) NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP CHECK (deleted_at IS NULL OR deleted_at > created_at)
);

-- Creating accounts table
CREATE TABLE accounts (
    account_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    account_name VARCHAR(255) NOT NULL CHECK (LENGTH(account_name) > 0),
    account_type VARCHAR(50) NOT NULL
);

-- Creating enum type for purchase order status
CREATE TYPE po_status AS ENUM ('draft', 'approved', 'received', 'cancelled');

-- Creating purchase_orders table with RANGE partitioning by month on order_date
CREATE TABLE purchase_orders (
    po_id BIGINT GENERATED ALWAYS AS IDENTITY,
    supplier_id BIGINT NOT NULL REFERENCES suppliers(supplier_id),
    order_date TIMESTAMP NOT NULL CHECK (order_date <= CURRENT_TIMESTAMP),
    status po_status NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    PRIMARY KEY (po_id, order_date)
) PARTITION BY RANGE (order_date);

-- Creating partitions for purchase_orders table (example for 2025)
CREATE TABLE purchase_orders_202501 PARTITION OF purchase_orders FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE purchase_orders_202502 PARTITION OF purchase_orders FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
-- Add more partitions as needed

-- Creating purchase_order_items table with RANGE and HASH partitioning
CREATE TABLE purchase_order_items (
    po_item_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    po_id BIGINT NOT NULL REFERENCES purchase_orders(po_id),
    product_id VARCHAR(20) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
    order_date TIMESTAMP NOT NULL
) PARTITION BY RANGE (order_date);

-- Creating sub-partitions with HASH on po_id
CREATE TABLE purchase_order_items_202501 PARTITION OF purchase_order_items
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01')
    PARTITION BY HASH (po_id);

CREATE TABLE purchase_order_items_202501_p0 PARTITION OF purchase_order_items_202501 FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE purchase_order_items_202501_p1 PARTITION OF purchase_order_items_202501 FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE purchase_order_items_202501_p2 PARTITION OF purchase_order_items_202501 FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE purchase_order_items_202501_p3 PARTITION OF purchase_order_items_202501 FOR VALUES WITH (MODULUS 4, REMAINDER 3);

-- Creating enum types for financial transactions
CREATE TYPE transaction_type AS ENUM ('debit', 'credit');
CREATE TYPE transaction_status AS ENUM ('draft', 'approved', 'received', 'cancelled');

-- Creating financial_transactions table with RANGE partitioning by month on transaction_date
CREATE TABLE financial_transactions (
    transaction_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    transaction_date TIMESTAMP NOT NULL CHECK (transaction_date <= CURRENT_TIMESTAMP),
    account_id BIGINT NOT NULL REFERENCES accounts(account_id),
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    type transaction_type NOT NULL,
    status transaction_status NOT NULL
) PARTITION BY RANGE (transaction_date);

-- Creating partitions for financial_transactions table (example for 2025)
CREATE TABLE financial_transactions_202501 PARTITION OF financial_transactions FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE financial_transactions_202502 PARTITION OF financial_transactions FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
-- Add more partitions as needed

-- Creating trigger function for total_amount calculation in purchase_orders
CREATE FUNCTION calculate_from_items() RETURNS TRIGGER AS $$
BEGIN
    NEW.total_amount = (
        SELECT COALESCE(SUM(poi.unit_price * poi.quantity), 0)
        FROM purchase_order_items poi
        WHERE poi.po_id = NEW.po_id
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER total_amount_trigger
    BEFORE INSERT OR UPDATE ON purchase_orders
    FOR EACH ROW
    EXECUTE FUNCTION calculate_from_items();

-- Creating indexes
CREATE INDEX employees_hire_date_idx ON employees (hire_date);
CREATE INDEX suppliers_name_idx ON suppliers (name);
CREATE INDEX purchase_orders_supplier_id_idx ON purchase_orders (supplier_id);
CREATE INDEX purchase_order_items_po_id_idx ON purchase_order_items (po_id);
CREATE INDEX financial_transactions_transaction_date_idx ON financial_transactions (transaction_date);