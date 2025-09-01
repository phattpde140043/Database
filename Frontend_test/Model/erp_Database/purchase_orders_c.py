from datetime import datetime
import pandas as pd
from common import execute_query, pos_dbname, user, password, host, port

# ===========================================================
# PurchaseOrders
# ===========================================================
class PurchaseOrder:
    def __init__(self, po_id, supplier_id, order_date, status, total_amount):
        self.po_id = po_id
        self.supplier_id = supplier_id
        self.order_date = order_date if order_date else datetime.now()
        self.status = status
        self.total_amount = total_amount

    @staticmethod
    def getall():
        query = """
            SELECT po_id, supplier_id, order_date, status, total_amount 
            FROM purchase_orders;
        """
        rows = execute_query(pos_dbname, user, password, host, port, query)
        return [PurchaseOrder(*row) for row in rows] if rows else []

    @staticmethod
    def toPandas():
        pos = PurchaseOrder.getall()
        data = [vars(p) for p in pos]
        return pd.DataFrame(data)

    def __repr__(self):
        return f"<PurchaseOrder(id={self.po_id}, supplier={self.supplier_id}, total={self.total_amount})>"

