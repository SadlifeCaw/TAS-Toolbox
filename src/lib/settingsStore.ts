import { create } from "zustand";

interface CustomerData {
  server: string;
  database: string;
}

interface SettingsState {
  selectedCustomer: string;
  customerData: Record<string, CustomerData>;
  setSelectedCustomer: (customer: string) => void;
}

const defaultCustomerData: Record<string, CustomerData> = {
  KundeA: { server: "10.0.0.1", database: "kundea_db" },
  KundeB: { server: "10.0.0.2", database: "kundeb_db" },
  KundeC: { server: "10.0.0.3", database: "kundec_db" },
};

export const useSettingsStore = create<SettingsState>((set) => ({
  selectedCustomer: "KundeA",
  customerData: defaultCustomerData,
  setSelectedCustomer: (customer) => set({ selectedCustomer: customer }),
}));
