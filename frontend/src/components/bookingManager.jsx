import React, { useState } from 'react';
import { createBooking } from '../services/bookingService';

function BookingManager() {
    const [rooms, setRooms] = useState([]);
    const [form, setForm] = useState({
        booking_ref: '',
        customer_id: '',
        address: '',
        city: '',
        room_number: '',
        check_in_date: '',
        check_out_date: '',
    });

    const fetchAvailableRooms = async () => {
        const { city, check_in_date, check_out_date } = form;
        const res = await getAvailableRooms(city, check_in_date, check_out_date);
        setRooms(res.data);
    };

    
    const handleChange = (e) => {
        setForm({ ...form, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        await createBooking(form);
        alert('Room booked successfully!');
        setForm({
            booking_ref: '',
            customer_id: '',
            address: '',
            city: '',
            room_number: '',
            check_in_date: '',
            check_out_date: '',
        });
    };

    return (
        <div>
            <h3>Book a Room</h3>
            <form onSubmit={handleSubmit}>
                <input
                    name="booking_ref"
                    value={form.booking_ref}
                    placeholder="Booking Reference"
                    onChange={handleChange}
                />
                <input
                    name="customer_id"
                    value={form.customer_id}
                    placeholder="Customer ID"
                    onChange={handleChange}
                />
                <input
                    name="address"
                    value={form.address}
                    placeholder="Address"
                    onChange={handleChange}
                />
                <input
                    name="city"
                    value={form.city}
                    placeholder="City"
                    onChange={handleChange}
                />
                <input
                    name="room_number"
                    value={form.room_}
                    type ="number"
                    placeholder="Room Number"
                    onChange={handleChange}
                />
                <input
                    name="check_in_date"
                    type="date"
                    value={form.check_in_date}
                    onChange={handleChange}
                />
                <input
                    name="check_out_date"
                    type="date"
                    value={form.check_out_date}
                    onChange={handleChange}
                />
                <button type="submit">Book Room</button>
            </form>

            <button onClick={fetchAvailableRooms}>Fetch Available Rooms</button>
            <ul>
                {rooms.map((room) => (
                    <li key={`${room.room_number}-${room.address}-${room.city}`}>
                        Room {room.room_number} - {room.type} - {room.price}$
                    </li>
                ))}
            </ul>
        </div>
    );
}

export default BookingManager;