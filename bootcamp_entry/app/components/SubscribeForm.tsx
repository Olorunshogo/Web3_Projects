
"use client";

import { useState } from "react";

export function SubscribeForm() {
  const [email, setEmail] = useState<string>("");

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (email.trim()) {
      console.log("Subscribed email:", email);
      setEmail("");
    }
  };

  return (
    <form onSubmit={handleSubmit} className="max-w-md mx-auto">
      <label className="block mb-3 text-lg font-medium">
        Subscribe for launch updates
      </label>
      <div className="flex gap-3">
        <input
          type="email"
          placeholder="your@email.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          className="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
        />
        <button
          type="submit"
          className="px-6 py-3 text-white transition-colors rounded-lg bg-primary hover:bg-indigo-600"
        >
          Subscribe
        </button>
      </div>
    </form>
  );
}
