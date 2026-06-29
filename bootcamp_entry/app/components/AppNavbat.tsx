
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Wallet, Timer, Home, type LucideIcon } from "lucide-react";

interface NavItem {
  href: string;
  label: string;
  icon: LucideIcon;
}

const navItems: NavItem[] = [
  { href: "/", label: "Home", icon: Home },
  { href: "/transaction-filter", label: "Section A", icon: Wallet },
  { href: "/launch-timer", label: "Section B", icon: Timer },
];

export default function AppNavbar() {
  const pathname = usePathname();

  return (
    <nav className="bg-white border-b border-gray-200 shadow-md">
      <div className="container flex items-center justify-between max-w-5xl px-4 py-4 mx-auto">
        <Link href="/" className="text-xl font-bold text-primary">
          BlockheaderWeb3 Assessment
        </Link>

        <ul className="flex gap-8">
          {navItems.map(({ href, label, icon: Icon }) => (
            <li key={href}>
              <Link
                href={href}
                className={`flex items-center gap-2 px-3 py-2 rounded-md transition-colors ${
                  pathname === href
                    ? "bg-primary text-white"
                    : "text-gray-700 hover:bg-gray-100"
                }`}
              >
                <Icon className="w-5 h-5" />
                {label}
              </Link>
            </li>
          ))}
        </ul>
      </div>
    </nav>
  );
}
