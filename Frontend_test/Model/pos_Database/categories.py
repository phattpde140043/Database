from sqlalchemy import (
    create_engine, Column, Integer, String, ForeignKey, DECIMAL, TIMESTAMP, func
)
from sqlalchemy.orm import declarative_base, sessionmaker, relationship
from datetime import datetime

class Category(Base):
    __tablename__ = "categories"

    category_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    created_at = Column(TIMESTAMP, default=func.now())
    deleted_at = Column(TIMESTAMP)

    products = relationship("Product", back_populates="category")
