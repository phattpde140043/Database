from datetime import datetime
from common import execute_query, pos_dbname, user, password, host, port
import pandas as pd


class ProductSKU:
    def __init__(self, sku_id, sku, product_id, color, size, price, 
                 created_at=None, deleted_at=None):
        self.sku_id = sku_id
        self.sku = sku
        self.product_id = product_id
        self.color = color
        self.size = size
        self.price = price
        self.created_at = created_at if created_at else datetime.now()
        self.deleted_at = deleted_at

        # Quan hệ (association)
        self.product = None
        self.order_items = []

    @staticmethod
    def getall():
        query = """
            SELECT sku_id, sku, product_id, color, size, price, created_at
            FROM products_sku WHERE deleted_at IS NULL
        """
        rows = execute_query(pos_dbname, user, password, host, port, query)

        # Ép kết quả thành list[ProductSKU]
        skus = [
            ProductSKU(
                row[0], row[1], row[2], row[3],
                row[4], row[5], row[6]
            )
            for row in rows
        ]
        return skus
    
    @staticmethod
    def getSkuByProductId(ProductId):
        query = f"""
            SELECT sku_id, sku, product_id, color, size, price, created_at
            FROM products_sku WHERE deleted_at IS NULL AND product_id = '{ProductId}'
        """
        rows = execute_query(pos_dbname, user, password, host, port, query)

        # Ép kết quả thành list[ProductSKU]
        skus = [
            ProductSKU(
                row[0], row[1], row[2], row[3],
                row[4], row[5], row[6]
            )
            for row in rows
        ]
        return skus

    @staticmethod
    def toPandas(sku_list):
        """Chuyển list[ProductSKU] thành pandas.DataFrame"""
        data = [{
            "sku_id": sku.sku_id,
            "sku": sku.sku,
            "product_id": sku.product_id,
            "color": sku.color,
            "size": sku.size,
            "price": sku.price,
            "created_at": sku.created_at
        } for sku in sku_list]

        return pd.DataFrame(data)

    @staticmethod
    def insert_SKU(p_sku,p_product_id,p_price,p_color,p_size):
        query= f"Select insert_sku('{p_sku}','{p_product_id}',{p_price},'{p_color}','{p_size}')"
        return execute_query(pos_dbname, user, password, host, port, query)

    @staticmethod
    def update_SKU(p_sku_id,p_sku,p_price,p_color,p_size):
        query= f"Select update_sku({p_sku_id},'{p_sku}','{p_color}','{p_size}',{p_price})"
        return execute_query(pos_dbname, user, password, host, port, query)

    @staticmethod
    def soft_deleted(p_sku_id):
        query= f"Select soft_delete_sku({p_sku_id})"
        return execute_query(pos_dbname, user, password, host, port, query)

    @staticmethod
    def searchByRange(p_min, p_max):
        query= f"Select search_skus_by_price({p_min},{p_max})"
        return execute_query(pos_dbname, user, password, host, port, query)


    def __repr__(self):
        return (f"<ProductSKU(id={self.sku_id}, sku={self.sku}, "
                f"product_id={self.product_id}, price={self.price}, "
                f"color={self.color}, size={self.size})>")
