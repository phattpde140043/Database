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


    def getall():
        query = "Select * from products"
        return execute_query(pos_dbname, user, password, host, port, query)


    # Business logic
    def add_sku(self, sku):
        """Thêm một SKU vào sản phẩm."""
        self.skus.append(sku)
        sku.product = self  # gắn ngược quan hệ

    def mark_deleted(self):
        """Đánh dấu sản phẩm bị xóa (soft delete)."""
        self.deleted_at = datetime.now()

    def get_active_skus(self):
        """Lấy danh sách SKU chưa bị xóa."""
        return [sku for sku in self.skus if sku.deleted_at is None]

    def __repr__(self):
        return f"<Product(id={self.product_id}, name={self.name}, category={self.category.name})>"
