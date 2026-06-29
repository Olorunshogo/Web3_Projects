
"use client";

import { useState, Dispatch, SetStateAction } from "react";
import { Plus } from "lucide-react";

interface Transaction {
  id: number;
  amount: number;
  type: "Credit" | "Debit";
}

interface Props {
  setTransactions: Dispatch<SetStateAction<Transaction[]>>;
}

export function TransactionForm({ setTransactions }: Props) {
  const [amount, setAmount] = useState<string>("");
  const [type, setType] = useState<"Credit" | "Debit">("Credit");

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const numAmount = parseFloat(amount);
    if (isNaN(numAmount) || numAmount <= 0) return;

    const newTx: Transaction = {
      id: Date.now(),
      amount: numAmount,
      type,
    };

    setTransactions((prev) => [...prev, newTx]);
    setAmount("");
  };

  return (
    <form onSubmit={handleSubmit} className="grid gap-4 md:grid-cols-3">
      <input
        type="number"
        step="0.01"
        min="0"
        placeholder="Amount"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
        required
        className="px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
      />

      <select
        value={type}
        onChange={(e) => setType(e.target.value as "Credit" | "Debit")}
        className="px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
      >
        <option value="Credit">Credit</option>
        <option value="Debit">Debit</option>
      </select>

      <button
        type="submit"
        className="flex items-center justify-center gap-2 px-6 py-3 text-white transition-colors rounded-lg bg-primary hover:bg-indigo-600"
      >
        <Plus className="w-5 h-5" />
        Add Transaction
      </button>
    </form>
  );
}
