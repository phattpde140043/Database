from common import execute_query, pos_dbname, user, password, host, port
import pandas as pd

class PaymentType:
    def __init__(self, payment_type_id, name):
        self.payment_type_id = payment_type_id
        self.name = name

    # Business logic
    def rename(self, new_name):
        """Đổi tên phương thức thanh toán"""
        self.name = new_name

    @staticmethod
    def getall():
        query = "Select payment_type_id, name from payment_types"
        rows = execute_query(pos_dbname, user, password, host, port, query)

        # Ép kết quả thành list<PaymentType>
        payment_types = [PaymentType(row[0], row[1]) for row in rows]
        return payment_types
    
    @staticmethod
    def toPandas(payment_types):
        """Chuyển danh sách PaymentType thành pandas.DataFrame"""
        data = [{
            "payment_type_id": pt.payment_type_id,
            "name": pt.name
        } for pt in payment_types]
        return pd.DataFrame(data)

    @staticmethod
    def insert_payment(payment_name):
        query = f"Select insert_payment_type('{payment_name}')"
        return execute_query(pos_dbname, user, password, host, port, query)

    @staticmethod
    def update_payment(payment_id,payment_name):
        query = f"Select update_payment_type({payment_id},'{payment_name}')"
        return execute_query(pos_dbname, user, password, host, port, query)



    def __repr__(self):
        return f"<PaymentType(id={self.payment_type_id}, name={self.name})>"
