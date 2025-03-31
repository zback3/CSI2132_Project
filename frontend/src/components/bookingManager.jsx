import React, { useState, useEffect } from 'react';
import { getBookings, createBooking, updateBooking, createBooking_Room, getBooking_Room } from '../services/bookingService';
import { getRooms } from '../services/roomService';
import { getCustomers } from '../services/customerService';

//TODO: For some reason the customer's name seems to be passed as the customer_id when creating a booking which is preventing the booking from being created.
//TODO: Change the way the booking_ref is generated to use a short unique ID instead of Date.now().
const BookingManager = () => {
    // State management
    const [bookings, setBookings] = useState([]);
    const [allRooms, setAllRooms] = useState([]);
    const [loading, setLoading] = useState(true); // Loading state
    const [availableRooms, setAvailableRooms] = useState([]);
    const [customers, setCustomers] = useState([]);
    const [formData, setFormData] = useState({
        start_date: '',
        end_date: '',
        total_price: '',
        customer_id: 0,
    });
    const [selectedRooms, setSelectedRooms] = useState([]);
    const [editing, setEditing] = useState(false);
    const [errors, setErrors] = useState({});
    const [filters, setFilters] = useState({
        minPrice: '',
        maxPrice: '',
        capacity: '',
        view: ''
    });
    const [currentBookingRef, setCurrentBookingRef] = useState(null);

    
    // Fetch initial data
    useEffect(() => {
        fetchData();
    }, []);

    // Filter available rooms when dates or filters change
    useEffect(() => {
        if (formData.start_date && formData.end_date) {
            filterAvailableRooms();
        }
    }, [formData.start_date, formData.end_date, filters]);

    // Calculate total price when dates or selected rooms change
    useEffect(() => {
        setFormData(prev => ({
            ...prev,
            total_price: calculateTotalPrice()
        }));
    }, [selectedRooms, formData.start_date, formData.end_date]);

    const fetchData = async () => {
        try {
          setLoading(true);  // Set loading to true when starting fetch
          const [bookingsRes, roomsRes, customersRes] = await Promise.all([
            getBookings(),
            getRooms(),
            getCustomers()
          ]);
          setBookings(bookingsRes?.data || []);
          setAllRooms(roomsRes?.data || []);
          setCustomers(customersRes?.data || []);
        } catch (error) {
          console.error("Error fetching data:", error);
        } finally {
          setLoading(false);  // Set loading to false when done (whether success or error)
        }
      };

      const filterAvailableRooms = () => {
        // Return early if required data isn't loaded
        if (!bookings || !allRooms || !formData.start_date || !formData.end_date) {
          setAvailableRooms([]);
          return;
        }
      
        // Safely get booked room keys with null checks at every level
        const bookedRoomKeys = bookings
          .filter(booking => 
            booking && 
            booking.rooms && 
            booking.start_date && 
            booking.end_date &&
            new Date(booking.end_date) >= new Date(formData.start_date) &&
            new Date(booking.start_date) <= new Date(formData.end_date)
          )
          .flatMap(booking => 
            Array.isArray(booking.rooms) 
              ? booking.rooms.map(room => 
                  room && room.room_number && room.address && room.city
                    ? `${room.room_number}-${room.address}-${room.city}`
                    : ''
                ).filter(Boolean)
              : []
          );
      
        // Filter rooms with all necessary checks
        const filtered = allRooms
          .filter(room => 
            room && 
            room.room_number && 
            room.address && 
            room.city &&
            !bookedRoomKeys.includes(`${room.room_number}-${room.address}-${room.city}`)
          );
      
        // Apply additional filters if they exist
        const result = filtered.filter(room => {
          if (filters.minPrice && room.price < Number(filters.minPrice)) return false;
          if (filters.maxPrice && room.price > Number(filters.maxPrice)) return false;
          if (filters.capacity && room.capacity < Number(filters.capacity)) return false;
          if (filters.view === 'mountain' && !room.mountain_view) return false;
          if (filters.view === 'sea' && !room.sea_view) return false;
          return true;
        });
      
        setAvailableRooms(result);
      };

    const handleFilterChange = (e) => {
        setFilters({
            ...filters,
            [e.target.name]: e.target.value
        });
    };

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
    };

    const handleRoomSelection = (room) => {
        setSelectedRooms(prev => {
            const isSelected = prev.some(r =>
                r.room_number === room.room_number &&
                r.address === room.address &&
                r.city === room.city
            );

            if (isSelected) {
                return prev.filter(r =>
                    !(r.room_number === room.room_number &&
                        r.address === room.address &&
                        r.city === room.city)
                );
            } else {
                return [...prev, room];
            }
        });
    };

    const validateForm = () => {
        const newErrors = {};
        
        if (!formData.start_date) newErrors.start_date = 'Start date is required';
        if (!formData.end_date) newErrors.end_date = 'End date is required';
        
        if (formData.start_date && formData.end_date) {
          if (new Date(formData.end_date) <= new Date(formData.start_date)) {
            newErrors.end_date = 'End date must be after start date';
          }
        }
        
        if (!formData.customer_id) newErrors.customer_id = 'Customer is required';
        if (selectedRooms.length === 0) newErrors.rooms = 'At least one room is required';
        if (selectedRooms.length > 10) newErrors.rooms = 'Maximum 10 rooms per booking';
        
        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
      };

    const calculateTotalPrice = () => {
        if (selectedRooms.length === 0 || !formData.start_date || !formData.end_date) return 0;

        const days = Math.ceil(
            (new Date(formData.end_date) - new Date(formData.start_date)) / (1000 * 60 * 60 * 24)
        );

        return selectedRooms.reduce((total, room) => total + (room.price * days), 0);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        
        // Validate form
        if (!validateForm()) return;
      
        try {
          // Calculate days and validate duration
          const days = Math.ceil(
            (new Date(formData.end_date) - new Date(formData.start_date)) / 
            (1000 * 60 * 60 * 24)
          );
          
          if (days > 14) {
            alert('Maximum stay duration is 14 days');
            return;
          }
          let booking_ref = Date.now();
          // Prepare booking data
          const bookingData = {
            booking_ref,
            start_date: formData.start_date,
            end_date: formData.end_date,
            customer_id: formData.customer_id,
            total_price: calculateTotalPrice()
          };

            // Prepare room data
            const roomData = selectedRooms.map(room => ({
                booking_ref,
                room_number: room.room_number,
                address: room.address,
                city: room.city
            }));
      
          // Submit booking
          let response;
          let responseRoom;
          if (editing) {
            response = await updateBooking(booking_ref, bookingData);
          } else {
            response = await createBooking(bookingData);
          }
          //Submit room data
          if (editing) {
            responseRoom = await createBooking_Room(currentBookingRef, roomData);
          } else {
            responseRoom = await createBooking_Room(response.data.booking_ref, roomData);
          }
      
          // Check for successful response
          if (response && response.data && responseRoom && responseRoom.data) {
            resetForm();
            fetchData();
            alert(editing ? 'Booking updated successfully!' : 'Booking created successfully!');
          } else {
            throw new Error('Invalid response from server');
          }
        } catch (error) {
          console.error("Booking error:", error);
          alert(`Failed to save booking: ${error.message || 'Please try again'}`);
        }
      };

    const handleEdit = (booking) => {
        setFormData({
            start_date: booking.start_date,
            end_date: booking.end_date,
            total_price: booking.total_price,
            customer_id: booking.customer_id,
        });
        setSelectedRooms(booking.rooms || []);
        setCurrentBookingRef(booking.booking_ref);
        setEditing(true);
    };

    const resetForm = () => {
        setFormData({
            start_date: '',
            end_date: '',
            total_price: '',
            customer_id: '',
        });
        setSelectedRooms([]);
        setEditing(false);
        setCurrentBookingRef(null);
        setFilters({
            minPrice: '',
            maxPrice: '',
            capacity: '',
            view: ''
        });
    };

    return (
        <div className="booking-manager">
            {loading ? (
                <div className="loading-state">
                <div className="spinner"></div>
                <p>Loading booking data...</p>
            </div>
            ) : (
                <>
                    <h3>{editing ? `Edit Booking #${currentBookingRef}` : 'Create New Booking'}</h3>

                    <form onSubmit={handleSubmit}>
                        <div className="form-group">
                            <label>Start Date:</label>
                            <input
                                type="date"
                                name="start_date"
                                value={formData.start_date}
                                onChange={handleChange}
                                min={new Date().toISOString().split('T')[0]}
                            />
                            {errors.start_date && <span className="error">{errors.start_date}</span>}
                        </div>

                        <div className="form-group">
                            <label>End Date:</label>
                            <input
                                type="date"
                                name="end_date"
                                value={formData.end_date}
                                onChange={handleChange}
                                min={formData.start_date || new Date().toISOString().split('T')[0]}
                            />
                            {errors.end_date && <span className="error">{errors.end_date}</span>}
                        </div>

                        <div className="form-group">
                            <label>Customer:</label>
                            <select
                                name="customer_id"
                                value={formData.customer_id}
                                onChange={handleChange}
                            >
                                <option value="">Select Customer</option>
                                {customers.map(customer => (
                                    <option key={customer.customer_ID} value={customer.customer_ID}>
                                        {/* TODO: This might be causing the issue with the customer_id being passed as the name */}
                                        {customer.first_name} {customer.last_name}
                                    </option>
                                ))}
                            </select>
                            {errors.customer_id && <span className="error">{errors.customer_id}</span>}
                        </div>

                        <div className="form-group">
                            <label>Total Price:</label>
                            <input
                                type="text"
                                name="total_price"
                                value={`$${formData.total_price.toLocaleString()}`}
                                readOnly
                            />
                        </div>

                        <div className="form-group">
                            <label>Room Filters:</label>
                            <div className="filter-controls">
                                <input
                                    type="number"
                                    name="minPrice"
                                    placeholder="Min price"
                                    value={filters.minPrice}
                                    onChange={handleFilterChange}
                                    min="0"
                                />
                                <input
                                    type="number"
                                    name="maxPrice"
                                    placeholder="Max price"
                                    value={filters.maxPrice}
                                    onChange={handleFilterChange}
                                    min="0"
                                />
                                <input
                                    type="number"
                                    name="capacity"
                                    placeholder="Min capacity"
                                    value={filters.capacity}
                                    onChange={handleFilterChange}
                                    min="1"
                                />
                                <select
                                    name="view"
                                    value={filters.view}
                                    onChange={handleFilterChange}
                                >
                                    <option value="">Any view</option>
                                    <option value="mountain">Mountain view</option>
                                    <option value="sea">Sea view</option>
                                </select>
                            </div>
                        </div>

                        <div className="form-group">
                            <label>Available Rooms:</label>
                            {errors.rooms && <span className="error">{errors.rooms}</span>}
                            <div className="room-grid">
                                {availableRooms.length > 0 ? (
                                    availableRooms.map(room => (
                                        <div
                                            key={`${room.room_number}-${room.address}-${room.city}`}
                                            className={`room-card ${selectedRooms.some(r =>
                                                r.room_number === room.room_number &&
                                                r.address === room.address &&
                                                r.city === room.city
                                            ) ? 'selected' : ''}`}
                                            onClick={() => handleRoomSelection(room)}
                                        >
                                            <h4>Room #{room.room_number}</h4>
                                            <p>{room.address}, {room.city}</p>
                                            <p>${room.price}/night</p>
                                            <p>Capacity: {room.capacity}</p>
                                            <p>
                                                {room.mountain_view && "🏔️ "}
                                                {room.sea_view && "🌊 "}
                                                {!room.mountain_view && !room.sea_view && "No special view"}
                                            </p>
                                        </div>
                                    ))
                                ) : (
                                    <p>No rooms available for the selected dates/filters</p>
                                )}
                            </div>
                        </div>

                        <div className="selected-rooms">
                            <h3>Selected Rooms ({selectedRooms.length})</h3>
                            {selectedRooms.length > 0 ? (
                                <ul>
                                    {selectedRooms.map(room => (
                                        <li key={`${room.room_number}-${room.address}-${room.city}`}>
                                            Room #{room.room_number} - {room.address}, {room.city} - ${room.price}/night
                                            <button
                                                type="button"
                                                className="remove-room"
                                                onClick={() => handleRoomSelection(room)}
                                            >
                                                ×
                                            </button>
                                        </li>
                                    ))}
                                </ul>
                            ) : (
                                <p>No rooms selected</p>
                            )}
                        </div>

                        <div className="form-actions">
                            <button type="submit" className="primary">
                                {editing ? 'Update Booking' : 'Create Booking'}
                            </button>
                            {editing && (
                                <button type="button" onClick={resetForm} className="secondary">
                                    Cancel
                                </button>
                            )}
                        </div>
                    </form>


                    <h3>Existing Bookings</h3>
                    <div className="bookings-list">
                        {bookings && Array.isArray(bookings) ? (
                            bookings.length > 0 ? (
                                bookings.map(booking => (
                                    booking && (
                                        <div key={booking.booking_ref || Math.random()} className="booking-card">
                                            <h4>Booking Ref: {booking.booking_ref || 'N/A'}</h4>
                                            <p>
                                                Customer: {
                                                    customers.find(c => c.customer_ID === booking.customer_id)?.first_name ||
                                                    booking.customer_id ||
                                                    'Unknown'
                                                }
                                            </p>
                                            <p>
                                                Dates: {booking.start_date ? new Date(booking.start_date).toLocaleDateString() : 'N/A'}
                                                {' to '}
                                                {booking.end_date ? new Date(booking.end_date).toLocaleDateString() : 'N/A'}
                                            </p>
                                            <p>Total: ${booking.total_price || 0}</p>
                                            <p>Rooms: {booking.rooms ? booking.rooms.length : 0}</p>
                                            <button onClick={() => booking.booking_ref && handleEdit(booking)}>
                                                Edit
                                            </button>
                                        </div>
                                    )
                                ))
                            ) : (
                                <p className="no-bookings">No bookings found</p>
                            )
                        ) : (
                            <p className="error-message">Failed to load bookings</p>
                        )}
                    </div>
                </>
            )}
        </div>
    );
};

export default BookingManager;