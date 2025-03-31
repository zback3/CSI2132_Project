import React, { useState, useEffect } from 'react';
import { createNewRenting, createRentingFromBooking } from '../services/checkinService';
import { getBookings } from '../services/bookingService';

function CheckInManager() {
    const [bookings, setBookings] = useState([]);
    const [form, setForm] = useState({
        renting_ref: '',
        start_date: '',
        end_date: '',
        total_price: '',
        customer_id: '',
        employee_id: '',
        payment: '',
        rooms: [] // Array to hold room details
    });
    const [roomForm, setRoomForm] = useState({
        room_number: '',
        address: '',
        city: ''
    });
    const [selectedRooms, setSelectedRooms] = useState([]);

    useEffect(() => {
        fetchBookings();
    }, []);

    const fetchBookings = async () => {
        const res = await getBookings();
        setBookings(res.data);
    };

    const handleChange = (e) => {
        setForm({ ...form, [e.target.name]: e.target.value });
    };

    const handleRoomChange = (e) => {
        setRoomForm({ ...roomForm, [e.target.name]: e.target.value });
    };

    const addRoom = () => {
        setSelectedRooms([...selectedRooms, roomForm]);
        setRoomForm({ room_number: '', address: '', city: '' });
    };

    const handleSubmitNewRenting = async (e) => {
        e.preventDefault();
        const rentingData = { ...form, rooms: selectedRooms };
        await createNewRenting(rentingData);
        alert('New renting created successfully!');
        setForm({
            renting_ref: '',
            start_date: '',
            end_date: '',
            total_price: '',
            customer_id: '',
            employee_id: '',
            payment: '',
            rooms: []
        });
        setSelectedRooms([]);
    };

    const handleCheckInBooking = async (bookingRef) => {
        const rentingRef = prompt('Enter a new renting reference:');
        const employeeId = prompt('Enter your employee ID:');
        const payment = prompt('Enter payment details:');

        if (rentingRef && employeeId && payment) {
            await createRentingFromBooking(bookingRef, {
                renting_ref: rentingRef,
                employee_id: employeeId,
                payment: payment
            });
            alert('Renting created from booking successfully!');
        }
    };

    return (
        <div>
            <h3>Check-In Manager</h3>

            <h4>Create New Renting</h4>
            <form onSubmit={handleSubmitNewRenting}>
                <input
                    name="renting_ref"
                    value={form.renting_ref}
                    placeholder="Renting Reference"
                    onChange={handleChange}
                />
                <input
                    name="start_date"
                    value={form.start_date}
                    placeholder="Start Date (YYYY-MM-DD)"
                    onChange={handleChange}
                />
                <input
                    name="end_date"
                    value={form.end_date}
                    placeholder="End Date (YYYY-MM-DD)"
                    onChange={handleChange}
                />
                <input
                    name="total_price"
                    value={form.total_price}
                    placeholder="Total Price"
                    onChange={handleChange}
                />
                <input
                    name="customer_id"
                    value={form.customer_id}
                    placeholder="Customer ID"
                    onChange={handleChange}
                />
                <input
                    name="employee_id"
                    value={form.employee_id}
                    placeholder="Employee ID"
                    onChange={handleChange}
                />
                <input
                    name="payment"
                    value={form.payment}
                    placeholder="Payment Details"
                    onChange={handleChange}
                />

                <h5>Add Rooms</h5>
                <input
                    name="room_number"
                    value={roomForm.room_number}
                    placeholder="Room Number"
                    onChange={handleRoomChange}
                />
                <input
                    name="address"
                    value={roomForm.address}
                    placeholder="Address"
                    onChange={handleRoomChange}
                />
                <input
                    name="city"
                    value={roomForm.city}
                    placeholder="City"
                    onChange={handleRoomChange}
                />
                <button type="button" onClick={addRoom}>Add Room</button>

                <ul>
                    {selectedRooms.map((room, index) => (
                        <li key={index}>
                            Room {room.room_number} - {room.address}, {room.city}
                        </li>
                    ))}
                </ul>

                <button type="submit">Create Renting</button>
            </form>

            <h4>Check-In Existing Booking</h4>
            <ul>
                {bookings.map((booking) => (
                    <li key={booking.booking_ref}>
                        Booking #{booking.booking_ref} - Customer: {booking.customer_id} - Dates: {booking.start_date} to {booking.end_date}
                        <button onClick={() => handleCheckInBooking(booking.booking_ref)}>Check In</button>
                    </li>
                ))}
            </ul>
        </div>
    );
}

export default CheckInManager;