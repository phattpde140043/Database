from datetime import datetime
from Frontend_test.common import execute_query, logistics_dbname, user, password, host, port
import pandas as pd


class Warehouse:
    def __init__(self, warehouse_id, name, location, created_at=None, deleted_at=None):
        self.warehouse_id = warehouse_id
        self.name = name
        self.location = location
        self.created_at = created_at if created_at else datetime.now()
        self.deleted_at = deleted_at

    # =================
    # Business Methods
    # =================
    @staticmethod
    def getall():
        query = """SELECT warehouse_id, name, location, created_at FROM warehouses WHERE deleted_at IS NULL;"""
        rows = execute_query(logistics_dbname, user, password, host, port, query)

        warehouses = []
        if rows:
            for row in rows:
                wh = Warehouse(
                    warehouse_id=row[0],
                    name=row[1],
                    location=row[2],
                    created_at=row[3],
                    deleted_at=row[4],
                )
                warehouses.append(wh)
        return warehouses

    @staticmethod
    def toPandas(warehouses):
        data = [

            {
                "warehouse_id": wh.warehouse_id,
                "name": wh.name,
                "location": wh.location,
                "created_at": wh.created_at,
                "deleted_at": wh.deleted_at,
            }
            for wh in warehouses
        ]
        return pd.DataFrame(data)

    @staticmethod
    def add_warehouse(name, location):
        query = f"""Select insert_warehouse('{name}', '{location}')"""
        result = execute_query(logistics_dbname, user, password, host, port, query)
        return result[0][0] if result else None
    
    @staticmethod
    def update_warehouse(id,name,location):
        query = f"""Select update_warehouse({id},'{name}','{location}')"""
        result = execute_query(logistics_dbname, user, password, host, port, query)
        return result[0][0] if result else None

    @staticmethod
    def soft_delete_warehouse(id):
        query = f"""Select soft_delete_warehouse({id})"""
        result = execute_query(logistics_dbname, user, password, host, port, query)
        return result[0][0] if result else None
