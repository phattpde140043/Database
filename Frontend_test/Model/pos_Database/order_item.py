from common import execute_query, pos_dbname, user, password, host, port

class OrderItem:
    def __init__(self, order_item_id, order, product, sku, quantity, unit_price):
        self.order_item_id = order_item_id
        self.order = order          # tham chiếu đến Order object
        self.product = product      # tham chiếu đến Product object
        self.sku = sku              # tham chiếu đến ProductSKU object
        self.quantity = quantity
        self.unit_price = unit_price

    # ======================
    # Business logic
    # ======================

    def get_total_price(self):
        """Tính tổng giá cho item"""
        return self.quantity * self.unit_price

    def increase_quantity(self, amount):
        """Tăng số lượng"""
        self.quantity += amount

    def decrease_quantity(self, amount):
        """Giảm số lượng (không âm)"""
        self.quantity = max(0, self.quantity - amount)

    def __repr__(self):
        return (f"<OrderItem(id={self.order_item_id}, "
                f"product={self.product.name if self.product else None}, "
                f"sku={self.sku.sku_id if self.sku else None}, "
                f"qty={self.quantity}, unit_price={self.unit_price})>")


