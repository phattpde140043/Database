
class PaymentType(Base):
    __tablename__ = "payment_types"

    payment_type_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False)