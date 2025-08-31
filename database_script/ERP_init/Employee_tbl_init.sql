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

----------------------------------------------------------------------------
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

----------------------------------------------------------------------------
CREATE INDEX employees_hire_date_idx ON employees (hire_date);
