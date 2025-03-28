import api from './api';

export const getChains = () => api.get('/chains');
export const createChain = (data) => api.post('/chains', data);
export const updateChain = (name, data) => api.put(`/chains/${name}`, data);
export const deleteChain = (name) => api.delete(`/chains/${name}`);