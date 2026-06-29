
import { Filter } from "lucide-react";
import { Dispatch, SetStateAction } from "react";

interface Props {
  filter: "all" | "credit" | "debit";
  setFilter: Dispatch<SetStateAction<"all" | "credit" | "debit">>;
}

export function FilterButtons({ filter, setFilter }: Props) {
  const buttons = [
    { key: "all", label: "Show All" },
    { key: "credit", label: "Show Credits" },
    { key: "debit", label: "Show Debits" },
  ] as const;

  return (
    <div className="flex items-center gap-3">
      <Filter className="w-5 h-5 text-gray-600" />
      {buttons.map(({ key, label }) => (
        <button
          key={key}
          onClick={() => setFilter(key)}
          className={`px-5 py-2 rounded-md transition-colors ${
            filter === key
              ? "bg-primary text-white"
              : "bg-gray-200 hover:bg-gray-300"
          }`}
        >
          {label}
        </button>
      ))}
    </div>
  );
}
