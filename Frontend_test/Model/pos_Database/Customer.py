from sqlalchemy import (
    create_engine, Column, Integer, String, ForeignKey, DECIMAL, TIMESTAMP, func
)
from sqlalchemy.orm import declarative_base, sessionmaker, relationship
from datetime import datetime

class Customer(Base):
    __tablename__ = "customers"

    customer_id = Column(String(20), primary_key=True)  # Trigger sinh CUST_xxx
    name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    phone = Column(String(20), unique=True, nullable=False)
    address = Column(String(500), nullable=False)
    created_at = Column(TIMESTAMP, default=func.now())
    updated_at = Column(TIMESTAMP, default=func.now(), onupdate=func.now())

    orders = relationship("Order", back_populates="customer")

    # CRUD
    @staticmethod
    def create(session, **kwargs):
        obj = Customer(**kwargs)
        session.add(obj)
        session.commit()
        return obj

    @staticmethod
    def get_by_id(session, customer_id):
        return session.query(Customer).get(customer_id)

    @staticmethod
    def update(session, customer_id, **kwargs):
        obj = session.query(Customer).get(customer_id)
        for key, value in kwargs.items():
            setattr(obj, key, value)
        session.commit()
        return obj

    @staticmethod
    def delete(session, customer_id):
        obj = session.query(Customer).get(customer_id)
        session.delete(obj)
        session.commit()

    # Business function
    def get_total_orders(self, session):
        return session.query(Order).filter_by(customer_id=self.customer_id).count()
