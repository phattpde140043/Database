from datetime import datetime
from Frontend_test.common import execute_query, pos_dbname, user, password, host, port
import pandas as pd


class Inventory:
    def __init__(self, inventory_id, warehouse_id, product_id, sku_id,
                 stock_quantity, last_updated=None):
        if stock_quantity < 0:
            raise ValueError("stock_quantity must be >= 0")

        self.inventory_id = inventory_id
        self.warehouse_id = warehouse_id
        self.product_id = product_id
        self.sku_id = sku_id
        self.stock_quantity = stock_quantity
        self.last_updated = last_updated if last_updated else datetime.now()

    # =================
    # Business Methods
    # =================
    @staticmethod
    def getall():
        query = """SELECT inventory_id, warehouse_id, product_id, sku_id,
                          stock_quantity, last_updated
                   FROM inventory;"""
        rows = execute_query(pos_dbname, user, password, host, port, query)

        inventories = []
        if rows:
            for row in rows:
                inv = Inventory(
                    inventory_id=row[0],
                    warehouse_id=row[1],
                    product_id=row[2],
                    sku_id=row[3],
                    stock_quantity=row[4],
                    last_updated=row[5],
                )
                inventories.append(inv)
        return inventories

    @staticmethod
    def toPandas():
        inventories = Inventory.getall()
        data = [
            {
                "inventory_id": inv.inventory_id,
                "warehouse_id": inv.warehouse_id,
                "product_id": inv.product_id,
                "sku_id": inv.sku_id,
                "stock_quantity": inv.stock_quantity,
                "last_updated": inv.last_updated,
            }
            for inv in inventories
        ]
        return pd.DataFrame(data)

    @staticmethod
    def add_inventory(warehouse_id, product_id, sku_id, stock_quantity):
        query = f"""
            INSERT INTO inventory (warehouse_id, product_id, sku_id, stock_quantity)
            VALUES ({warehouse_id}, '{product_id}', {sku_id}, {stock_quantity})
            RETURNING inventory_id;
        """
        result = execute_query(pos_dbname, user, password, host, port, query)
        return result[0][0] if result else None

    @staticmethod
    def update_stock(inventory_id, quantity_change):
        query = f"""
            UPDATE inventory
            SET stock_quantity = stock_quantity + {quantity_change},
                last_updated = now()
            WHERE inventory_id = {inventory_id}
            RETURNING inventory_id, stock_quantity;
        """
        result = execute_query(pos_dbname, user, password, host, port, query)
        return result[0] if result else None

    def __repr__(self):
        return (f"<Inventory(id={self.inventory_id}, warehouse={self.warehouse_id}, "
                f"product={self.product_id}, sku={self.sku_id}, stock={self.stock_quantity})>")
