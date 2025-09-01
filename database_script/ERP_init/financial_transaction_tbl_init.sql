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

-------------------------------------------------------------------------
CREATE INDEX financial_transactions_transaction_date_idx ON financial_transactions (transaction_date);

-- ==========================================
-- Function: Insert new financial_transaction
-- ==========================================
CREATE OR REPLACE FUNCTION insert_financial_transaction(
    p_transaction_date TIMESTAMPTZ,
    p_account_id BIGINT,
    p_amount DECIMAL(12,2),
    p_type VARCHAR,
    p_status VARCHAR
)
RETURNS BIGINT AS $$
DECLARE
    v_transaction_id BIGINT;
BEGIN
    -- Validate input
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be > 0';
    END IF;

    IF p_type NOT IN ('debit','credit') THEN
        RAISE EXCEPTION 'Invalid transaction type: %', p_type;
    END IF;

    IF p_status NOT IN ('draft','approved','received','cancelled') THEN
        RAISE EXCEPTION 'Invalid transaction status: %', p_status;
    END IF;

    -- Insert into correct partition
    INSERT INTO financial_transactions(transaction_date, account_id, amount, type, status)
    VALUES (p_transaction_date, p_account_id, p_amount, p_type, p_status)
    RETURNING transaction_id INTO v_transaction_id;

    RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- Function: Update financial_transaction
-- ==========================================
CREATE OR REPLACE FUNCTION update_financial_transaction(
    p_transaction_id BIGINT,
    p_transaction_date TIMESTAMPTZ,
    p_amount DECIMAL(12,2) DEFAULT NULL,
    p_type VARCHAR DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE financial_transactions
    SET amount = COALESCE(p_amount, amount),
        type   = COALESCE(p_type, type),
        status = COALESCE(p_status, status)
    WHERE transaction_id = p_transaction_id
      AND transaction_date = p_transaction_date; -- xác định đúng partition

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaction % at % not found', p_transaction_id, p_transaction_date;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Insert transaction
SELECT insert_financial_transaction(
    p_transaction_date := '2025-08-20'::timestamptz,
    p_account_id := 1,
    p_amount := 1500.00,
    p_type := 'debit',
    p_status := 'approved'
);

-- Update transaction
SELECT update_financial_transaction(
    p_transaction_id := 1,
    p_transaction_date := '2025-08-20'::timestamptz,
    p_amount := 2000.00,
    p_status := 'received'
);
