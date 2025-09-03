from datetime import datetime
from Frontend_test.common import execute_query, pos_dbname, user, password, host, port
import pandas as pd


class DeliveryTracking:
    def __init__(self, tracking_id, shipment_id, shipment_date,
                 checkpoint_time, location, status="in_transit"):
        self.tracking_id = tracking_id
        self.shipment_id = shipment_id
        self.shipment_date = shipment_date
        self.checkpoint_time = checkpoint_time if checkpoint_time else datetime.now()
        self.location = location
        self.status = status

    # =================
    # Business Methods
    # =================
    @staticmethod
    def getall():
        query = """SELECT tracking_id, shipment_id, shipment_date,
                          checkpoint_time, location, status
                   FROM delivery_tracking;"""
        rows = execute_query(pos_dbname, user, password, host, port, query)

        deliveries = []
        if rows:
            for row in rows:
                d = DeliveryTracking(
                    tracking_id=row[0],
                    shipment_id=row[1],
                    shipment_date=row[2],
                    checkpoint_time=row[3],
                    location=row[4],
                    status=row[5],
                )
                deliveries.append(d)
        return deliveries

    @staticmethod
    def toPandas():
        deliveries = DeliveryTracking.getall()
        data = [
            {
                "tracking_id": d.tracking_id,
                "shipment_id": d.shipment_id,
                "shipment_date": d.shipment_date,
                "checkpoint_time": d.checkpoint_time,
                "location": d.location,
                "status": d.status,
            }
            for d in deliveries
        ]
        return pd.DataFrame(data)

    @staticmethod
    def add_delivery(shipment_id, shipment_date, checkpoint_time, location, status="in_transit"):
        query = f"""
            INSERT INTO delivery_tracking (shipment_id, shipment_date, checkpoint_time, location, status)
            VALUES ({shipment_id}, '{shipment_date}', '{checkpoint_time}', '{location}', '{status}')
            RETURNING tracking_id;
        """
        result = execute_query(pos_dbname, user, password, host, port, query)
        return result[0][0] if result else None

    @staticmethod
    def update_status(tracking_id, checkpoint_time, new_status):
        query = f"""
            UPDATE delivery_tracking
            SET status = '{new_status}'
            WHERE tracking_id = {tracking_id}
              AND checkpoint_time = '{checkpoint_time}'
            RETURNING tracking_id;
        """
        result = execute_query(pos_dbname, user, password, host, port, query)
        return result[0][0] if result else None

    def __repr__(self):
        return (f"<DeliveryTracking(id={self.tracking_id}, shipment={self.shipment_id}, "
                f"status={self.status}, checkpoint_time={self.checkpoint_time})>")
