import {useState, useEffect} from "react";
import axios from "axios";
import {format} from "date-fns";
import './App.css';

import HotelManager from './components/hotelManager';
import ChainManager from './components/chainManager';
import EmployeeManager from './components/employeeManager';
import CustomerManager from './components/customerManager';
import RoomManager from './components/roomManager';

const baseURL = "http://localhost:5000";

function App() {

  return (
    <div className="App">
        <h1>Hotel Management System</h1>
            <ChainManager />
            <HotelManager />
            <EmployeeManager />
            <CustomerManager />
            <RoomManager />
    </div>
  );
}

export default App;
