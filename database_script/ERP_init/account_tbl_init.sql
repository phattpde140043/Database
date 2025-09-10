----------------------------------------------------------------------------------------------------
--                                   Creating accounts table
CREATE TABLE accounts (
    account_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    account_name VARCHAR(255) NOT NULL CHECK (LENGTH(account_name) > 0),
    account_type VARCHAR(50) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now() CHECK (updated_at <= CURRENT_TIMESTAMP)
);
-- ==========================================
-- Function: Insert new account
-- ==========================================
CREATE OR REPLACE FUNCTION insert_account(
    p_account_name VARCHAR,
    p_account_type VARCHAR
)
RETURNS BIGINT AS $$
DECLARE
    v_account_id BIGINT;
BEGIN
    -- Validate dữ liệu
    IF p_account_name IS NULL OR LENGTH(TRIM(p_account_name)) = 0 THEN
        RAISE EXCEPTION 'Account name cannot be empty';
    END IF;

    IF p_account_type IS NULL OR LENGTH(TRIM(p_account_type)) = 0 THEN
        RAISE EXCEPTION 'Account type cannot be empty';
    END IF;

    -- Insert
    INSERT INTO accounts(account_name, account_type)
    VALUES (p_account_name, p_account_type)
    RETURNING account_id INTO v_account_id;

    RETURN v_account_id;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- Function: Update account info
-- ==========================================
CREATE OR REPLACE FUNCTION update_account(
    p_account_id BIGINT,
    p_account_name VARCHAR DEFAULT NULL,
    p_account_type VARCHAR DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE accounts
    SET 
        account_name = p_account_name,
        account_type = p_account_type
    WHERE account_id = p_account_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Account % not found', p_account_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- Trigger: update column updated_at
-- ==========================================
CREATE OR REPLACE FUNCTION account_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS account_set_timestamp_trigger ON accounts;

CREATE TRIGGER account_set_timestamp_trigger
BEFORE INSERT OR UPDATE ON accounts
FOR EACH ROW
EXECUTE FUNCTION account_set_timestamp();


---------------------- Test --------------------------------

Select * from accounts
-- Insert account mới
SELECT insert_account('Main Account', 'Savings');

-- Update account
SELECT update_account(1,'Cash account', 'asset');
