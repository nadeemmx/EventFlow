"use client"

import Link from "next/link"
import { usePathname, useRouter } from "next/navigation"
import {
  LayoutDashboard,
  CalendarCheck,
  Users,
  Target,
  Building2,
  CreditCard,
  FileText,
  BarChart3,
  Settings,
  LogOut,
  X,
  Building,
  UserCog,
  DollarSign,
  Shield,
} from "lucide-react"

import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Separator } from "@/components/ui/separator"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Sheet, SheetContent, SheetClose } from "@/components/ui/sheet"
import { useAuth } from "@/stores/auth-context"

interface NavItem {
  label: string
  href: string
  icon: React.ElementType
  roles?: string[]
}

const venueOwnerNavItems: NavItem[] = [
  { label: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { label: "Bookings", href: "/bookings", icon: CalendarCheck },
  { label: "Customers", href: "/customers", icon: Users },
  { label: "Leads", href: "/leads", icon: Target },
  { label: "Venues", href: "/venues", icon: Building2 },
  { label: "Payments", href: "/payments", icon: CreditCard },
  { label: "Invoices", href: "/invoices", icon: FileText },
  { label: "Reports", href: "/reports", icon: BarChart3 },
  { label: "Settings", href: "/settings", icon: Settings },
] as const

const platformAdminNavItems: NavItem[] = [
  { label: "Platform Overview", href: "/admin", icon: LayoutDashboard },
  { label: "Venue Owners", href: "/admin/tenants", icon: Users },
  { label: "All Venues", href: "/admin/venues", icon: Building },
  { label: "Subscription Plans", href: "/subscriptions", icon: DollarSign },
  { label: "Platform Reports", href: "/reports", icon: BarChart3 },
  { label: "Audit Logs", href: "/audit-logs", icon: FileText },
  { label: "Platform Settings", href: "/settings", icon: Shield },
] as const

interface AppSidebarProps {
  open?: boolean
  onClose?: () => void
}

function SidebarContent({ pathname, onLinkClick }: { pathname: string; onLinkClick?: () => void }) {
  const { user, logout } = useAuth()
  const router = useRouter()

  const isPlatformAdmin = user?.role === "SUPER_ADMIN"
  const navItems = isPlatformAdmin ? platformAdminNavItems : venueOwnerNavItems

  const initials = user?.full_name
    ? user.full_name.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2)
    : "U"

  return (
    <>
      <div className="flex items-center justify-between h-16 px-6 shrink-0">
        <div className="flex items-center gap-2.5">
          <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-amber-500 text-slate-900 font-bold text-sm">
            EF
          </div>
          <span className="font-semibold text-lg tracking-tight">EventFlow</span>
          {isPlatformAdmin && (
            <span className="text-xs font-medium px-2 py-0.5 rounded bg-amber-500/10 text-amber-700">
              Platform Admin
            </span>
          )}
        </div>
        {onLinkClick && (
          <SheetClose asChild>
            <Button
              variant="ghost"
              size="icon"
              aria-label="Close"
              className="md:hidden cursor-pointer"
            >
              <X className="h-5 w-5" />
            </Button>
          </SheetClose>
        )}
      </div>

      <Separator className="bg-[hsl(var(--sidebar-border))]" />

      <ScrollArea className="flex-1 px-3 py-4">
        <nav aria-label="Sidebar" className="flex flex-col gap-1">
          {navItems.map((item) => {
            const isActive = pathname === item.href || pathname.startsWith(item.href + "/")
            const Icon = item.icon
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onLinkClick}
                className={cn(
                  "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors",
                  isActive
                    ? "bg-amber-500/10 text-amber-600"
                    : "text-[hsl(var(--sidebar-foreground))] hover:bg-[hsl(var(--sidebar-accent))] hover:text-[hsl(var(--sidebar-accent-foreground))]"
                )}
              >
                <Icon aria-hidden="true" focusable="false" className="h-4 w-4 shrink-0" />
                <span>{item.label}</span>
              </Link>
            )
          })}
        </nav>
      </ScrollArea>

      <div className="p-4 border-t border-[hsl(var(--sidebar-border))]">
        <div className="flex items-center gap-3">
          <Avatar className="h-9 w-9">
            <AvatarFallback className="bg-amber-500/10 text-amber-600 text-xs">
              {initials}
            </AvatarFallback>
          </Avatar>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium truncate text-[hsl(var(--sidebar-accent-foreground))]">
              {user?.full_name || "User"}
            </p>
            <p className="text-xs truncate text-[hsl(var(--sidebar-foreground))] opacity-70">
              {user?.role ? user.role.replace(/_/g, " ") : ""}
            </p>
          </div>
          <Button
            variant="ghost"
            size="icon"
            className="text-[hsl(var(--sidebar-foreground))] hover:text-[hsl(var(--sidebar-accent-foreground))] hover:bg-[hsl(var(--sidebar-accent))] cursor-pointer shrink-0"
            title="Logout"
            aria-label="Logout"
            onClick={async () => {
              await logout()
              router.push("/login")
            }}
          >
            <LogOut className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </>
  )
}

export function AppSidebar({ open, onClose }: AppSidebarProps) {
  const pathname = usePathname()

  return (
    <>
      <aside className="hidden md:flex md:flex-col md:w-64 md:fixed md:inset-y-0 z-30 bg-[hsl(var(--sidebar-background))] text-[hsl(var(--sidebar-foreground))] border-r border-[hsl(var(--sidebar-border))]">
        <SidebarContent pathname={pathname} />
      </aside>

      <Sheet open={open} onOpenChange={(o) => !o && onClose?.()}>
        <SheetContent side="left" className="p-0 w-64 bg-[hsl(var(--sidebar-background))] text-[hsl(var(--sidebar-foreground))] border-r border-[hsl(var(--sidebar-border))]">
          <SidebarContent pathname={pathname} onLinkClick={onClose} />
        </SheetContent>
      </Sheet>
    </>
  )
}
