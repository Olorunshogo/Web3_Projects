
import { ArrowUp, ArrowDown } from "lucide-react";

interface Transaction {
  id: number;
  amount: number;
  type: "Credit" | "Debit";
}

interface Props {
  transactions: Transaction[];
}

export function TransactionList({ transactions }: Props) {
  if (transactions.length === 0) {
    return (
      <p className="py-12 text-center text-gray-500">
        No transactions yet. Add one above!
      </p>
    );
  }

  return (
    <ul className="space-y-4">
      {transactions.map((tx) => (
        <li
          key={tx.id}
          className={`p-6 rounded-lg shadow flex items-center justify-between border-l-4 ${
            tx.type === "Credit"
              ? "bg-green-50 border-credit"
              : "bg-red-50 border-debit"
          }`}
        >
          <div className="flex items-center gap-4">
            {tx.type === "Credit" ? (
              <ArrowUp className="w-8 h-8 text-credit" />
            ) : (
              <ArrowDown className="w-8 h-8 text-debit" />
            )}
            <div>
              <p className="text-lg font-semibold">{tx.type}</p>
              <p className="text-2xl font-bold">
                {tx.type === "Credit" ? "+" : "-"}${tx.amount.toFixed(2)}
              </p>
            </div>
          </div>
        </li>
      ))}
    </ul>
  );
}
