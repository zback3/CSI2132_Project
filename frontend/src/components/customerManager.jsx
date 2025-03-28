import React, { useEffect, useState } from 'react';
import { getCustomers, createCustomer, updateCustomer, deleteCustomer } from '../services/customerService';

function CustomerManager() {
    const [customers, setCustomers] = useState([]);
    const [form, setForm] = useState({
        customer_id: '',
        first_name: '',
        last_name: '',
        address: '',
        id_type: '',
        id_number: ''
    });

    useEffect(() => {
        fetchCustomers();
    }, []);

    const fetchCustomers = async () => {
        const res = await getCustomers();
        setCustomers(res.data);
    };

    const handleChange = (e) => {
        setForm({ ...form, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        await createCustomer(form);
        fetchCustomers();
        setForm({
            customer_id: '',
            first_name: '',
            last_name: '',
            address: '',
            id_type: '',
            id_number: ''
        });
    };

    const handleDelete = async (customerId) => {
        await deleteCustomer(customerId);
        fetchCustomers();
    };

    const handleUpdate = async (customerId) => {
        const updatedFirstName = prompt("Enter new first name:");
        const updatedLastName = prompt("Enter new last name:");
        const updatedAddress = prompt("Enter new address:");
        const updatedIdType = prompt("Enter new ID type:");
        const updatedIdNumber = prompt("Enter new ID number:");
        const updatedRegistrationDate = prompt("Enter new registration date (YYYY-MM-DD):");

        if (updatedFirstName && updatedLastName && updatedAddress && updatedIdType && updatedIdNumber && updatedRegistrationDate) {
            await updateCustomer(customerId, {
                first_name: updatedFirstName,
                last_name: updatedLastName,
                address: updatedAddress,
                id_type: updatedIdType,
                id_number: updatedIdNumber,
                registration_date: updatedRegistrationDate,
            });
            fetchCustomers();
        }
    };

    return (
        <div>
            <h3>Edit Customer Data</h3>
            <form onSubmit={handleSubmit}>
                <input
                    name="customer_id"
                    value={form.customer_id}
                    placeholder="Customer ID"
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
                <button type="submit">Add Customer</button>
            </form>

            <ul>
                {customers.map((customer) => (
                    <li key={customer.customer_id}>
                        {customer.customer_id} - {customer.first_name} {customer.last_name} - {customer.address} - {customer.id_type} - {customer.id_number} - {customer.registration_date}
                        <button onClick={() => handleUpdate(customer.customer_id)}>Update</button>
                        <button onClick={() => handleDelete(customer.customer_id)}>Delete</button>
                    </li>
                ))}
            </ul>
        </div>
    );
}

export default CustomerManager;