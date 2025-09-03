from datetime import datetime
import pandas as pd
from Frontend_test.common import execute_query, erp_dbname, user, password, host, port

# ===========================================================
# Suppliers
# ===========================================================
class Supplier:
    def __init__(self, supplier_id, name, contact_name, phone, email, created_at=None, deleted_at=None):
        self.supplier_id = supplier_id
        self.name = name
        self.contact_name = contact_name
        self.phone = phone
        self.email = email
        self.created_at = created_at if created_at else datetime.now()
        self.deleted_at = deleted_at

    @staticmethod
    def getall():
        query = """
            SELECT supplier_id, name, contact_name, phone, email, created_at
            FROM suppliers WHERE deleted_at IS NULL;
        """
        rows = execute_query(erp_dbname, user, password, host, port, query)
        return [Supplier(*row) for row in rows] if rows else []

    @staticmethod
    def toPandas(suppliers):
        data = [vars(s) for s in suppliers]
        return pd.DataFrame(data)
    
    @staticmethod
    def insert_supplier(name,contact_name,phone,email):
        query=f"""Select insert_supplier('{name}','{contact_name}','{phone}','{email}');"""
        result = execute_query(erp_dbname, user, password, host, port, query)
        return result if result else None
    @staticmethod
    def update_supplier(supplier_id,name,contact_name,phone,email):
        query=f"""Select update_supplier({supplier_id},'{name}','{contact_name}','{phone}','{email}');"""
        result = execute_query(erp_dbname, user, password, host, port, query)
        return result if result else None

    @staticmethod
    def soft_delete_supplier(supplier_id):
        query=f"""Select soft_delete_supplier({supplier_id});"""
        result = execute_query(erp_dbname, user, password, host, port, query)
        return result if result else None

    def __repr__(self):
        return f"<Supplier(id={self.supplier_id}, name='{self.name}')>"

