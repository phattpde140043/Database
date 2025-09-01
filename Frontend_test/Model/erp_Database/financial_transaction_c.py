from datetime import datetime
import pandas as pd
from common import execute_query, pos_dbname, user, password, host, port


# ===========================================================
# FinancialTransactions
# ===========================================================
class FinancialTransaction:
    def __init__(self, transaction_id, transaction_date, account_id, amount, type, status):
        self.transaction_id = transaction_id
        self.transaction_date = transaction_date if transaction_date else datetime.now()
        self.account_id = account_id
        self.amount = amount
        self.type = type
        self.status = status

    @staticmethod
    def getall():
        query = """
            SELECT transaction_id, transaction_date, account_id, amount, type, status 
            FROM financial_transactions;
        """
        rows = execute_query(pos_dbname, user, password, host, port, query)
        return [FinancialTransaction(*row) for row in rows] if rows else []

    @staticmethod
    def toPandas():
        txs = FinancialTransaction.getall()
        data = [vars(t) for t in txs]
        return pd.DataFrame(data)

    def __repr__(self):
        return f"<Transaction(id={self.transaction_id}, account={self.account_id}, amount={self.amount}, status='{self.status}')>"
