from datetime import datetime
from decimal import Decimal
from common import execute_query, pos_dbname, user, password, host, port

class Order:
    def __init__(self, order_id, customer, payment_type,
                 shipping_address=None, payment_status="pending"):
        self.order_id = order_id
        self.customer = customer            # Customer object
        self.payment_type = payment_type    # PaymentType object
        self.order_date = datetime.now()
        self.total_amount = Decimal("0.00")
        self.shipping_address = shipping_address
        self.payment_status = payment_status
        self.items = []  # list of OrderItem

    # ========================
    # Business logic
    # ========================

    def getall():
        query = "Select * from orders"
        return execute_query(pos_dbname, user, password, host, port, query)


    def add_item(self, order_item):
        """Thêm OrderItem vào đơn hàng"""
        self.items.append(order_item)
        self.recalc_total()

    def remove_item(self, order_item_id):
        """Xóa OrderItem theo id"""
        self.items = [item for item in self.items if item.order_item_id != order_item_id]
        self.recalc_total()

    def recalc_total(self):
        """Tính lại tổng tiền"""
        self.total_amount = sum(item.get_total_price() for item in self.items)

    def set_payment_status(self, status):
        """Cập nhật trạng thái thanh toán"""
        self.payment_status = status

    def __repr__(self):
        return (f"<Order(id={self.order_id}, customer={self.customer.name if self.customer else None}, "
                f"total={self.total_amount}, status={self.payment_status}, items={len(self.items)})>")
