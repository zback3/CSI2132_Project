import api from './api';

export const getHotels = () => api.get('/hotels');
export const getHotel = (address, city) => api.get(`/hotels/${address}/${city}`);
export const createHotel = (data) => api.post('/hotels', data);
export const updateHotel = (address, city, data) => api.put(`/hotels/${address}/${city}`, data);
export const deleteHotel = (address, city) => api.delete(`/hotels/${address}/${city}`);

export const getHotelPhones = (address, city) => api.get(`/hotels/${address}/${city}/phones`);
export const addHotelPhone = (address, city, phoneNumber) =>
    api.post(`/hotels/${address}/${city}/phones`, { phone_number: phoneNumber });
export const deleteHotelPhone = (address, city, phoneNumber) =>
    api.delete(`/hotels/${address}/${city}/phones/${phoneNumber}`);
export const getAvailableRoomsCity = (city) =>
    api.get((`/available_rooms_city/${city}`));