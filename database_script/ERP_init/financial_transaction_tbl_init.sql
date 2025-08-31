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