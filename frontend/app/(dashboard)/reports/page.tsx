"use client"

import { useRouter } from "next/navigation"
import {
  IndianRupee,
  CalendarCheck,
  CreditCard,
  Building2,
  Target,
  Briefcase,
  Package,
} from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { PageHeader } from "@/components/common/PageHeader"

const reportTypes = [
  {
    icon: IndianRupee,
    title: "Revenue Report",
    description: "Track total revenue, refunds, and net income",
    href: "/reports/revenue",
    color: "text-emerald-600 bg-emerald-100 dark:text-emerald-400 dark:bg-emerald-950",
  },
  {
    icon: CalendarCheck,
    title: "Booking Report",
    description: "Booking statistics by status and event type",
    href: "/reports/bookings",
    color: "text-blue-600 bg-blue-100 dark:text-blue-400 dark:bg-blue-950",
  },
  {
    icon: CreditCard,
    title: "Payments Report",
    description: "Payment collection and refund analytics",
    href: "/reports/payments",
    color: "text-purple-600 bg-purple-100 dark:text-purple-400 dark:bg-purple-950",
  },
  {
    icon: Building2,
    title: "Venue Occupancy",
    description: "Venue utilization and booking rates",
    href: "/reports/occupancy",
    color: "text-orange-600 bg-orange-100 dark:text-orange-400 dark:bg-orange-950",
  },
  {
    icon: Target,
    title: "Leads Report",
    description: "Lead conversion and source analytics",
    href: "/reports/leads",
    color: "text-rose-600 bg-rose-100 dark:text-rose-400 dark:bg-rose-950",
  },
  {
    icon: Briefcase,
    title: "Vendors Report",
    description: "Vendor category and status overview",
    href: "/reports/vendors",
    color: "text-cyan-600 bg-cyan-100 dark:text-cyan-400 dark:bg-cyan-950",
  },
  {
    icon: Package,
    title: "Inventory Report",
    description: "Stock levels and category breakdown",
    href: "/reports/inventory",
    color: "text-yellow-600 bg-yellow-100 dark:text-yellow-400 dark:bg-yellow-950",
  },
]

export default function ReportsPage() {
  const router = useRouter()

  return (
    <div className="space-y-6">
      <PageHeader
        title="Reports"
        description="View analytics and insights for your business"
      />

      <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        {reportTypes.map((report) => (
          <button
            key={report.title}
            className="text-left cursor-pointer"
            onClick={() => router.push(report.href)}
          >
            <Card className="transition-colors hover:bg-slate-100 h-full">
              <CardHeader>
                <div className="flex items-center gap-3">
                  <div className={`flex items-center justify-center w-10 h-10 rounded-lg ${report.color}`}>
                    <report.icon className="h-5 w-5" />
                  </div>
                  <CardTitle className="text-base ">{report.title}</CardTitle>
                </div>
              </CardHeader>
              <CardContent>
                <CardDescription>{report.description}</CardDescription>
              </CardContent>
            </Card>
          </button>
        ))}
      </div>
    </div>
  )
}
