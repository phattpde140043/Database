from datetime import datetime
from Frontend_test.common import execute_query, pos_dbname, user, password, host, port
import pandas as pd

class Customer:
    def __init__(self, customer_id, name, email, phone, address,created_at=datetime.now()):
        self.customer_id = customer_id
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.created_at = created_at

    @staticmethod
    def getall():
        query = "SELECT customer_id, name, email, phone, address, created_at FROM customers"
        rows = execute_query(pos_dbname, user, password, host, port, query)  
        # rows giả sử trả về list of tuple [(id, name, email, phone, address, created_at), ...]

        customers = []
        for row in rows:
            customers.append(
                Customer(
                    customer_id=row[0],
                    name=row[1],
                    email=row[2],
                    phone=row[3],
                    address=row[4],
                    created_at=row[5]
                )
            )
        return customers
    
    @staticmethod
    def getbyID(CustomerID):
        query = f"SELECT customer_id, name, email, phone, address, created_at FROM customers WHERE customer_id = '{CustomerID}'" 
        rows = execute_query(pos_dbname, user, password, host, port, query)  
        # rows giả sử trả về list of tuple [(id, name, email, phone, address, created_at), ...]

        customers = []
        for row in rows:
            customers.append(
                Customer(
                    customer_id=row[0],
                    name=row[1],
                    email=row[2],
                    phone=row[3],
                    address=row[4],
                    created_at=row[5]
                )
            )
        return customers
    
    @staticmethod
    def update_customer(CustomerID, name, email, phone, address):
        query = f"""SELECT update_customer('{CustomerID}','{name}','{email}','{phone}','{address}');"""
        result = execute_query(pos_dbname, user, password, host, port, query)
        return result
    
    @staticmethod
    def toPandas(customers: list):
        data = [
            {
                "customer_id": c.customer_id,
                "name": c.name,
                "email": c.email,
                "phone": c.phone,
                "address": c.address,
                "created_at": c.created_at
            }
            for c in customers
        ]
        return pd.DataFrame(data)
    
    @staticmethod
    def add_customer(name, email, phone, address):
        query = f"""SELECT insert_customer('{name}', '{email}', '{phone}', '{address}');"""
        result = execute_query(pos_dbname, user, password, host, port, query)
        return result[0][0] if result else None
        


