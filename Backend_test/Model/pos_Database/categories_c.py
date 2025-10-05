from datetime import datetime
from common import execute_query, pos_dbname, user, password, host, port
import pandas as pd


class Category:
    def __init__(self, category_id, name, created_at=None, deleted_at=None):
        self.category_id = category_id
        self.name = name
        self.created_at = created_at if created_at else datetime.now()
        self.deleted_at = deleted_at
        self.products = []  # giữ danh sách sản phẩm (Product objects)

    # =================
    # Business Methods
    # =================

    @staticmethod
    def getall():
        query = "SELECT category_id, name, created_at, deleted_at IS NULL AS is_active FROM categories;"
        rows = execute_query(pos_dbname, user, password, host, port, query)

        categories = []
        if rows:
            for row in rows:
                cat = Category(
                    category_id=row[0],
                    name=row[1],
                    created_at=row[2],
                    deleted_at=row[3]
                )
                categories.append(cat)
        return categories

    @staticmethod
    def toPandas(list_category):
        """Trả về pandas DataFrame từ bảng categories"""
        categories = Category.getall()
        data = [
            {
                "category_id": c.category_id,
                "name": c.name,
                "created_at": c.created_at,
                "deleted_at": c.deleted_at
            }
            for c in categories
        ]
        return pd.DataFrame(data)

    @staticmethod
    def add_category(category_name):
        query = f"""select insert_category('{category_name}');"""
        result = execute_query(pos_dbname, user, password, host, port, query)
        return result if result else None
    
    @staticmethod
    def update_category(category_id, category_name):
        query = f"""select update_category({category_id},'{category_name}');"""
        result = execute_query(pos_dbname, user, password, host, port, query)
        return result if result else None
    

    @staticmethod
    def soft_delete(category_id):
       query = f"""select soft_delete_category({category_id});"""
       result = execute_query(pos_dbname, user, password, host, port, query)
       return result if result else None

    def __repr__(self):
        return f"<Category(id={self.category_id}, name='{self.name}', products={len(self.products)})>"