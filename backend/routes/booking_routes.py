from flask import Blueprint, request, jsonify
from models.customer import Customer
from models.booking import Booking, Book_Room, Renting, Rent_Room, Check_In
from database import db
from datetime import datetime

booking_bp = Blueprint('booking_bp', __name__)

# Get all
@booking_bp.route('/bookings', methods=['GET'])
def get_bookings():
    bookings = Booking.query.all()
    return jsonify([b.to_dict() for b in bookings])

@booking_bp.route('/rentings', methods=['GET'])
def get_rentings():
    rentings = Renting.query.all()
    return jsonify([r.to_dict() for r in rentings])


# Get single
@booking_bp.route('/bookings/<int:booking_ref>', methods=['GET'])
def get_booking(booking_ref):
    booking = Booking.query.get(booking_ref)
    if not booking:
        return {"error": "Booking not found"}, 404
    return booking.to_dict()

@booking_bp.route('/bookings/<int:renting_ref>', methods=['GET'])
def get_booking(renting_ref):
    renting = Booking.query.get(renting_ref)
    if not renting:
        return {"error": "Renting not found"}, 404
    return renting.to_dict()


#Create
@booking_bp.route('/bookings', methods=['POST'])
def create_booking():
    data = request.get_json()
    try:
        booking = Booking(
            booking_ref=data['booking_ref'],
            start_date=datetime.strptime(data['start_date'], '%Y-%m-%d').date(),
            end_date=datetime.strptime(data['end_date'], '%Y-%m-%d').date(),
            total_price=data['total_price'],
            customer_id=data['customer_id']
        )
        db.session.add(booking)
        db.session.commit()
        return booking.to_dict(), 201
    except KeyError as e:
        return {"error": f"Missing field: {str(e)}"}, 400
    except ValueError:
        return {"error": "Invalid date format. Use YYYY-MM-DD."}, 400

@booking_bp.route('/rentings', methods=['POST'])
def create_renting():
    data = request.get_json()
    try:
        renting = Renting(
            renting_ref=data['renting_ref'],
            start_date=datetime.strptime(data['start_date'], '%Y-%m-%d').date(),
            end_date=datetime.strptime(data['end_date'], '%Y-%m-%d').date(),
            total_price=data['total_price'],
            customer_id=data['customer_id']
        )
        db.session.add(renting)
        db.session.commit()
        return renting.to_dict(), 201
    except KeyError as e:
        return {"error": f"Missing field: {str(e)}"}, 400
    except ValueError:
        return {"error": "Invalid date format. Use YYYY-MM-DD."}, 400


#Update
@booking_bp.route('/bookings/<int:booking_ref>', methods=['PUT'])
def update_booking(booking_ref):
    booking = Booking.query.get(booking_ref)
    if not booking:
        return {"error": "Booking not found"}, 404

    data = request.get_json()
    if 'start_date' in data:
        try:
            booking.start_date = datetime.strptime(data['start_date'], '%Y-%m-%d').date()
        except ValueError:
            return {"error": "Invalid start_date format"}, 400
    if 'end_date' in data:
        try:
            booking.end_date = datetime.strptime(data['end_date'], '%Y-%m-%d').date()
        except ValueError:
            return {"error": "Invalid end_date format"}, 400

    booking.total_price = data.get('total_price', booking.total_price)
    booking.customer_id = data.get('customer_id', booking.customer_id)

    db.session.commit()
    return booking.to_dict()

@booking_bp.route('/rentings/<int:renting_ref>', methods=['PUT'])
def update_renting(renting_ref):
    renting = Renting.query.get(renting_ref)
    if not renting:
        return {"error": "Renting not found"}, 404

    data = request.get_json()
    if 'start_date' in data:
        try:
            renting.start_date = datetime.strptime(data['start_date'], '%Y-%m-%d').date()
        except ValueError:
            return {"error": "Invalid start_date format"}, 400
    if 'end_date' in data:
        try:
            renting.end_date = datetime.strptime(data['end_date'], '%Y-%m-%d').date()
        except ValueError:
            return {"error": "Invalid end_date format"}, 400

    renting.total_price = data.get('total_price', renting.total_price)
    renting.customer_id = data.get('customer_id', renting.customer_id)

    db.session.commit()
    return renting.to_dict()

# ------------------ DELETE BOOKING ------------------
@booking_bp.route('/bookings/<int:booking_ref>', methods=['DELETE'])
def delete_booking(booking_ref):
    booking = Booking.query.get(booking_ref)
    if not booking:
        return {"error": "Booking not found"}, 404

    db.session.delete(booking)
    db.session.commit()
    return {"message": f"Booking {booking_ref} deleted successfully."}

@booking_bp.route('/renting/<int:renting_ref>', methods=['DELETE'])
def delete_renting(renting_ref):
    renting = Booking.query.get(renting_ref)
    if not renting:
        return {"error": "Renting not found"}, 404

    db.session.delete(renting)
    db.session.commit()
    return {"message": f"Booking {renting_ref} deleted successfully."}

# ------------------ ASSIGN ROOM TO BOOKING ------------------
@booking_bp.route('/bookings/<int:booking_ref>/assign_room', methods=['POST'])
def assign_room_to_booking(booking_ref):
    booking = Booking.query.get(booking_ref)
    if not booking:
        return {"error": "Booking not found"}, 404

    data = request.get_json()
    try:
        book_room = Book_Room(
            booking_ref=booking_ref,
            room_number=data['room_number'],
            address=data['address'],
            city=data['city']
        )
        db.session.add(book_room)
        db.session.commit()
        return book_room.to_dict(), 201
    except KeyError as e:
        return {"error": f"Missing field: {str(e)}"}, 400

@booking_bp.route('/rentings/<int:renting_ref>/assign_room', methods=['POST'])
def assign_room_to_renting(renting_ref):
    renting = Renting.query.get(renting_ref)
    if not renting:
        return {"error": "Renting not found"}, 404

    data = request.get_json()
    try:
        rent_room = Rent_Room(
            renting_ref=renting_ref,
            room_number=data['room_number'],
            address=data['address'],
            city=data['city']
        )
        db.session.add(rent_room)
        db.session.commit()
        return rent_room.to_dict(), 201
    except KeyError as e:
        return {"error": f"Missing field: {str(e)}"}, 400

# ------------------ GET ROOMS FOR A BOOKING ------------------
@booking_bp.route('/bookings/<int:booking_ref>/rooms', methods=['GET'])
def get_rooms_for_booking(booking_ref):
    rooms = Book_Room.query.filter_by(booking_ref=booking_ref).all()
    return jsonify([r.to_dict() for r in rooms])

@booking_bp.route('/rentings/<int:renting_ref>/rooms', methods=['GET'])
def get_rooms_for_renting(renting_ref):
    rooms = Rent_Room.query.filter_by(renting_ref=renting_ref).all()
    return jsonify([r.to_dict() for r in rooms])