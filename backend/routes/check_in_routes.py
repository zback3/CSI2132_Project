from flask import Blueprint, request, jsonify
from models.booking import Renting, Check_In, Booking, Rent_Room, Book_Room
from database import db
from datetime import datetime

check_in_bp = Blueprint('check_in_bp', __name__)

# Create a new renting from scratch
@check_in_bp.route('/check_in/new_renting', methods=['POST'])
def create_new_renting():
    data = request.get_json()
    try:
        # Create the Renting entry
        renting = Renting(
            renting_ref=data['renting_ref'],
            start_date=datetime.strptime(data['start_date'], '%Y-%m-%d').date(),
            end_date=datetime.strptime(data['end_date'], '%Y-%m-%d').date(),
            total_price=data['total_price'],
            customer_id=data['customer_id']
        )
        db.session.add(renting)
        db.session.flush() 

        # Add rooms to Rent_Room table
        for room in data['rooms']:
            rent_room = Rent_Room(
                renting_ref=data['renting_ref'],
                room_number=room['room_number'],
                address=room['address'],
                city=room['city']
            )
            db.session.add(rent_room)

        # Create the Check_In entry
        check_in = Check_In(
            renting_ref=data['renting_ref'],
            employee_id=data['employee_id'],
            booking_ref=None,  # No booking associated
            payment=data['payment']
        )
        db.session.add(check_in)

        db.session.commit()
        return {"message": "New renting created successfully"}, 201
    except KeyError as e:
        return {"error": f"Missing field: {str(e)}"}, 400
    except ValueError:
        return {"error": "Invalid data format. Use YYYY-MM-DD."}, 400

@check_in_bp.route('/check_in/from_booking/<int:booking_ref>', methods=['POST'])
def create_renting_from_booking(booking_ref):
    data = request.get_json()
    booking = Booking.query.get(booking_ref)
    if not booking:
        return {"error": "Booking not found"}, 404

    try:
        # Create the Renting entry
        renting = Renting(
            renting_ref=data['renting_ref'],
            start_date=booking.start_date,
            end_date=booking.end_date,
            total_price=booking.total_price,
            customer_id=booking.customer_id
        )
        db.session.add(renting)
        db.session.flush() 

        # Copy rooms from Book_Room to Rent_Room
        booked_rooms = Book_Room.query.filter_by(booking_ref=booking_ref).all()
        for room in booked_rooms:
            rent_room = Rent_Room(
                renting_ref=data['renting_ref'],
                room_number=room.room_number,
                address=room.address,
                city=room.city
            )
            db.session.add(rent_room)

        # Create the Check_In entry
        check_in = Check_In(
            renting_ref=data['renting_ref'],
            employee_id=data['employee_id'],
            booking_ref=booking_ref,
            payment=data['payment']
        )
        db.session.add(check_in)

        db.session.commit()  # Commit all changes to the database
        return {"message": "New renting created successfully"}, 201
    except KeyError as e:
        db.session.rollback()  # Rollback the transaction in case of an error
        return {"error": f"Missing field: {str(e)}"}, 400
    except ValueError:
        db.session.rollback()  # Rollback the transaction in case of an error
        return {"error": "Invalid data format. Use YYYY-MM-DD."}, 400