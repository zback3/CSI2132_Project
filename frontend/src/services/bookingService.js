import api from './api';

export const getBookings = async () => {
    try {
      const response = await api.get('/bookings');
      return response;
    } catch (error) {
      console.error('Error fetching bookings:', error);
      throw error;
    }
  };
export const getBooking = (booking_ref) => api.get(`/bookings/${booking_ref}`);
export const getBooking_Room = (booking_ref) => api.get(`/bookings/${booking_ref}/rooms`);
export const createBooking = async (data) => {
    try {
      const response = await api.post('/bookings', data);
      return response;
    } catch (error) {
      console.error('Error creating booking:', error);
      throw new Error(error.response?.data?.message || 'Failed to create booking');
    }
  };
  export const updateBooking = async (booking_ref, data) => {
    try {
      const response = await api.put(`/bookings/${booking_ref}`, data);
      return response;
    } catch (error) {
      console.error('Error updating booking:', error);
      throw new Error(error.response?.data?.message || 'Failed to update booking');
    }
  };
export const createBooking_Room = (booking_ref,data) => api.post(`/bookings/${booking_ref}/assign_room`, data);
