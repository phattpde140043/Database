from datetime import datetime
from common import execute_query, pos_dbname, user, password, host, port
import pandas as pd

class Product:
    def __init__(self, product_id, name, category, created_at=None, deleted_at=None):
        self.product_id = product_id
        self.name = name
        self.category = category       # tham chiếu đến Category object
        self.created_at = created_at if created_at else datetime.now()
        self.deleted_at = deleted_at

        # Quan hệ 1-nhiều
        self.skus = []

    @staticmethod
    def getall():
        query = "SELECT p.product_id, p.name AS product_name,c.category_id, c.name AS category_name FROM products p JOIN categories c ON p.category_id = c.category_id;"
        rows = execute_query(pos_dbname, user, password, host, port, query)

        products = []
        for row in rows:
            # nếu execute_query trả về tuple (product_id, product_name, category_id, category_name)
            product_id, product_name, category_id, category_name = row

            # category có thể để dạng dict hoặc object riêng
            category = {
                "category_id": category_id,
                "name": category_name
            }

            products.append(Product(product_id, product_name, category))

        return products    


    @staticmethod
    def get_product_by_categories_id(category_id):
        query = f"SELECT p.product_id, p.name AS product_name, c.name AS category_name FROM products p JOIN categories c ON p.category_id = c.category_id WHERE c.category_id = {category_id};"
        return execute_query(pos_dbname, user, password, host, port, query)

    @staticmethod
    def get_product_by_id(product_id):
        query = f"SELECT p.product_id, p.name AS product_name, c.name AS category_name FROM products p JOIN categories c ON p.category_id = c.category_id WHERE p.product_id = '{product_id}';"
        return execute_query(pos_dbname, user, password, host, port, query)
    
    @staticmethod
    def get_product_by_name(product_name):
        query = f"SELECT p.product_id, p.name AS product_name, c.name AS category_name FROM products p JOIN categories c ON p.category_id = c.category_id WHERE p.name ILIKE '%{product_name}%';"
        return execute_query(pos_dbname, user, password, host, port, query)
    
    @staticmethod
    def soft_delete(product_id):
        query= f"select soft_delete_product('{product_id}')"
        return execute_query(pos_dbname, user, password, host, port, query)

    @staticmethod
    def add_product(name,category_id,SKU,price,color,size):
        query = f"select insert_product('{name}',{category_id},'{SKU}',{price},'{color}','{size}')"
        return execute_query(pos_dbname, user, password, host, port, query)

    @staticmethod
    def update_product(product_id,name,category_id):
        query = f"select update_product('{product_id}','{name}',{category_id})"
        return execute_query(pos_dbname, user, password, host, port, query)
    
    @staticmethod
    def to_pandas(products: list):
        """
        Convert list[Product] -> pandas.DataFrame
        """
        data = []
        for p in products:
            data.append({
                "product_id": p.product_id,
                "name": p.name,
                "category": p.category.name if hasattr(p.category, "name") else p.category,
                "created_at": p.created_at,
                "deleted_at": p.deleted_at,
                "sku_count": len(p.skus)  # ví dụ thêm thông tin số SKU
            })
        return pd.DataFrame(data)

    def __repr__(self):
        return f"<Product(id={self.product_id}, name={self.name}, category={self.category.name})>"
