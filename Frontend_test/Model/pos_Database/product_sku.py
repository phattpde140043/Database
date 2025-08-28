

class ProductSKU(Base):
    __tablename__ = "products_sku"

    sku_id = Column(Integer, primary_key=True, autoincrement=True)
    sku = Column(String(50), unique=True, nullable=False)
    product_id = Column(String(20), ForeignKey("products.product_id"), nullable=False)
    color = Column(String(50))
    size = Column(String(50))
    price = Column(DECIMAL(10, 2), nullable=False)
    created_at = Column(TIMESTAMP, default=func.now())
    deleted_at = Column(TIMESTAMP)

    product = relationship("Product", back_populates="skus")
    order_items = relationship("OrderItem", back_populates="sku")

    # CRUD
    @staticmethod
    def create(session, **kwargs):
        obj = ProductSKU(**kwargs)
        session.add(obj)
        session.commit()
        return obj
    
    @staticmethod
    def get_by_id(session, sku_id):
        return session.query(ProductSKU).get(sku_id) 
    
    @staticmethod
    def update(session, sku_id, **kwargs):
        obj = session.query(ProductSKU).get(sku_id)
        for key, value in kwargs.items():
            setattr(obj, key, value)
        session.commit()
        return obj
    
    @staticmethod
    def delete(session, sku_id):
        obj = session.query(ProductSKU).get(sku_id)
        session.delete(obj)
        session.commit();

    # Business function
    def get_total_sold(self, session):
        return session.query(OrderItem).filter_by(sku_id=self.sku_id).count()
    
    def get_total_revenue(self, session):
        total = session.query(func.sum(OrderItem.quantity * OrderItem.price)).filter_by(sku_id=self.sku_id).scalar()
        return total if total else 0
    
    @staticmethod
    def get_skus_by_product(session, product_id):   
        return session.query(ProductSKU).filter_by(product_id=product_id).all()
    
    @staticmethod
    def get_skus_below_price(session, price):
        return session.query(ProductSKU).filter(ProductSKU.price < price).all()
    
    @staticmethod
    def get_skus_in_price_range(session, min_price, max_price):
        return session.query(ProductSKU).filter(ProductSKU.price.between(min_price, max_price)).all()
    