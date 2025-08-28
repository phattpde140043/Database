from datetime import datetime
from common import execute_query, pos_dbname, user, password, host, port

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

    def getall():
        query = "Select * from categories"
        return execute_query(pos_dbname, user, password, host, port, query)

    def add_product(self, product):
        """Thêm 1 product vào category"""
        self.products.append(product)

    def remove_product(self, product_id):
        """Xóa product theo id"""
        self.products = [p for p in self.products if p.product_id != product_id]

    def soft_delete(self):
        """Đánh dấu category là đã xóa"""
        self.deleted_at = datetime.now()

    def __repr__(self):
        return f"<Category(id={self.category_id}, name='{self.name}', products={len(self.products)})>"
