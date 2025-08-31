from datetime import datetime
from common import execute_query, pos_dbname, user, password, host, port

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
        query = "SELECT p.product_id, p.name AS product_name, c.name AS category_name, p.price FROM products p JOIN categories c ON p.category_id = c.category_id;"
        return execute_query(pos_dbname, user, password, host, port, query)

    @staticmethod
    def get_product_by_categories_id(category_id):
        query = f"SELECT p.product_id, p.name AS product_name, c.name AS category_name, p.price FROM products p JOIN categories c ON p.category_id = c.category_id WHERE c.category_id = {category_id};"
        return execute_query(pos_dbname, user, password, host, port, query)

    @staticmethod
    def get_product_by_id(product_id):
        query = f"SELECT p.product_id, p.name AS product_name, c.name AS category_name, p.price FROM products p JOIN categories c ON p.category_id = c.category_id WHERE p.product_id = '{product_id}';"
        return execute_query(pos_dbname, user, password, host, port, query)
    
    @staticmethod
    def get_product_by_name(product_name):
        query = f"SELECT p.product_id, p.name AS product_name, c.name AS category_name, p.price FROM products p JOIN categories c ON p.category_id = c.category_id WHERE p.name ILIKE '%{product_name}%';"
        return execute_query(pos_dbname, user, password, host, port, query)
    
    def soft_delete(product_id):
        query= f"select soft_delete_product('{product_id}')"
        return execute_query(pos_dbname, user, password, host, port, query)

    def add_product(product_id,name,category_id):
        query = f"select update_produt('{product_id}','{name}',{category_id})"
        return execute_query(pos_dbname, user, password, host, port, query)

    @staticmethod
    def update_product(product_id,name,category_id,sku,price,color,size):
        query = f"select update_product('{product_id}','{name}',{category_id},'{sku}',{price},'{color}','{size}')"
        return execute_query(pos_dbname, user, password, host, port, query)

    def __repr__(self):
        return f"<Product(id={self.product_id}, name={self.name}, category={self.category.name})>"
