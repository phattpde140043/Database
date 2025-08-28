

class Order(Base):
    __tablename__ = "orders"

    order_id = Column(Integer, primary_key=True, autoincrement=True)
    customer_id = Column(String(20), ForeignKey("customers.customer_id"), nullable=False)
    order_date = Column(TIMESTAMP, default=func.now())
    total_amount = Column(DECIMAL(12, 2), default=0.0)
    shipping_address = Column(String(500))
    payment_type_id = Column(Integer, ForeignKey("payment_types.payment_type_id"), nullable=False)
    payment_status = Column(String(20), default="pending")

    customer = relationship("Customer", back_populates="orders")
    items = relationship("OrderItem", back_populates="order")
    payment_type = relationship("PaymentType")

    # Business function: tính lại total_amount
    def recalc_total(self, session):
        self.total_amount = sum(
            item.quantity * item.unit_price for item in self.items
        )
        session.commit()
