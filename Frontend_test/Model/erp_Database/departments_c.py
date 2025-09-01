from datetime import datetime
import pandas as pd
from common import execute_query, pos_dbname, user, password, host, port


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
        rows = execute_query(pos_dbname, user, password, host, port, query)
        return [Department(*row) for row in rows] if rows else []

    @staticmethod
    def toPandas():
        departments = Department.getall()
        data = [vars(d) for d in departments]
        return pd.DataFrame(data)

    def __repr__(self):
        return f"<Department(id={self.department_id}, name='{self.name}')>"

