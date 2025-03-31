import {useState, useEffect} from "react";
import axios from "axios";
import {format} from "date-fns";
import './App.css';

import HotelManager from './components/hotelManager';
import ChainManager from './components/chainManager';
import EmployeeManager from './components/employeeManager';
import CustomerManager from './components/customerManager';
import RoomManager from './components/roomManager';
import BookingManager from "./components/bookingManager";
import CheckinManager from "./components/checkinManager";

const baseURL = "http://localhost:5000";

function App() {

  return (
    <div className="App">
        <h1>eHotels Web App: CSI2132 Term Project</h1>
        <h2>Booking System</h2>
            <BookingManager />
        <h2>Hotel Management System</h2>
            <CheckinManager />
            <ChainManager />
            <HotelManager />
            <EmployeeManager />
            <CustomerManager />
            <RoomManager />
            
    </div>
  );
}

export default App;
