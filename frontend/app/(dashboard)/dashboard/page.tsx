"use client"

import { useRouter } from "next/navigation"
import {
  Calendar,
  CalendarCheck,
  CreditCard,
  IndianRupee,
  Target,
  Plus,
  ArrowRight,
  UserPlus,
  FileText,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { PageHeader } from "@/components/common/PageHeader"
import { StatCard } from "@/components/common/StatCard"
import { ErrorState } from "@/components/common/ErrorState"
import { useDashboardSummary } from "@/hooks/use-dashboard"
import { useBookings } from "@/hooks/use-bookings"
import { formatINR, formatDate } from "@/lib/utils"

const quickActions = [
  {
    icon: Plus,
    title: "New Booking",
    description: "Create a new event booking",
    href: "/bookings/new",
  },
  {
    icon: UserPlus,
    title: "Add Customer",
    description: "Register a new customer",
    href: "/customers/new",
  },
  {
    icon: CreditCard,
    title: "Record Payment",
    description: "Log a payment received",
    href: "/payments/new",
  },
  {
    icon: FileText,
    title: "View Reports",
    description: "Analytics and insights",
    href: "/reports",
  },
]

export default function DashboardPage() {
  const router = useRouter()

  const { data, isLoading, isError, error, refetch } = useDashboardSummary()
  const { data: recentBookingsData, isLoading: bookingsLoading } = useBookings({ page: 1, page_size: 5 })

  const summary = data?.data
  const recentBookings = recentBookingsData?.data ?? []

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader title="Dashboard" />
        <ErrorState message={(error as Error)?.message} onRetry={() => refetch()} />
      </div>
    )
  }

  return (
    <div className="space-y-8">
      <PageHeader title="Dashboard" />

      <div className="grid gap-4 grid-cols-2 lg:grid-cols-5">
        <StatCard
          title="Today's Events"
          value={summary?.today_events ?? 0}
          icon={Calendar}
          loading={isLoading}
        />
        <StatCard
          title="Upcoming Bookings"
          value={summary?.upcoming_bookings ?? 0}
          icon={CalendarCheck}
          loading={isLoading}
        />
        <StatCard
          title="Pending Payments"
          value={summary?.pending_payments ?? 0}
          icon={CreditCard}
          loading={isLoading}
        />
        <StatCard
          title="Monthly Revenue"
          value={formatINR(summary?.monthly_revenue ?? 0)}
          icon={IndianRupee}
          loading={isLoading}
        />
        <StatCard
          title="Active Leads"
          value={summary?.active_leads ?? 0}
          icon={Target}
          loading={isLoading}
        />
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-lg ">Quick Actions</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid gap-3 sm:grid-cols-2">
              {quickActions.map((action) => (
                <button
                  key={action.title}
                  className="flex items-start gap-3 rounded-lg border p-4 text-left transition-colors hover:bg-slate-100 cursor-pointer"
                  onClick={() => router.push(action.href)}
                >
                  <div className="flex items-center justify-center w-9 h-9 rounded-lg bg-amber-500/10 text-amber-600 shrink-0">
                    <action.icon className="h-4 w-4" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium">{action.title}</p>
                    <p className="text-xs text-muted-foreground">{action.description}</p>
                  </div>
                  <ArrowRight className="h-4 w-4 text-muted-foreground shrink-0 mt-1" />
                </button>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle className="text-lg ">Recent Bookings</CardTitle>
            <Button
              variant="ghost"
              size="sm"
              className="cursor-pointer"
              onClick={() => router.push("/bookings")}
            >
              View all
            </Button>
          </CardHeader>
          <CardContent>
            {bookingsLoading ? (
              <div className="space-y-3">
                {Array.from({ length: 5 }).map((_, i) => (
                  <div key={i} className="h-10 bg-muted rounded animate-pulse" />
                ))}
              </div>
            ) : recentBookings.length === 0 ? (
              <div className="flex flex-col items-center py-6 text-center">
                <p className="text-sm text-muted-foreground mb-3">No recent bookings</p>
                <Button variant="outline" size="sm" className="cursor-pointer" onClick={() => router.push("/bookings/new")}>
                  <Plus className="h-4 w-4 mr-2" />
                  New Booking
                </Button>
              </div>
            ) : (
              <div className="space-y-2">
                {recentBookings.map((booking) => (
                  <div
                    key={booking.id}
                    className="flex items-center justify-between py-2 border-b last:border-0 cursor-pointer hover:bg-slate-100 rounded px-2 -mx-2 transition-colors"
                    onClick={() => router.push(`/bookings/${booking.id}`)}
                  >
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium truncate">{booking.booking_number}</p>
                      <p className="text-xs text-muted-foreground">{formatDate(booking.event_date)}</p>
                    </div>
                    <span className="text-sm font-semibold ml-4">{formatINR(Number(booking.total_amount))}</span>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
