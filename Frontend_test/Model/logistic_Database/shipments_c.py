from datetime import datetime
from Frontend_test.common import execute_query, pos_dbname, user, password, host, port
import pandas as pd


class Shipment:
    def __init__(self, shipment_id, order_id, warehouse_id,
                 shipment_date=None, status="pending"):
        self.shipment_id = shipment_id
        self.order_id = order_id
        self.warehouse_id = warehouse_id
        self.shipment_date = shipment_date if shipment_date else datetime.now()
        self.status = status

    # =================
    # Business Methods
    # =================
    @staticmethod
    def getall():
        query = """SELECT shipment_id, order_id, warehouse_id,
                          shipment_date, status
                   FROM shipments;"""
        rows = execute_query(pos_dbname, user, password, host, port, query)

        shipments = []
        if rows:
            for row in rows:
                s = Shipment(
                    shipment_id=row[0],
                    order_id=row[1],
                    warehouse_id=row[2],
                    shipment_date=row[3],
                    status=row[4],
                )
                shipments.append(s)
        return shipments

    @staticmethod
    def toPandas():
        shipments = Shipment.getall()
        data = [
            {
                "shipment_id": s.shipment_id,
                "order_id": s.order_id,
                "warehouse_id": s.warehouse_id,
                "shipment_date": s.shipment_date,
                "status": s.status,
            }
            for s in shipments
        ]
        return pd.DataFrame(data)

    @staticmethod
    def add_shipment(order_id, warehouse_id, shipment_date=None, status="pending"):
        shipment_date = shipment_date if shipment_date else datetime.now()
        query = f"""
            INSERT INTO shipments (order_id, warehouse_id, shipment_date, status)
            VALUES ({order_id}, {warehouse_id}, '{shipment_date}', '{status}')
            RETURNING shipment_id, shipment_date;
        """
        result = execute_query(pos_dbname, user, password, host, port, query)
        return result[0] if result else None

    @staticmethod
    def update_status(shipment_id, shipment_date, new_status):
        query = f"""
            UPDATE shipments
            SET status = '{new_status}'
            WHERE shipment_id = {shipment_id}
              AND shipment_date = '{shipment_date}'
            RETURNING shipment_id, status;
        """
        result = execute_query(pos_dbname, user, password, host, port, query)
        return result[0] if result else None

    def __repr__(self):
        return (f"<Shipment(id={self.shipment_id}, order={self.order_id}, "
                f"warehouse={self.warehouse_id}, status={self.status}, "
                f"date={self.shipment_date})>")
