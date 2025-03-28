from flask import Blueprint, request, jsonify
from models.room import Room
from database import db

room_bp = Blueprint('room_bp', __name__)

@room_bp.route('/rooms', methods=['GET'])
def get_rooms():
    rooms = Room.query.all()
    return jsonify([room.to_dict() for room in rooms])

@room_bp.route('/rooms', methods=['POST'])
def create_room():
    data = request.get_json()
    room = Room(**data)
    db.session.add(room)
    db.session.commit()
    return room.to_dict(), 201

@room_bp.route('/rooms/<int:room_number>/<hotel_address>/<hotel_city>', methods=['GET'])
def get_room(room_number, hotel_address, hotel_city):
    room = Room.query.get((room_number, hotel_address, hotel_city))
    if not room:
        return {"error": "Room not found"}, 404
    return room.to_dict()

@room_bp.route('/rooms/<int:room_number>/<hotel_address>/<hotel_city>', methods=['PUT'])
def update_room(room_number, hotel_address, hotel_city):
    room = Room.query.get((room_number, hotel_address, hotel_city))
    if not room:
        return {"error": "Room not found"}, 404
    data = request.get_json()
    for key, value in data.items():
        setattr(room, key, value)
    db.session.commit()
    return room.to_dict()

@room_bp.route('/rooms/<int:room_number>/<hotel_address>/<hotel_city>', methods=['DELETE'])
def delete_room(room_number, hotel_address, hotel_city):
    room = Room.query.get((room_number, hotel_address, hotel_city))
    if not room:
        return {"error": "Room not found"}, 404
    db.session.delete(room)
    db.session.commit()
    return {"message": "Room deleted successfully"}