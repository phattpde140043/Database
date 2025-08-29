from datetime import datetime
from common import execute_query, pos_dbname, user, password, host, port

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

    def getall():
        query = "Select * from products_sku"
        return execute_query(pos_dbname, user, password, host, port, query)


    # Business logic
    def mark_deleted(self):
        """Đánh dấu SKU đã bị xóa (soft delete)."""
        self.deleted_at = datetime.now()

    def get_total_sold(self):
        """Tính tổng số lượng đã bán từ order_items."""
        return sum(item.quantity for item in self.order_items)

    def get_total_revenue(self):
        """Tính tổng doanh thu từ order_items."""
        return sum(item.quantity * item.unit_price for item in self.order_items)

    def __repr__(self):
        return (f"<ProductSKU(id={self.sku_id}, sku={self.sku}, "
                f"product_id={self.product_id}, price={self.price}, "
                f"color={self.color}, size={self.size})>")
