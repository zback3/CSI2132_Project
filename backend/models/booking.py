from database import db

class Booking(db.Model):
    __tablename__ = 'Booking'
    __table_args__ = {'schema': 'Hotel'}

    booking_ref = db.Column(db.Integer, primary_key=True)
    start_date = db.Column(db.Date, nullable=False)
    end_date = db.Column(db.Date, nullable=False)
    total_price = db.Column(db.Float, nullable=False)
    customer_id = db.Column(db.Integer, nullable=False)

    def __init__(self, booking_ref, start_date, end_date, total_price, customer_id):
        self.booking_ref = booking_ref
        self.start_date = start_date
        self.end_date = end_date
        self.total_price = total_price
        self.customer_id = customer_id
    
    def to_dict(self):
        return {
            'booking_ref': self.booking_ref,
            'start_date': self.start_date,
            'end_date': self.end_date,
            'total_price': self.total_price,
            'customer_id': self.customer_id
        }


class Book_Room(db.Model):
    __tablename__ = 'Book_Room'
    __table_args__ = {'schema': 'Hotel'}

    booking_ref = db.Column(db.Integer, primary_key=True)
    room_number = db.Column(db.Integer, primary_key=True)
    address = db.Column(db.String, primary_key=True)
    city = db.Column(db.String, primary_key=True)

    def __init__(self, booking_ref, room_number, address, city):
        self.booking_ref = booking_ref
        self.room_number = room_number
        self.address = address
        self.city = city

    def to_dict(self):
        return {
            'booking_ref': self.booking_ref,
            'room_number': self.room_number,
            'address': self.address,
            'city': self.city
        }

class Renting(db.Model):
    __tablename__ = 'Renting'
    __table_args__ = {'schema': 'Hotel'}

    renting_ref = db.Column(db.Integer, primary_key=True)
    start_date = db.Column(db.Date, nullable=False)
    end_date = db.Column(db.Date, nullable=False)
    total_price = db.Column(db.Float, nullable=False)
    customer_id = db.Column(db.Integer, nullable=False)

    def __init__(self, renting_ref, start_date, end_date, total_price, customer_id):
        self.renting_ref = renting_ref
        self.start_date = start_date
        self.end_date = end_date
        self.total_price = total_price
        self.customer_id = customer_id

    def to_dict(self):
        return {
            'renting_ref': self.renting_ref,
            'start_date': self.start_date,
            'end_date': self.end_date,
            'total_price': self.total_price,
            'customer_id': self.customer_id
        }

class Rent_Room(db.Model):
    __tablename__ = 'Rent_Room'
    __table_args__ = {'schema': 'Hotel'}

    renting_ref = db.Column(db.Integer, primary_key=True)
    room_number = db.Column(db.Integer, primary_key=True)
    address = db.Column(db.String, primary_key=True)
    city = db.Column(db.String, primary_key=True)

    def __init__(self, renting_ref, room_number, address, city):
        self.renting_ref = renting_ref
        self.room_number = room_number
        self.address = address
        self.city = city

    def to_dict(self):
        return {
            'renting_ref': self.renting_ref,
            'room_number': self.room_number,
            'address': self.address,
            'city': self.city
        }

class Check_In(db.Model):
    __tablename__ = 'Check_In'
    __table_args__ = {'schema': 'Hotel'}

    renting_ref = db.Column(db.Integer, primary_key=True)
    employee_id = db.Column(db.Integer, nullable=False)
    booking_ref = db.Column(db.Integer, nullable=True)
    payment = db.Column(db.String, nullable=False) 

    def __init__(self, renting_ref, employee_id, booking_ref, payment):
        self.renting_ref = renting_ref
        self.employee_id = employee_id
        self.booking_ref = booking_ref
        self.payment = payment
    
    def to_dict(self):
        return {
            'renting_ref': self.renting_ref,
            'employee_id': self.employee_id,
            'booking_ref': self.booking_ref,
            'payment': self.payment
        }