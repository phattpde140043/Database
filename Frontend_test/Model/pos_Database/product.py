

class Product(Base):
    __tablename__ = "products"

    product_id = Column(String(20), primary_key=True)  # Trigger sinh PROD_xxx
    name = Column(String(255), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.category_id"), nullable=False)
    created_at = Column(TIMESTAMP, default=func.now())
    deleted_at = Column(TIMESTAMP)

    category = relationship("Category", back_populates="products")
    skus = relationship("ProductSKU", back_populates="product")