from flask_sqlalchemy import SQLAlchemy

from database import db

class Room(db.Model):
    __tablename__ = 'Room'
    __table_args__ = {'schema': 'Hotel'}

    room_number = db.Column(db.Integer, primary_key=True)
    address = db.Column(db.String, primary_key=True)
    city = db.Column(db.String, primary_key=True)
    price = db.Column(db.Float, nullable=False)
    capacity = db.Column(db.Integer, nullable=False)
    mountain_view = db.Column(db.Boolean, default=False)
    sea_view = db.Column(db.Boolean, default=False)
    extendable = db.Column(db.Boolean, default=False)

    def __init__(self, room_number, address, city, price, capacity, mountain_view, sea_view, extendable):
        self.room_number = room_number
        self.address = address
        self.city = city
        self.price = price
        self.capacity = capacity
        self.mountain_view = mountain_view
        self.sea_view = sea_view
        self.extendable = extendable

    def to_dict(self):
        return {
            'room_number': self.room_number,
            'address': self.address,
            'city': self.city,
            'price': self.price,
            'capacity': self.capacity,
            'mountain_view': self.mountain_view,
            'sea_view': self.sea_view,
            'extendable': self.extendable
        }


class Room_Amenities(db.Model):
    __tablename__ = 'Room_Amenities'
    __table_args__ = {'schema': 'Hotel'}

    room_number = db.Column(db.Integer, primary_key=True)
    address = db.Column(db.String, primary_key=True)
    city = db.Column(db.String, primary_key=True)
    amenity = db.Column(db.String, primary_key=True)


class Room_Issues(db.Model):
    __tablename__ = 'Room_Issues'
    __table_args__ = {'schema': 'Hotel'}

    room_number = db.Column(db.Integer, primary_key=True)
    address = db.Column(db.String, primary_key=True)
    city = db.Column(db.String, primary_key=True)
    issue = db.Column(db.String, primary_key=True)