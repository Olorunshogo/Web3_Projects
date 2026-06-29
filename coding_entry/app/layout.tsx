import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import AppNavbar from "./components/AppNavbat";
import AppFooter from "./components/AppFooter";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "BlockheaderWeb3 Cohort 8 Assessment",
  description: "Transaction Filter & Sorter + Token Launch Countdown",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`flex min-h-screen flex-col ${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        {/* <AppNavbar /> */}
        <main className="container flex-1 max-w-5xl px-4 py-8 mx-auto">
          {children}
        </main>
        {/* <AppFooter /> */}
      </body>
    </html>
  );
}
