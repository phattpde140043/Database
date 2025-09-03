from datetime import datetime
import pandas as pd
from Frontend_test.common import execute_query, erp_dbname, user, password, host, port


# ===========================================================
# Departments
# ===========================================================
class Department:
    def __init__(self, department_id, name):
        self.department_id = department_id
        self.name = name

    @staticmethod
    def getall():
        query = "SELECT department_id, name FROM departments;"
        rows = execute_query(erp_dbname, user, password, host, port, query)
        return [Department(*row) for row in rows] if rows else []

    @staticmethod
    def toPandas(departments):
        data = [vars(d) for d in departments]
        return pd.DataFrame(data)
    
    @staticmethod
    def insert_department(department_name):
        query = f"""Select insert_department('{department_name}')"""
        result = execute_query(erp_dbname, user, password, host, port, query)
        return result[0][0] if result else None
    
    @staticmethod
    def update_department(id,department_name):
        query = f"""Select update_department({id},'{department_name}')"""
        result = execute_query(erp_dbname, user, password, host, port, query)
        return result[0][0] if result else None

    def __repr__(self):
        return f"<Department(id={self.department_id}, name='{self.name}')>"

