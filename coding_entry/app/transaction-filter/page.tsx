
"use client";

import { useState } from "react";
import { TransactionForm } from "../components/TransactionForm";
import { FilterButtons } from "../components/FilterButtons";
import { TransactionList } from "../components/TransactionList";

interface Transaction {
  id: number;
  amount: number;
  type: "Credit" | "Debit";
}

export default function TransactionFilter() {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [filter, setFilter] = useState<"all" | "credit" | "debit">("all");

  // Net balance calculated from ALL transactions (overall balance)
  const netBalance = transactions.reduce((acc, t) => {
    return t.type === "Credit" ? acc + t.amount : acc - t.amount;
  }, 0);

  // Filtered & sorted list (highest → lowest amount)
  const filteredTransactions = transactions.filter(
    (t) => filter === "all" || t.type.toLowerCase() === filter
  );

  const sortedTransactions = [...filteredTransactions].sort(
    (a, b) => b.amount - a.amount
  );

  return (
    <>
      <h1 className="mb-8 text-3xl font-bold text-center md:text-4xl">
        Transaction Filter & Sorter
      </h1>

      <div className="p-6 mb-8 bg-white shadow-lg rounded-xl md:p-8">
        <TransactionForm setTransactions={setTransactions} />

        <div className="flex flex-col items-center justify-between gap-6 mt-8 sm:flex-row">
          <FilterButtons filter={filter} setFilter={setFilter} />

          <div className="text-2xl font-bold">
            Net Balance:{" "}
            <span className={netBalance >= 0 ? "text-credit" : "text-debit"}>
              ${netBalance.toFixed(2)}
            </span>
          </div>
        </div>
      </div>

      <TransactionList transactions={sortedTransactions} />
    </>
  );
}
