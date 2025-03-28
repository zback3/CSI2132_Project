from flask import Blueprint, request, jsonify
from models.customer import Customer
from database import db
from datetime import datetime

customer_bp = Blueprint('customer_bp', __name__)

# ------------------ GET ALL ------------------
@customer_bp.route('/customers', methods=['GET'])
def get_customers():
    customers = Customer.query.all()
    return jsonify([c.to_dict() for c in customers])

# ------------------ GET BY ID ------------------
@customer_bp.route('/customers/<int:customer_id>', methods=['GET'])
def get_customer(customer_id):
    customer = Customer.query.get(customer_id)
    if not customer:
        return {"error": "Customer not found"}, 404
    return customer.to_dict()

# ------------------ CREATE ------------------
@customer_bp.route('/customers', methods=['POST'])
def create_customer():
    data = request.get_json()

    try:
        customer = Customer(
            customer_id=data['customer_id'],
            first_name=data['first_name'],
            last_name=data['last_name'],
            address=data['address'],
            id_type=data['id_type'],
            id_number=data['id_number'],
        )
        db.session.add(customer)
        db.session.commit()
        return customer.to_dict(), 201
    except KeyError as e:
        return {"error": f"Missing field: {str(e)}"}, 400
    except ValueError:
        return {"error": "Invalid date format. Use YYYY-MM-DD."}, 400

# ------------------ UPDATE ------------------
@customer_bp.route('/customers/<int:customer_id>', methods=['PUT'])
def update_customer(customer_id):
    customer = Customer.query.get(customer_id)
    if not customer:
        return {"error": "Customer not found"}, 404

    data = request.get_json()
    customer.first_name = data.get('first_name', customer.first_name)
    customer.last_name = data.get('last_name', customer.last_name)
    customer.address = data.get('address', customer.address)
    customer.id_type = data.get('id_type', customer.id_type)
    customer.id_number = data.get('id_number', customer.id_number)

    if 'registration_date' in data:
        try:
            customer.registration_date = datetime.strptime(data['registration_date'], '%Y-%m-%d').date()
        except ValueError:
            return {"error": "Invalid date format. Use YYYY-MM-DD."}, 400

    db.session.commit()
    return customer.to_dict()

# ------------------ DELETE ------------------
@customer_bp.route('/customers/<int:customer_id>', methods=['DELETE'])
def delete_customer(customer_id):
    customer = Customer.query.get(customer_id)
    if not customer:
        return {"error": "Customer not found"}, 404

    db.session.delete(customer)
    db.session.commit()
    return {"message": f"Customer {customer_id} deleted successfully"}
