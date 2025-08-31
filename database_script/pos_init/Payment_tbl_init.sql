--------------------------------------------------------------------------------
--                              Creating payment_types table
CREATE TABLE payment_types (
    payment_type_id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 0)
);