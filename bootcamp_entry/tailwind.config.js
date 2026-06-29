// tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./app/**/*.{js,jsx}", "./components/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: {
        credit: "#22c55e", // green-500
        debit: "#ef4444", // red-500
        primary: "#6366f1", // indigo-500
      },
    },
  },
  plugins: [],
};
