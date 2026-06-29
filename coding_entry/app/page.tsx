
// export default function Home() {
//   return (
//     <div className="flex items-center justify-center min-h-screen font-sans bg-zinc-50 dark:bg-black">
//       <main className="flex flex-col items-center justify-between w-full max-w-3xl min-h-screen px-16 py-32 bg-white dark:bg-black sm:items-start">
//         <Image
//           className="dark:invert"
//           src="/next.svg"
//           alt="Next.js logo"
//           width={100}
//           height={20}
//           priority
//         />
//         <div className="flex flex-col items-center gap-6 text-center sm:items-start sm:text-left">
//           <h1 className="max-w-xs text-3xl font-semibold leading-10 tracking-tight text-black dark:text-zinc-50">
//             To get started, edit the page.tsx file.
//           </h1>
//           <p className="max-w-md text-lg leading-8 text-zinc-600 dark:text-zinc-400">
//             Looking for a starting point or more instructions? Head over to{" "}
//             <a
//               href="https://vercel.com/templates?framework=next.js&utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
//               className="font-medium text-zinc-950 dark:text-zinc-50"
//             >
//               Templates
//             </a>{" "}
//             or the{" "}
//             <a
//               href="https://nextjs.org/learn?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
//               className="font-medium text-zinc-950 dark:text-zinc-50"
//             >
//               Learning
//             </a>{" "}
//             center.
//           </p>
//         </div>
//         <div className="flex flex-col gap-4 text-base font-medium sm:flex-row">
//           <a
//             className="flex h-12 w-full items-center justify-center gap-2 rounded-full bg-foreground px-5 text-background transition-colors hover:bg-[#383838] dark:hover:bg-[#ccc] md:w-[158px]"
//             href="https://vercel.com/new?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
//             target="_blank"
//             rel="noopener noreferrer"
//           >
//             <Image
//               className="dark:invert"
//               src="/vercel.svg"
//               alt="Vercel logomark"
//               width={16}
//               height={16}
//             />
//             Deploy Now
//           </a>
//           <a
//             className="flex h-12 w-full items-center justify-center rounded-full border border-solid border-black/[.08] px-5 transition-colors hover:border-transparent hover:bg-black/[.04] dark:border-white/[.145] dark:hover:bg-[#1a1a1a] md:w-[158px]"
//             href="https://nextjs.org/docs?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
//             target="_blank"
//             rel="noopener noreferrer"
//           >
//             Documentation
//           </a>
//         </div>
//       </main>
//     </div>
//   );
// }

import Link from "next/link";
import { Wallet, Timer } from "lucide-react";

export default function HomePage() {
  return (
    <>
      <section className="py-16 text-center">
        <h1 className="mb-6 text-4xl font-bold md:text-5xl">
          BlockheaderWeb3 Cohort 8 Coding Assessment
        </h1>
        <p className="max-w-2xl mx-auto text-xl text-gray-600">
          Two production-ready frontend challenges built with Next.js, Tailwind
          CSS, and lucide-react icons.
        </p>
      </section>

      <div className="grid gap-8 mt-12 md:grid-cols-2">
        <Link
          href="/transaction-filter"
          className="block p-8 transition-shadow bg-white border border-gray-200 shadow-lg rounded-xl hover:shadow-xl"
        >
          <Wallet className="w-12 h-12 mb-4 text-credit" />
          <h2 className="mb-3 text-2xl font-semibold">
            Section A: Transaction Filter & Sorter
          </h2>
          <p className="text-gray-600">
            Add transactions, filter by type, view net balance, sorted by amount
            with color coding.
          </p>
        </Link>

        <Link
          href="/launch-timer"
          className="block p-8 transition-shadow bg-white border border-gray-200 shadow-lg rounded-xl hover:shadow-xl"
        >
          <Timer className="w-12 h-12 mb-4 text-primary" />
          <h2 className="mb-3 text-2xl font-semibold">
            Section B: Token Launch Countdown
          </h2>
          <p className="text-gray-600">
            Live countdown with customizable date, progress bar, and email
            subscription form.
          </p>
        </Link>
      </div>
    </>
  );
}
