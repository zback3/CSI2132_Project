import api from './api';

export const getBookings = () => api.get('/bookings');
export const createBooking = (data) => api.post('/bookings', data);
export const updateBooking = (booking_ref, data) => api.put(`/bookings/${booking_ref}`, data);