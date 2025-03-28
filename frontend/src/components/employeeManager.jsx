import React, { useEffect, useState } from 'react';
import { getEmployees, createEmployee, updateEmployee, deleteEmployee } from '../services/employeeService';

function EmployeeManager() {
    const [employees, setEmployees] = useState([]);
    const [form, setForm] = useState({
        employee_id: '',
        first_name: '',
        last_name: '',
        address: '',
        id_type: '',
        id_number: '',
        hotel_address: '',
        hotel_city: '',
        manager_employee_id: '',
    });

    useEffect(() => {
        fetchEmployees();
    }, []);

    const fetchEmployees = async () => {
        const res = await getEmployees();
        setEmployees(res.data);
    };

    const handleChange = (e) => {
        setForm({ ...form, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        await createEmployee(form);
        fetchEmployees();
        setForm({
            employee_id: '',
            first_name: '',
            last_name: '',
            address: '',
            id_type: '',
            id_number: '',
            hotel_address: '',
            hotel_city: '',
            manager_employee_id: '',
        });
    };

    const handleDelete = async (employeeId) => {
        await deleteEmployee(employeeId);
        fetchEmployees();
    };

    const handleUpdate = async (employeeId) => {
        const updatedFirstName = prompt("Enter new first name:");
        const updatedLastName = prompt("Enter new last name:");
        const updatedAddress = prompt("Enter new address:");
        const updatedIdType = prompt("Enter new ID type:");
        const updatedIdNumber = prompt("Enter new ID number:");
        const updatedHotelAddress = prompt("Enter new hotel address:");
        const updatedHotelCity = prompt("Enter new hotel city:");
        const updatedManagerId = prompt("Enter new manager employee ID:");

        if (updatedFirstName && updatedLastName && updatedAddress && updatedIdType && updatedIdNumber && updatedHotelAddress && updatedHotelCity) {
            await updateEmployee(employeeId, {
                first_name: updatedFirstName,
                last_name: updatedLastName,
                address: updatedAddress,
                id_type: updatedIdType,
                id_number: updatedIdNumber,
                hotel_address: updatedHotelAddress,
                hotel_city: updatedHotelCity,
                manager_employee_id: updatedManagerId || null,
            });
            fetchEmployees();
        }
    };

    return (
        <div>
            <h3>Edit Employee Data</h3>
            <form onSubmit={handleSubmit}>
                <input
                    name="employee_id"
                    value={form.employee_id}
                    placeholder="Employee ID"
                    onChange={handleChange}
                />
                <input
                    name="first_name"
                    value={form.first_name}
                    placeholder="First Name"
                    onChange={handleChange}
                />
                <input
                    name="last_name"
                    value={form.last_name}
                    placeholder="Last Name"
                    onChange={handleChange}
                />
                <input
                    name="address"
                    value={form.address}
                    placeholder="Address"
                    onChange={handleChange}
                />
                <input
                    name="id_type"
                    value={form.id_type}
                    placeholder="ID Type"
                    onChange={handleChange}
                />
                <input
                    name="id_number"
                    value={form.id_number}
                    placeholder="ID Number"
                    onChange={handleChange}
                />
                <input
                    name="hotel_address"
                    value={form.hotel_address}
                    placeholder="Hotel Address"
                    onChange={handleChange}
                />
                <input
                    name="hotel_city"
                    value={form.hotel_city}
                    placeholder="Hotel City"
                    onChange={handleChange}
                />
                <input
                    name="manager_employee_id"
                    value={form.manager_employee_id}
                    placeholder="Manager Employee ID"
                    onChange={handleChange}
                />
                <button type="submit">Add Employee</button>
            </form>

            <ul>
                {employees.map((employee) => (
                    <li key={employee.employee_id}>
                        {employee.employee_id} - {employee.first_name} {employee.last_name} - {employee.address} - {employee.id_type} - {employee.id_number} - {employee.hotel_address}, {employee.hotel_city} - Manager: {employee.manager_employee_id}
                        <button onClick={() => handleUpdate(employee.employee_id)}>Update</button>
                        <button onClick={() => handleDelete(employee.employee_id)}>Delete</button>
                    </li>
                ))}
            </ul>
        </div>
    );
}

export default EmployeeManager;