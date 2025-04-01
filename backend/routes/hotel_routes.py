from datetime import date, datetime, timedelta
from sqlalchemy import text
from flask import Blueprint, request, jsonify
from models.hotel import Available_Rooms_Per_Area, AvailableRoomsView, Hotel, Hotel_Phone_Inst, Chain, Chain_Email_Inst, Chain_Phone_Inst, HotelTotalCapacity
from database import db

hotel_bp = Blueprint('hotel_bp', __name__)

@hotel_bp.route('/hotels', methods=['GET'])
def get_hotels():
    hotels = Hotel.query.all()
    return jsonify([hotel.to_dict() for hotel in hotels])

@hotel_bp.route('/hotels/<address>/<city>', methods=['GET'])
def get_hotel(address, city):
    hotel = Hotel.query.get((address, city))
    if not hotel:
        return {"error": "Hotel not found"}, 404
    return hotel.to_dict()

@hotel_bp.route('/hotels', methods=['POST'])
def create_hotel():
    data = request.get_json()
    try:
        hotel = Hotel(
            address=data['address'],
            city=data['city'],
            name=data['name'],
            rating=data.get('rating'),
            email=data.get('email'),
            number_rooms=data.get('number_rooms'),
            manager_id=data.get('manager_id')
        )
        db.session.add(hotel)
        db.session.commit()
        return hotel.to_dict(), 201
    except KeyError as e:
        return {"error": f"Missing required field: {str(e)}"}, 400

@hotel_bp.route('/hotels/<address>/<city>', methods=['PUT'])
def update_hotel(address, city):
    hotel = Hotel.query.get((address, city))
    if not hotel:
        return {"error": "Hotel not found"}, 404

    data = request.get_json()
    hotel.name = data.get('name', hotel.name)
    hotel.rating = data.get('rating', hotel.rating)
    hotel.email = data.get('email', hotel.email)
    hotel.number_rooms = data.get('number_rooms', hotel.number_rooms)
    hotel.manager_id = data.get('manager_id', hotel.manager_id)

    db.session.commit()
    return hotel.to_dict()

@hotel_bp.route('/hotels/<address>/<city>', methods=['DELETE'])
def delete_hotel(address, city):
    hotel = Hotel.query.get((address, city))
    if not hotel:
        return {"error": "Hotel not found"}, 404

    db.session.delete(hotel)
    db.session.commit()
    return {"message": f"Hotel at {address}, {city} deleted."}

# ------------------ HOTEL PHONE NUMBERS ------------------

# Route to get all phone numbers for a specific hotel
@hotel_bp.route('/hotels/<address>/<city>/phones', methods=['GET'])
def get_hotel_phones(address, city):
    phones = Hotel_Phone_Inst.query.filter_by(address=address, city=city).all()
    return jsonify([phone.phone_number for phone in phones])

@hotel_bp.route('/hotels/<address>/<city>/phones', methods=['POST'])
def add_hotel_phone(address, city):
    data = request.get_json()
    phone_number = data.get('phone_number')

    if not phone_number:
        return {"error": "Phone number is required"}, 400

    phone = Hotel_Phone_Inst(address=address, city=city, phone_number=phone_number)
    db.session.add(phone)
    db.session.commit()
    return {"message": "Phone number added successfully"}, 201

@hotel_bp.route('/hotels/<address>/<city>/phones/<phone_number>', methods=['DELETE'])
def delete_hotel_phone(address, city, phone_number):
    phone = Hotel_Phone_Inst.query.filter_by(address=address, city=city, phone_number=phone_number).first()
    if not phone:
        return {"error": "Phone number not found"}, 404

    db.session.delete(phone)
    db.session.commit()
    return {"message": "Phone number deleted successfully"}, 200

# ------------------ CHAINS ------------------

@hotel_bp.route('/chains', methods=['GET'])
def get_chains():
    chains = Chain.query.all()
    return jsonify([c.to_dict() for c in chains])

@hotel_bp.route('/chains', methods=['POST'])
def create_chain():
    data = request.get_json()
    try:
        chain = Chain(
            name=data['name'],
            office_address=data['office_address']
            )
        db.session.add(chain)
        db.session.commit()
        return chain.to_dict(), 201
    except KeyError as e:
        return {"error": f"Missing required field: {str(e)}"}, 400

@hotel_bp.route('/chains/<name>', methods=['PUT'])
def update_chain(name):
    chain = Chain.query.get(name)
    if not chain:
        return {"error": "Chain not found"}, 404

    data = request.get_json()
    chain.office_address = data.get('office_address', chain.office_address)

    db.session.commit()
    return chain.to_dict()

@hotel_bp.route('/chains/<name>', methods=['DELETE'])
def delete_chain(name):
    chain = Chain.query.get(name)
    if not chain:
        return {"error": "Chain not found"}, 404

    db.session.delete(chain)
    db.session.commit()
    return {"message": f"Chain {name} deleted."}

@hotel_bp.route('/chain_emails', methods=['GET'])
def get_chain_emails():
    emails = Chain_Email_Inst.query.all()
    return jsonify([
        {"name": e.name, "email": e.email}
        for e in emails
    ])

@hotel_bp.route('/chain_phones', methods=['GET'])
def get_chain_phones():
    phones = Chain_Phone_Inst.query.all()
    return jsonify([
        {"name": p.name, "email": p.email}
        for p in phones
    ])

# ------------------ Views ------------------  

@hotel_bp.route('/available_rooms_per_area', methods=['GET'])
def get_available_rooms_per_area():
    try:
        # Query the view
        available_rooms = Available_Rooms_Per_Area.query.all()
        return jsonify([room.to_dict() for room in available_rooms]), 200
    except Exception as e:
        return {"error": str(e)}, 500


@hotel_bp.route('/hotel_total_capacity', methods=['GET'])
def get_hotel_total_capacity():
    try:
        hotel_capacity = HotelTotalCapacity.query.all()
        return jsonify([capacity.to_dict() for capacity in hotel_capacity]), 200
    except Exception as e:
        return {"error": str(e)}, 500



@hotel_bp.route('/available_rooms_city/<city>', methods=['GET'])
def get_available_city(city):
    available_rooms = Available_Rooms_Per_Area.query.get((city))
    if not available_rooms:
        return {"error": "No available rooms found"}, 404   
    return available_rooms.to_dict()



@hotel_bp.route('/available_rooms/<city>/<int:min_capacity>/<start_date>/<end_date>', methods=['GET'])
def get_available_rooms(city, min_capacity, start_date, end_date):
    try:
        # Convert string dates to date objects
        start_date = datetime.strptime(start_date, '%Y-%m-%d').date()
        end_date = datetime.strptime(end_date, '%Y-%m-%d').date()
        
        # Validate dates
        if start_date < date.today():
            return {"error": "start_date must be today or in the future"}, 400
        if start_date > end_date:
            return {"error": "start_date must be before end_date"}, 400
        
        # Validate capacity (already converted to int by route converter)
        if min_capacity < 0:  
            return {"error": "min_capacity must be a positive integer"}, 400

        # Execute query
        query = text("""
            SELECT * FROM "Hotel".get_available_rooms_by_date(
                :start_date, 
                :end_date, 
                :city, 
                :min_capacity
            )
        """)
        
        results = db.session.execute(query, {
            'city': city,
            'start_date': start_date,
            'end_date': end_date,
            'min_capacity': min_capacity
        })
        
        # Convert results to JSON
        available_rooms = [
            {
                'city': row.city,
                'address': row.address,  # Fixed space before 'address'
                'room_number': row.room_number,
                'capacity': row.capacity,
                'amenities': row.amenities,
                'price': row.price,
                'features': {  # Grouped view-related features
                    'mountain_view': row.mountain_view,
                    'sea_view': row.sea_view,
                    'extendable': row.extendable
                }
            }
            for row in results
        ]
        
        if not available_rooms:
            return {"message": "No available rooms found matching your criteria"}, 200
        
        return jsonify(available_rooms)
        
    except ValueError:
        return {"error": "Invalid date format. Use YYYY-MM-DD"}, 400
    except Exception as e:
        return {"error": str(e)}, 500
