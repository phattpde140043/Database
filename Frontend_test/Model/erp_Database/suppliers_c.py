from datetime import datetime
import pandas as pd
from common import execute_query, pos_dbname, user, password, host, port

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
            SELECT supplier_id, name, contact_name, phone, email, created_at, deleted_at 
            FROM suppliers;
        """
        rows = execute_query(pos_dbname, user, password, host, port, query)
        return [Supplier(*row) for row in rows] if rows else []

    @staticmethod
    def toPandas():
        suppliers = Supplier.getall()
        data = [vars(s) for s in suppliers]
        return pd.DataFrame(data)

    def __repr__(self):
        return f"<Supplier(id={self.supplier_id}, name='{self.name}')>"

