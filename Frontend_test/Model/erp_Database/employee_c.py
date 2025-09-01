from datetime import datetime
import pandas as pd
from common import execute_query, pos_dbname, user, password, host, port


# ===========================================================
# Employees
# ===========================================================
class Employee:
    def __init__(self, employee_id, name, email, department_id, hire_date, salary, deleted_at=None):
        self.employee_id = employee_id
        self.name = name
        self.email = email
        self.department_id = department_id
        self.hire_date = hire_date if hire_date else datetime.now()
        self.salary = salary
        self.deleted_at = deleted_at

    @staticmethod
    def getall():
        query = """
            SELECT employee_id, name, email, department_id, hire_date, salary, deleted_at 
            FROM employees;
        """
        rows = execute_query(pos_dbname, user, password, host, port, query)
        return [Employee(*row) for row in rows] if rows else []

    @staticmethod
    def toPandas():
        employees = Employee.getall()
        data = [vars(e) for e in employees]
        return pd.DataFrame(data)

    def __repr__(self):
        return f"<Employee(id='{self.employee_id}', name='{self.name}', dept={self.department_id})>"

