

class OrderItem(Base):
    __tablename__ = "order_items"

    order_item_id = Column(Integer, primary_key=True, autoincrement=True)
    order_id = Column(Integer, ForeignKey("orders.order_id"), nullable=False)
    product_id = Column(String(20), ForeignKey("products.product_id"), nullable=False)
    sku_id = Column(Integer, ForeignKey("products_sku.sku_id"), nullable=False)
    quantity = Column(Integer, nullable=False)
    unit_price = Column(DECIMAL(10, 2), nullable=False)

    order = relationship("Order", back_populates="items")
    sku = relationship("ProductSKU", back_populates="order_items")

