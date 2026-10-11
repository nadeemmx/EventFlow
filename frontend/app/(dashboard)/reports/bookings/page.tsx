"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { ArrowLeft, CalendarCheck, CheckCircle, XCircle, Ban, DollarSign } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { PageHeader } from "@/components/common/PageHeader"
import { StatCard } from "@/components/common/StatCard"
import { ErrorState } from "@/components/common/ErrorState"
import { useBookingReport } from "@/hooks/use-reports"
import { formatINR } from "@/lib/utils"

export default function BookingReportPage() {
  const router = useRouter()
  const today = new Date().toISOString().split("T")[0]
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split("T")[0]
  const [startDate, setStartDate] = useState(thirtyDaysAgo)
  const [endDate, setEndDate] = useState(today)

  const { data, isLoading, isError, error, refetch } = useBookingReport({ start_date: startDate, end_date: endDate })
  const report = data?.data

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader title="Booking Report">
          <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/reports")}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Button>
        </PageHeader>
        <ErrorState message={(error as Error)?.message} onRetry={() => refetch()} />
      </div>
    )
  }

  const byStatus = report?.by_status ?? {}

  return (
    <div className="space-y-6">
      <PageHeader title="Booking Report">
        <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/reports")}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-3 items-start sm:items-end">
        <div className="space-y-1">
          <label htmlFor="report-start-date" className="text-xs text-muted-foreground">Start Date</label>
          <Input
            id="report-start-date"
            type="date"
            value={startDate}
            onChange={(e) => setStartDate(e.target.value)}
            className="w-44 cursor-pointer"
          />
        </div>
        <div className="space-y-1">
          <label htmlFor="report-end-date" className="text-xs text-muted-foreground">End Date</label>
          <Input
            id="report-end-date"
            type="date"
            value={endDate}
            onChange={(e) => setEndDate(e.target.value)}
            className="w-44 cursor-pointer"
          />
        </div>
        <Button
          variant="secondary"
          size="sm"
          className="cursor-pointer"
          onClick={() => refetch()}
        >
          Apply
        </Button>
      </div>

      <div className="grid gap-4 grid-cols-2 sm:grid-cols-5">
        <StatCard
          title="Total Bookings"
          value={report?.total_bookings ?? "—"}
          icon={CalendarCheck}
          loading={isLoading}
        />
        <StatCard
          title="Confirmed"
          value={byStatus.CONFIRMED ?? 0}
          icon={CheckCircle}
          loading={isLoading}
        />
        <StatCard
          title="Cancelled"
          value={byStatus.CANCELLED ?? 0}
          icon={XCircle}
          loading={isLoading}
        />
        <StatCard
          title="Completed"
          value={byStatus.COMPLETED ?? 0}
          icon={Ban}
          loading={isLoading}
        />
        <StatCard
          title="Avg Value"
          value={report ? formatINR(report.average_booking_value) : "—"}
          icon={DollarSign}
          loading={isLoading}
        />
      </div>

      {report && (
        <div className="text-sm text-muted-foreground">
          Period: {new Date(report.period_start).toLocaleDateString()} –{" "}
          {new Date(report.period_end).toLocaleDateString()}
        </div>
      )}
    </div>
  )
}
