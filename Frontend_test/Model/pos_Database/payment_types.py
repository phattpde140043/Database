from common import execute_query, pos_dbname, user, password, host, port

class PaymentType:
    def __init__(self, payment_type_id, name):
        self.payment_type_id = payment_type_id
        self.name = name

    # Business logic
    def rename(self, new_name):
        """Đổi tên phương thức thanh toán"""
        self.name = new_name

    def __repr__(self):
        return f"<PaymentType(id={self.payment_type_id}, name={self.name})>"
