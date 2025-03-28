from flask import Blueprint, request, jsonify
from models.employee import Employee
from database import db

employee_bp = Blueprint('employee_bp', __name__)

# ------------------ GET ALL EMPLOYEES ------------------
@employee_bp.route('/employees', methods=['GET'])
def get_employees():
    employees = Employee.query.all()
    return jsonify([e.to_dict() for e in employees])

# ------------------ GET SINGLE EMPLOYEE ------------------
@employee_bp.route('/employees/<int:employee_id>', methods=['GET'])
def get_employee(employee_id):
    employee = Employee.query.get(employee_id)
    if not employee:
        return {"error": "Employee not found"}, 404
    return employee.to_dict()

# ------------------ CREATE EMPLOYEE ------------------
@employee_bp.route('/employees', methods=['POST'])
def create_employee():
    data = request.get_json()

    try:
        employee = Employee(
            employee_id=data['employee_id'],
            first_name=data['first_name'],
            last_name=data['last_name'],
            address=data['address'],
            id_type=data['id_type'],
            id_number=data['id_number'],
            hotel_address=data['hotel_address'],
            hotel_city=data['hotel_city'],
            manager_employee_id=data.get('manager_employee_id')  # optional
        )
        db.session.add(employee)
        db.session.commit()
        return employee.to_dict(), 201
    except KeyError as e:
        return {"error": f"Missing field: {str(e)}"}, 400

# ------------------ UPDATE EMPLOYEE ------------------
@employee_bp.route('/employees/<int:employee_id>', methods=['PUT'])
def update_employee(employee_id):
    employee = Employee.query.get(employee_id)
    if not employee:
        return {"error": "Employee not found"}, 404

    data = request.get_json()
    employee.first_name = data.get('first_name', employee.first_name)
    employee.last_name = data.get('last_name', employee.last_name)
    employee.address = data.get('address', employee.address)
    employee.id_type = data.get('id_type', employee.id_type)
    employee.id_number = data.get('id_number', employee.id_number)
    employee.hotel_address = data.get('hotel_address', employee.hotel_address)
    employee.hotel_city = data.get('hotel_city', employee.hotel_city)
    employee.manager_employee_id = data.get('manager_employee_id', employee.manager_employee_id)

    db.session.commit()
    return employee.to_dict()

# ------------------ DELETE EMPLOYEE ------------------
@employee_bp.route('/employees/<int:employee_id>', methods=['DELETE'])
def delete_employee(employee_id):
    employee = Employee.query.get(employee_id)
    if not employee:
        return {"error": "Employee not found"}, 404

    db.session.delete(employee)
    db.session.commit()
    return {"message": f"Employee {employee_id} deleted successfully"}
