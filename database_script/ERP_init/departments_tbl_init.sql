-------------------------------------------------------------------------------------------------
--                              Creating departments table
CREATE TABLE departments (
    department_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0)
);