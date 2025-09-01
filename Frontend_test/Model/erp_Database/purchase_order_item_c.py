
from datetime import datetime
import pandas as pd
from common import execute_query, pos_dbname, user, password, host, port

# ===========================================================
# PurchaseOrderItems
# ===========================================================
class PurchaseOrderItem:
    def __init__(self, po_item_id, po_id, product_id, quantity, unit_price, order_date):
        self.po_item_id = po_item_id
        self.po_id = po_id
        self.product_id = product_id
        self.quantity = quantity
        self.unit_price = unit_price
        self.order_date = order_date if order_date else datetime.now()

    @staticmethod
    def getall():
        query = """
            SELECT po_item_id, po_id, product_id, quantity, unit_price, order_date 
            FROM purchase_order_items;
        """
        rows = execute_query(pos_dbname, user, password, host, port, query)
        return [PurchaseOrderItem(*row) for row in rows] if rows else []

    @staticmethod
    def toPandas():
        items = PurchaseOrderItem.getall()
        data = [vars(i) for i in items]
        return pd.DataFrame(data)

    def __repr__(self):
        return f"<POItem(id={self.po_item_id}, po={self.po_id}, product='{self.product_id}', qty={self.quantity})>"

