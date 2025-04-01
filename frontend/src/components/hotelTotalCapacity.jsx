import React, { useEffect, useState } from 'react';
import { getHotelTotalCapacity } from '../services/hotelService';

function HotelTotalCapacity() {
    const [hotels, setHotels] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        fetchHotelCapacity();
    }, []);

    const fetchHotelCapacity = async () => {
        try {
            const response = await getHotelTotalCapacity();
            setHotels(response.data);
        } catch (err) {
            console.error('Error fetching hotel total capacity:', err);
            setError('Failed to load data. Please try again later.');
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return <p>Loading hotel total capacity...</p>;
    }

    if (error) {
        return <p className="error">{error}</p>;
    }

    return (
        <div style={{ textAlign: 'center', margin: '20px auto' }}>
            <h3>Hotel Total Capacity</h3>
            {hotels.length > 0 ? (
                <table style={{ margin: '0 auto', borderCollapse: 'collapse' }}>
                    <thead>
                        <tr>
                            <th style={{ padding: '10px', border: '1px solid black' }}>Address</th>
                            <th style={{ padding: '10px', border: '1px solid black' }}>City</th>
                            <th style={{ padding: '10px', border: '1px solid black' }}>Hotel Name</th>
                            <th style={{ padding: '10px', border: '1px solid black' }}>Total Capacity</th>
                            <th style={{ padding: '10px', border: '1px solid black' }}>Total Rooms</th>
                        </tr>
                    </thead>
                    <tbody>
                        {hotels.map((hotel, index) => (
                            <tr key={index}>
                                <td style={{ padding: '10px', border: '1px solid black' }}>{hotel.address}</td>
                                <td style={{ padding: '10px', border: '1px solid black' }}>{hotel.city}</td>
                                <td style={{ padding: '10px', border: '1px solid black' }}>{hotel.hotel_name}</td>
                                <td style={{ padding: '10px', border: '1px solid black' }}>{hotel.total_capacity}</td>
                                <td style={{ padding: '10px', border: '1px solid black' }}>{hotel.total_rooms}</td>
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

export default HotelTotalCapacity;
