from datetime import datetime
import pandas as pd
from Frontend_test.common import execute_query, erp_dbname, user, password, host, port

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
        rows = execute_query(erp_dbname, user, password, host, port, query)
        return [Account(*row) for row in rows] if rows else []

    @staticmethod
    def toPandas(accounts):
        data = [vars(a) for a in accounts]
        return pd.DataFrame(data)
    
    @staticmethod
    def insert_account(account_name, type):
        query = f"""Select insert_account('{account_name}','{type}')"""
        result = execute_query(erp_dbname, user, password, host, port, query)
        return result[0][0] if result else None
    
    @staticmethod
    def update_account(id,account_name, type):
        query = f"""Select update_account({id},'{account_name}','{type}')"""
        result = execute_query(erp_dbname, user, password, host, port, query)
        return result[0][0] if result else None

    def __repr__(self):
        return f"<Account(id={self.account_id}, name='{self.account_name}', type='{self.account_type}')>"

