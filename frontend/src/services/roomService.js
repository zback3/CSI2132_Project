import api from './api';

export const getRooms = () => api.get('/rooms');
export const getRoom = (roomNumber, address, city) => api.get(`/rooms/${roomNumber}/${address}/${city}`);
export const createRoom = (data) => api.post('/rooms', data);
export const updateRoom = (roomNumber, address, city, data) => api.put(`/rooms/${roomNumber}/${address}/${city}`, data);
export const deleteRoom = (roomNumber, address, city) => api.delete(`/rooms/${roomNumber}/${address}/${city}`);