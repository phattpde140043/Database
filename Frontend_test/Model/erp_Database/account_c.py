from datetime import datetime
import pandas as pd
from common import execute_query, pos_dbname, user, password, host, port

# ===========================================================
# Accounts
# ===========================================================
class Account:
    def __init__(self, account_id, account_name, account_type):
        self.account_id = account_id
        self.account_name = account_name
        self.account_type = account_type

    @staticmethod
    def getall():
        query = "SELECT account_id, account_name, account_type FROM accounts;"
        rows = execute_query(pos_dbname, user, password, host, port, query)
        return [Account(*row) for row in rows] if rows else []

    @staticmethod
    def toPandas():
        accounts = Account.getall()
        data = [vars(a) for a in accounts]
        return pd.DataFrame(data)

    def __repr__(self):
        return f"<Account(id={self.account_id}, name='{self.account_name}', type='{self.account_type}')>"

