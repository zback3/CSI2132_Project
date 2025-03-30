from database import db

class Hotel(db.Model):
    __tablename__ = 'Hotel'
    __table_args__ = {'schema': 'Hotel'}

    address = db.Column(db.String, primary_key=True)
    city = db.Column(db.String, primary_key=True)
    name = db.Column(db.String, nullable=False)
    rating = db.Column(db.Integer)
    email = db.Column(db.String)
    number_rooms = db.Column(db.Integer)
    manager_id = db.Column(db.Integer)

    def __init__(self, address, city, name, rating, email, number_rooms, manager_id):
        self.address = address
        self.city = city
        self.name = name
        self.rating = rating
        self.email = email
        self.number_rooms = number_rooms
        self.manager_id = manager_id

    def to_dict(self):
        return {
            'address': self.address,
            'city': self.city,
            'name': self.name,
            'rating': self.rating,
            'email': self.email,
            'number_rooms': self.number_rooms,
            'manager_id': self.manager_id
        }

class Hotel_Phone_Inst(db.Model):
    __tablename__ = 'Hotel_Phone_Inst'
    __table_args__ = {'schema': 'Hotel'}

    address = db.Column(db.String, primary_key=True)
    city = db.Column(db.String, primary_key=True)
    phone_number = db.Column(db.String, primary_key=True)

class Chain(db.Model):
    __tablename__ = 'Chain'
    __table_args__ = {'schema': 'Hotel'}

    name = db.Column(db.String, primary_key=True)
    office_address = db.Column(db.String, nullable=False)
    number_of_hotels = db.Column(db.Integer, nullable=False, default=0)

    def __init__(self, name, office_address):
        self.name = name
        self.office_address = office_address

    def to_dict(self):
        return {
            'name': self.name,
            'office_address': self.office_address,
            'number_of_hotels': self.number_of_hotels
        }

class Chain_Email_Inst(db.Model):
    __tablename__ = 'Chain_Email_Inst'
    __table_args__ = {'schema': 'Hotel'}

    name = db.Column(db.String, primary_key=True)
    email = db.Column(db.String, primary_key=True)

class Chain_Phone_Inst(db.Model):
    __tablename__ = 'Chain_Phone_Inst'
    __table_args__ = {'schema': 'Hotel'}

    name = db.Column(db.String, primary_key=True)
    email = db.Column(db.String, primary_key=True)

class Available_Rooms_Per_Area(db.Model):
    __tablename__ = 'available_rooms_per_area'
    __table_args__ = {'schema': 'Hotel'}
    
    city = db.Column(db.String(100), primary_key=True)
    available_rooms_count = db.Column(db.Integer)
    
    def to_dict(self):
        return {
            'city': self.city,
            'available_rooms': self.available_rooms_count,
        }
    
class HotelTotalCapacity(db.Model):
    __tablename__ = 'hotel_total_capacity'
    __table_args__ = {'schema': 'Hotel'}
    
    address = db.Column(db.String(200), primary_key=True)
    city = db.Column(db.String(100), primary_key=True)
    hotel_name = db.Column(db.String(100))
    total_capacity = db.Column(db.Integer)
    total_rooms = db.Column(db.Integer)
    
    def to_dict(self):
        return {
            'address': self.address,
            'city': self.city,
            'hotel_name': self.hotel_name,
            'total_capacity': self.total_capacity,
            'total_rooms': self.total_rooms
        }
    
class AvailableRoomsView(db.Model):
    __tablename__ = 'available_rooms_view'
    __table_args__ = {'schema': 'Hotel'}
    
    city = db.Column(db.String(100), primary_key=True)
    available_rooms_count = db.Column(db.Integer)
    start_date = db.Column(db.Date, primary_key=True)
    end_date = db.Column(db.Date, primary_key=True)
    
    def to_dict(self):
        return {
            'city': self.city,
            'available_rooms': self.available_rooms_count,
            'start_date': self.start_date.isoformat(),
            'end_date': self.end_date.isoformat()
        }