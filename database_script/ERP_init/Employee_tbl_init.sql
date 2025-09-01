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


-- ==========================================
-- Function: Insert new employee
-- ==========================================
CREATE OR REPLACE FUNCTION insert_employee(
    p_employee_id VARCHAR,
    p_name VARCHAR,
    p_email BYTEA,
    p_department_id BIGINT,
    p_hire_date TIMESTAMPTZ DEFAULT now(),
    p_salary DECIMAL(12,2)
)
RETURNS VOID AS $$
BEGIN
    -- Validate dữ liệu
    IF LENGTH(TRIM(p_name)) = 0 THEN
        RAISE EXCEPTION 'Employee name cannot be empty';
    END IF;

    IF p_salary <= 0 THEN
        RAISE EXCEPTION 'Salary must be greater than 0';
    END IF;

    IF p_hire_date > now() THEN
        RAISE EXCEPTION 'Hire date cannot be in the future';
    END IF;

    -- Insert
    INSERT INTO employees(employee_id, name, email, department_id, hire_date, salary)
    VALUES (p_employee_id, p_name, p_email, p_department_id, p_hire_date, p_salary);
END;
$$ LANGUAGE plpgsql;


-- ==========================================
-- Function: Update employee info
-- ==========================================
CREATE OR REPLACE FUNCTION update_employee(
    p_employee_id VARCHAR,
    p_name VARCHAR DEFAULT NULL,
    p_email BYTEA DEFAULT NULL,
    p_department_id BIGINT DEFAULT NULL,
    p_salary DECIMAL(12,2) DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE employees
    SET 
        name = COALESCE(p_name, name),
        email = COALESCE(p_email, email),
        department_id = COALESCE(p_department_id, department_id),
        salary = COALESCE(p_salary, salary)
    WHERE employee_id = p_employee_id
      AND deleted_at IS NULL;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Employee % not found or already deleted', p_employee_id;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- ==========================================
-- Function: Soft delete employee
-- ==========================================
CREATE OR REPLACE FUNCTION soft_delete_employee(
    p_employee_id VARCHAR
)
RETURNS VOID AS $$
BEGIN
    UPDATE employees
    SET deleted_at = now()
    WHERE employee_id = p_employee_id
      AND deleted_at IS NULL;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Employee % not found or already deleted', p_employee_id;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Insert
SELECT insert_employee('E001', 'Nguyen Van A', 'a@example.com'::BYTEA, 1, now(), 1200.00);

-- Update
SELECT update_employee('E001', p_salary := 1500.00);

-- Soft delete
SELECT soft_delete_employee('E001');
