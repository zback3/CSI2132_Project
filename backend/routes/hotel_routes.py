from flask import Blueprint, request, jsonify
from models.hotel import Hotel, Hotel_Phone_Inst, Chain, Chain_Email_Inst, Chain_Phone_Inst
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