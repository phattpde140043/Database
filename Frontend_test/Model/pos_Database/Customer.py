from datetime import datetime
from common import execute_query, pos_dbname, user, password, host, port

class Customer:
    def __init__(self, customer_id, name, email, phone, address):
        self.customer_id = customer_id
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.created_at = datetime.now()
        


