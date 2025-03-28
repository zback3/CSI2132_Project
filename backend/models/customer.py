from database import db
from datetime import datetime

class Customer(db.Model):
    __tablename__ = 'Customer'
    __table_args__ = {'schema': 'Hotel'}

    customer_id = db.Column(db.Integer, primary_key=True)
    first_name = db.Column(db.String, nullable=False)
    last_name = db.Column(db.String, nullable=False)
    address = db.Column(db.String, nullable=False)
    id_type = db.Column(db.String, nullable=False)
    id_number = db.Column(db.String, nullable=False)
    registration_date = db.Column(db.Date, nullable=False, default=datetime.utcnow)

    def __init__(self, customer_id, first_name, last_name, address, id_type, id_number):
        self.customer_id = customer_id
        self.first_name = first_name
        self.last_name = last_name
        self.address = address
        self.id_type = id_type
        self.id_number = id_number

    def to_dict(self):
        return {
            'customer_id': self.customer_id,
            'first_name': self.first_name,
            'last_name': self.last_name,
            'address': self.address,
            'id_type': self.id_type,
            'id_number': self.id_number,
            'registration_date': self.registration_date
        }