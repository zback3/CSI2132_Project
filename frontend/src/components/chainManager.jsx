import React, { useEffect, useState } from 'react';
import { getChains, createChain, updateChain, deleteChain } from '../services/chainService';

function ChainManager() {
    const [chains, setChains] = useState([]);
    const [form, setForm] = useState({
        name: '',
        office_address: '',
    });

    useEffect(() => {
        fetchChains();
    }, []);

    const fetchChains = async () => {
        const res = await getChains();
        setChains(res.data);
    };

    const handleChange = (e) => {
        setForm({ ...form, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        await createChain(form);
        fetchChains();
        setForm({ name: '', office_address: ''});
    };

    const handleDelete = async (name) => {
        await deleteChain(name);
        fetchChains();
    };

    const handleUpdate = async (name) => {
        const updatedOfficeAddress = prompt("Enter new office address:");
        if (updatedOfficeAddress) {
            await updateChain(name, {
                office_address: updatedOfficeAddress,
            });
            fetchChains();
        }
    };

    return (
        <div>
            <h3>Edit Chain Data</h3>
            <form onSubmit={handleSubmit}>
                <input
                    name="name"
                    value={form.name}
                    placeholder="Chain Name"
                    onChange={handleChange}
                />
                <input
                    name="office_address"
                    value={form.office_address}
                    placeholder="Office Address"
                    onChange={handleChange}
                />
                <button type="submit">Add Chain</button>
            </form>

            <ul>
                {chains.map((chain) => (
                    <li key={chain.name}>
                        {chain.name} - {chain.office_address} - {chain.number_of_hotels} hotels
                        <button onClick={() => handleUpdate(chain.name)}>Update</button>
                        <button onClick={() => handleDelete(chain.name)}>Delete</button>
                    </li>
                ))}
            </ul>
        </div>
    );
}

export default ChainManager;