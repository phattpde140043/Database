----------------------------------------------------------------------------------------------------
--                                   Creating accounts table
CREATE TABLE accounts (
    account_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    account_name VARCHAR(255) NOT NULL CHECK (LENGTH(account_name) > 0),
    account_type VARCHAR(50) NOT NULL
);