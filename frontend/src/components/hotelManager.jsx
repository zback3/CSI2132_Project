import React, { useEffect, useState } from 'react';
import { getHotels, createHotel, updateHotel, deleteHotel } from '../services/hotelService';
import { getHotelPhones, addHotelPhone, deleteHotelPhone } from '../services/hotelService';

function HotelManager() {
    const [hotels, setHotels] = useState([]);
    const [form, setForm] = useState({
        address: '',
        city: '',
        name: '',
        rating: '',
        email: '',
        number_rooms: '',
        manager_id: '',
    });

    const [selectedHotel, setSelectedHotel] = useState(null);
    const [phoneNumbers, setPhoneNumbers] = useState([]);
    const [newPhoneNumber, setNewPhoneNumber] = useState('');

    useEffect(() => {
        fetchHotels();
    }, []);

    const fetchHotels = async () => {
        const res = await getHotels();
        setHotels(res.data);
    };

    const fetchPhoneNumbers = async (address, city) => {
        const res = await getHotelPhones(address, city);
        setPhoneNumbers(res.data);
        setSelectedHotel({ address, city });
    };

    const handleChange = (e) => {
        setForm({ ...form, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        await createHotel(form);
        fetchHotels();
        setForm({
            address: '',
            city: '',
            name: '',
            rating: '',
            email: '',
            number_rooms: '',
            manager_id: '',
        });
    };

    const handleDelete = async (address, city) => {
        await deleteHotel(address, city);
        fetchHotels();
    };

    const handleUpdate = async (address, city) => {
        const updatedName = prompt("Enter new hotel name:");
        const updatedRating = prompt("Enter new rating:");
        const updatedEmail = prompt("Enter new email:");
        const updatedNumberRooms = prompt("Enter new number of rooms:");
        const updatedManagerId = prompt("Enter new manager ID:");

        if (updatedName && updatedRating && updatedEmail && updatedNumberRooms && updatedManagerId) {
            await updateHotel(address, city, {
                name: updatedName,
                rating: parseInt(updatedRating, 10),
                email: updatedEmail,
                number_rooms: parseInt(updatedNumberRooms, 10),
                manager_id: parseInt(updatedManagerId, 10),
            });
            fetchHotels();
        }
    };

    const handleAddPhoneNumber = async () => {
        if (selectedHotel && newPhoneNumber) {
            await addHotelPhone(selectedHotel.address, selectedHotel.city, newPhoneNumber);
            fetchPhoneNumbers(selectedHotel.address, selectedHotel.city);
            setNewPhoneNumber('');
        }
    };

    const handleDeletePhoneNumber = async (phoneNumber) => {
        if (selectedHotel) {
            await deleteHotelPhone(selectedHotel.address, selectedHotel.city, phoneNumber);
            fetchPhoneNumbers(selectedHotel.address, selectedHotel.city);
        }
    };

    return (
        <div>
            <h3>Edit Hotel Data</h3>
            <form onSubmit={handleSubmit}>
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
                    name="name"
                    value={form.name}
                    placeholder="Chain Name"
                    onChange={handleChange}
                />
                <input
                    name="rating"
                    value={form.rating}
                    placeholder="Rating"
                    type="number"
                    onChange={handleChange}
                />
                <input
                    name="email"
                    value={form.email}
                    placeholder="Email"
                    onChange={handleChange}
                />
                <input
                    name="number_rooms"
                    value={form.number_rooms}
                    placeholder="Number of Rooms"
                    type="number"
                    onChange={handleChange}
                />
                <input
                    name="manager_id"
                    value={form.manager_id}
                    placeholder="Manager ID"
                    type="number"
                    onChange={handleChange}
                />
                <button type="submit">Add Hotel</button>
            </form>

            <ul>
                {hotels.map((hotel) => (
                    <li key={`${hotel.address}-${hotel.city}`}>
                        {hotel.address}, {hotel.city} - {hotel.name} - {hotel.email} - {hotel.rating} stars - {hotel.number_rooms} rooms
                        <button onClick={() => handleUpdate(hotel.address, hotel.city)}>Update</button>
                        <button onClick={() => handleDelete(hotel.address, hotel.city)}>Delete</button>
                        <button onClick={() => fetchPhoneNumbers(hotel.address, hotel.city)}>Manage Phones</button>
                    </li>
                ))}
            </ul>

            {selectedHotel && (
                <div>
                    <h4>Phone Numbers for {selectedHotel.address}, {selectedHotel.city}</h4>
                    <ul>
                        {phoneNumbers.map((phone) => (
                            <li key={phone}>
                                {phone}
                                <button onClick={() => handleDeletePhoneNumber(phone)}>Delete</button>
                            </li>
                        ))}
                    </ul>
                    <input
                        value={newPhoneNumber}
                        placeholder="New Phone Number"
                        onChange={(e) => setNewPhoneNumber(e.target.value)}
                    />
                    <button onClick={handleAddPhoneNumber}>Add Phone Number</button>
                </div>
            )}

        </div>
    );
}

export default HotelManager;