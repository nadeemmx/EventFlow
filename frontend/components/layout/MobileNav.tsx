"use client"

import Link from "next/link"
import { usePathname } from "next/navigation"
import {
  LayoutDashboard,
  CalendarCheck,
  Users,
  CreditCard,
  MoreHorizontal,
} from "lucide-react"

import { cn } from "@/lib/utils"

const navItems = [
  { label: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { label: "Bookings", href: "/bookings", icon: CalendarCheck },
  { label: "Customers", href: "/customers", icon: Users },
  { label: "Payments", href: "/payments", icon: CreditCard },
  { label: "More", href: "/more", icon: MoreHorizontal },
] as const

export function MobileNav() {
  const pathname = usePathname()

  return (
    <nav
      aria-label="Mobile"
      className="md:hidden fixed bottom-0 inset-x-0 z-40 bg-background border-t border-border"
    >
      <div className="flex items-center justify-around h-16 px-2">
        {navItems.map((item) => {
          const isActive =
            pathname === item.href || pathname.startsWith(item.href + "/")
          const Icon = item.icon
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex flex-col items-center gap-1 px-3 py-1.5 rounded-lg transition-colors min-w-0",
                isActive
                  ? "text-amber-600"
                  : "text-muted-foreground hover:text-foreground"
              )}
            >
              <Icon aria-hidden="true" focusable="false" className="h-5 w-5 shrink-0" />
              <span className="text-[10px] font-medium truncate w-full text-center">
                {item.label}
              </span>
            </Link>
          )
        })}
      </div>
    </nav>
  )
}
