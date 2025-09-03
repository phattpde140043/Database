from datetime import datetime
import pandas as pd
from Frontend_test.common import execute_query, erp_dbname, user, password, host, port


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
            SELECT employee_id, name, email, department_id, hire_date, salary
            FROM employees WHERE deleted_at IS NULL;
        """
        rows = execute_query(erp_dbname, user, password, host, port, query)
        return [Employee(*row) for row in rows] if rows else []

    @staticmethod
    def toPandas(employees):
        data = [vars(e) for e in employees]
        return pd.DataFrame(data)
    
    @staticmethod
    def insert_employee(name,email,department_id,salary,hire_date):
        query=f"""Select insert_employee('{name}','{email}',{department_id},{salary},{hire_date});"""
        result = execute_query(erp_dbname, user, password, host, port, query)
        return result if result else None
    @staticmethod
    def update_employee(emp_id,name,email,department_id,salary):
        query=f"""Select update_employee('{emp_id}','{name}','{email}',{department_id},{salary});"""
        result = execute_query(erp_dbname, user, password, host, port, query)
        return result if result else None

    @staticmethod
    def soft_delete_employee(emp_id):
        query=f"""Select soft_delete_employee('{emp_id}');"""
        result = execute_query(erp_dbname, user, password, host, port, query)
        return result if result else None

    def __repr__(self):
        return f"<Employee(id='{self.employee_id}', name='{self.name}', dept={self.department_id})>"

