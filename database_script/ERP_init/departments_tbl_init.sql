-------------------------------------------------------------------------------------------------
--                              Creating departments table
CREATE TABLE departments (
    department_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0)
);
-- ==========================================
-- Function: Insert new department
-- ==========================================
CREATE OR REPLACE FUNCTION insert_department(
    p_name VARCHAR
)
RETURNS BIGINT AS $$
DECLARE
    v_department_id BIGINT;
BEGIN
    -- Validate dữ liệu
    IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
        RAISE EXCEPTION 'Department name cannot be empty';
    END IF;

    -- Insert
    INSERT INTO departments(name)
    VALUES (p_name)
    RETURNING department_id INTO v_department_id;

    RETURN v_department_id;
END;
$$ LANGUAGE plpgsql;
-- ==========================================
-- Function: Update department info
-- ==========================================
CREATE OR REPLACE FUNCTION update_department(
    p_department_id BIGINT,
    p_name VARCHAR DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE departments
    SET name = COALESCE(p_name, name)
    WHERE department_id = p_department_id;

    -- Nếu không tìm thấy record
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Department % not found', p_department_id;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Insert department mới
SELECT insert_department('Sales');

-- Update department
SELECT update_department(1, p_name := 'Marketing');
