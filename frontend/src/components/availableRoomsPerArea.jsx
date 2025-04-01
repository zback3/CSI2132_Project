import React, { useEffect, useState } from 'react';
import { getAvailableRoomsPerArea } from '../services/hotelService';

function AvailableRoomsPerArea() {
    const [rooms, setRooms] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);


    useEffect(() => {
        fetchAvailableRooms();
    }, []);


    const fetchAvailableRooms = async () => {
        try {
            const response = await getAvailableRoomsPerArea();
            setRooms(response.data);
        } catch (err) {
            console.error('Error fetching available rooms per area:', err);
            setError('Failed to load data. Please try again later.');
        } finally {
            setLoading(false);
        }
    };


    if (loading) {
        return <p>Loading available rooms per area...</p>;
    }


    if (error) {
        return <p className="error">{error}</p>;
    }


    return (
        <div style={{ textAlign: 'center', margin: '20px auto' }}>
            {rooms.length > 0 ? (
                <table style={{ margin: '0 auto', borderCollapse: 'collapse' }}>
                    <thead>
                        <tr>
                            <th style={{ padding: '10px', border: '1px solid black' }}>City</th>
                            <th style={{ padding: '10px', border: '1px solid black' }}>Available Rooms</th>
                        </tr>
                    </thead>
                    <tbody>
                        {rooms.map((room, index) => (
                            <tr key={index}>
                                <td style={{ padding: '10px', border: '1px solid black' }}>{room.city}</td>
                                <td style={{ padding: '10px', border: '1px solid black' }}>{room.available_rooms}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            ) : (
                <p>No data available.</p>
            )}
        </div>
    );
}


export default AvailableRoomsPerArea;

