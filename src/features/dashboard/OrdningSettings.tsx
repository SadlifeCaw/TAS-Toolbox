import React from 'react';
import { useSettingsStore } from '@/lib/settingsStore';

const OrdningSettings: React.FC = () => {
  const {
    selectedCustomer,
    customerData,
    setSelectedCustomer,
  } = useSettingsStore();

  const server = customerData[selectedCustomer].server;
  const database = customerData[selectedCustomer].database;
  const customers = Object.keys(customerData);

  return (
    <div className="grid grid-cols-1 md:grid-cols-[1fr_auto_1fr] gap-6">
      {/* Ordning Section */}
      <div className="pr-6">
        <div className="form-control mb-4">
          <label className="label text-sm font-medium text-gray-700">Ordning</label>
          <input type="text" placeholder="Bygningspuljen" className="input input-bordered w-full" />
        </div>
        <div className="form-control mb-4">
          <label className="label text-sm font-medium text-gray-700">Kortform</label>
          <input type="text" placeholder="BNP" className="input input-bordered w-full" />
        </div>
        <div className="form-control">
          <label className="label text-sm font-medium text-gray-700">Regelsæt</label>
          <input type="text" placeholder="Pulje 2024" className="input input-bordered w-full" />
        </div>
      </div>

      {/* Divider */}
      <div className="divider"></div>

      {/* Customer Section */}
      <div className="pl-6">
        <div className="form-control mb-4">
          <label className="label text-sm font-medium text-gray-700">Kunde</label>
          <select
            className="select select-bordered w-full"
            value={selectedCustomer}
            onChange={(e) => setSelectedCustomer(e.target.value)}
          >
            {customers.map((cust) => (
              <option key={cust} value={cust}>{cust}</option>
            ))}
          </select>
        </div>
        <div className="form-control mb-4">
          <label className="label text-sm font-medium text-gray-700">Server</label>
          <input
            type="text"
            className="input input-bordered bg-gray-100 cursor-not-allowed"
            value={server}
            readOnly
          />
        </div>
        <div className="form-control">
          <label className="label text-sm font-medium text-gray-700">Database</label>
          <input
            type="text"
            className="input input-bordered bg-gray-100 cursor-not-allowed"
            value={database}
            readOnly
          />
        </div>
      </div>
    </div>
  );
};

export default OrdningSettings;
