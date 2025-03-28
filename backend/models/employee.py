from database import db

class Employee(db.Model):
    __tablename__ = 'Employee'
    __table_args__ = {'schema': 'Hotel'}

    employee_id = db.Column(db.Integer, primary_key=True)
    first_name = db.Column(db.String, nullable=False)
    last_name = db.Column(db.String, nullable=False)
    address = db.Column(db.String, nullable=False)
    id_type = db.Column(db.String, nullable=False)
    id_number = db.Column(db.String, nullable=False)
    hotel_address= db.Column(db.String, nullable=False)
    hotel_city = db.Column(db.String, nullable=False)
    manager_employee_id = db.Column(db.Integer, nullable=True)

    def __init__(self, employee_id, first_name, last_name, address, id_type, id_number, hotel_address, hotel_city, manager_employee_id):
        self.employee_id = employee_id
        self.first_name = first_name
        self.last_name = last_name
        self.address = address
        self.id_type = id_type
        self.id_number = id_number
        self.hotel_address = hotel_address
        self.hotel_city = hotel_city
        self.manager_employee_id = manager_employee_id
    
    def to_dict(self):
        return {
            'employee_id': self.employee_id,
            'first_name': self.first_name,
            'last_name': self.last_name,
            'address': self.address,
            'id_type': self.id_type,
            'id_number': self.id_number,
            'hotel_address': self.hotel_address,
            'hotel_city': self.hotel_city,
            'manager_employee_id': self.manager_employee_id
        }