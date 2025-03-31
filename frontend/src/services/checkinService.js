import api from './api';

export const createNewRenting = (data) => api.post('/check_in/new_renting', data);
export const createRentingFromBooking = (bookingRef, data) => api.post(`/check_in/from_booking/${bookingRef}`, data);