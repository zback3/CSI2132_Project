from flask import Flask, request
from flask_sqlalchemy import SQLAlchemy
from database import db

from flask_cors import CORS

app = Flask(__name__)
CORS(app)

dbPassword = '075002'

app.config['SQLALCHEMY_DATABASE_URI'] = f'postgresql://postgres:{dbPassword}@localhost/hotels'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)


from models.hotel import Hotel, Hotel_Phone_Inst, Chain, Chain_Email_Inst, Chain_Phone_Inst, Available_Rooms_Per_Area,HotelTotalCapacity
from models.room import Room, Room_Amenities, Room_Issues
from models.customer import Customer
from models.employee import Employee
from models.booking import Booking, Book_Room, Renting, Rent_Room, Check_In

from routes.hotel_routes import hotel_bp
from routes.room_routes import room_bp
from routes.customer_routes import customer_bp
from routes.employee_routes import employee_bp
from routes.booking_routes import booking_bp
from routes.check_in_routes import check_in_bp


app.register_blueprint(hotel_bp)
app.register_blueprint(room_bp)
app.register_blueprint(customer_bp)
app.register_blueprint(employee_bp)
app.register_blueprint(booking_bp)
app.register_blueprint(check_in_bp)

print("Registered Routes:")
print(app.url_map)

if __name__ == '__main__':
    app.run()