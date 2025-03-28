import api from './api';

export const getEmployees = () => api.get('/employees');
export const getEmployee = (employeeId) => api.get(`/employees/${employeeId}`);
export const createEmployee = (data) => api.post('/employees', data);
export const updateEmployee = (employeeId, data) => api.put(`/employees/${employeeId}`, data);
export const deleteEmployee = (employeeId) => api.delete(`/employees/${employeeId}`);