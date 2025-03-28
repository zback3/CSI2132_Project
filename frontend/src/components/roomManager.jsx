import React, { useEffect, useState } from 'react';
import { getRooms, createRoom, updateRoom, deleteRoom } from '../services/roomService';

function RoomManager() {
    const [rooms, setRooms] = useState([]);
    const [form, setForm] = useState({
        room_number: '',
        address: '',
        city: '',
        price: '',
        capacity: '',
        mountain_view: false,
        sea_view: false,
        extendable: false,
    });

    useEffect(() => {
        fetchRooms();
    }, []);

    const fetchRooms = async () => {
        const res = await getRooms();
        setRooms(res.data);
    };

    const handleChange = (e) => {
        const { name, value, type, checked } = e.target;
        setForm({
            ...form,
            [name]: type === 'checkbox' ? checked : value,
        });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        await createRoom(form);
        fetchRooms();
        setForm({
            room_number: '',
            address: '',
            city: '',
            price: '',
            capacity: '',
            mountain_view: false,
            sea_view: false,
            extendable: false,
        });
    };

    const handleDelete = async (roomNumber, address, city) => {
        await deleteRoom(roomNumber, address, city);
        fetchRooms();
    };

    const handleUpdate = async (roomNumber, address, city) => {
        const updatedPrice = prompt("Enter new price:");
        const updatedCapacity = prompt("Enter new capacity:");
        const updatedMountainView = prompt("Mountain view? (true/false):") === 'true';
        const updatedSeaView = prompt("Sea view? (true/false):") === 'true';
        const updatedExtendable = prompt("Extendable? (true/false):") === 'true';

        if (updatedPrice && updatedCapacity) {
            await updateRoom(roomNumber, address, city, {
                price: parseFloat(updatedPrice),
                capacity: parseInt(updatedCapacity, 10),
                mountain_view: updatedMountainView,
                sea_view: updatedSeaView,
                extendable: updatedExtendable,
            });
            fetchRooms();
        }
    };

    return (
        <div>
            <h3>Edit Room Data</h3>
            <form onSubmit={handleSubmit}>
                <input
                    name="room_number"
                    value={form.room_number}
                    placeholder="Room Number"
                    type="number"
                    onChange={handleChange}
                />
                <input
                    name="address"
                    value={form.address}
                    placeholder="Hotel Address"
                    onChange={handleChange}
                />
                <input
                    name="city"
                    value={form.city}
                    placeholder="Hotel City"
                    onChange={handleChange}
                />
                <input
                    name="price"
                    value={form.price}
                    placeholder="Price"
                    type="number"
                    onChange={handleChange}
                />
                <input
                    name="capacity"
                    value={form.capacity}
                    placeholder="Capacity"
                    type="number"
                    onChange={handleChange}
                />
                <label>
                    Mountain View:
                    <input
                        name="mountain_view"
                        type="checkbox"
                        checked={form.mountain_view}
                        onChange={handleChange}
                    />
                </label>
                <label>
                    Sea View:
                    <input
                        name="sea_view"
                        type="checkbox"
                        checked={form.sea_view}
                        onChange={handleChange}
                    />
                </label>
                <label>
                    Extendable:
                    <input
                        name="extendable"
                        type="checkbox"
                        checked={form.extendable}
                        onChange={handleChange}
                    />
                </label>
                <button type="submit">Add Room</button>
            </form>

            <ul>
                {rooms.map((room) => (
                    <li key={`${room.room_number}-${room.address}-${room.city}`}>
                        Room {room.room_number} - {room.address}, {room.city} - ${room.price} - Capacity: {room.capacity} - Mountain View: {room.mountain_view ? 'Yes' : 'No'} - Sea View: {room.sea_view ? 'Yes' : 'No'} - Extendable: {room.extendable ? 'Yes' : 'No'}
                        <button onClick={() => handleUpdate(room.room_number, room.address, room.city)}>Update</button>
                        <button onClick={() => handleDelete(room.room_number, room.address, room.city)}>Delete</button>
                    </li>
                ))}
            </ul>
        </div>
    );
}

export default RoomManager;