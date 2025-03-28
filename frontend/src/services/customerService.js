import api from './api';

export const getCustomers = () => api.get('/customers');
export const getCustomer = (customerId) => api.get(`/customers/${customerId}`);
export const createCustomer = (data) => api.post('/customers', data);
export const updateCustomer = (customerId, data) => api.put(`/customers/${customerId}`, data);
export const deleteCustomer = (customerId) => api.delete(`/customers/${customerId}`);