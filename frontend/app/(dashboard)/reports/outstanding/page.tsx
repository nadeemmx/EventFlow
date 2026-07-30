"use client"

import { useRouter } from "next/navigation"
import { ArrowLeft, IndianRupee, CalendarCheck } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { PageHeader } from "@/components/common/PageHeader"
import { StatCard } from "@/components/common/StatCard"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { DataTable } from "@/components/common/DataTable"
import { StatusBadge } from "@/components/common/StatusBadge"
import { useOutstandingPaymentsReport } from "@/hooks/use-reports"
import { formatINR, formatDate } from "@/lib/utils"
import type { OutstandingPaymentItem } from "@/services/reports.service"

export default function OutstandingPaymentsPage() {
  const router = useRouter()
  const { data, isLoading, isError, error, refetch } = useOutstandingPaymentsReport()
  const report = data?.data

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader title="Outstanding Payments Report">
          <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/reports")}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Button>
        </PageHeader>
        <ErrorState message={(error as Error)?.message} onRetry={() => refetch()} />
      </div>
    )
  }

  const columns = [
    { key: "booking_number", header: "Booking #", sortable: true },
    { key: "customer_name", header: "Customer", sortable: true },
    { key: "venue_name", header: "Venue", sortable: true },
    {
      key: "event_date",
      header: "Event Date",
      sortable: true,
      cell: (item: OutstandingPaymentItem) => formatDate(item.event_date),
    },
    {
      key: "total_amount",
      header: "Total",
      sortable: true,
      cell: (item: OutstandingPaymentItem) => formatINR(item.total_amount),
    },
    {
      key: "paid_amount",
      header: "Paid",
      sortable: true,
      cell: (item: OutstandingPaymentItem) => formatINR(item.paid_amount),
    },
    {
      key: "outstanding_amount",
      header: "Outstanding",
      sortable: true,
      cell: (item: OutstandingPaymentItem) => (
        <span className="font-semibold text-destructive">{formatINR(item.outstanding_amount)}</span>
      ),
    },
    {
      key: "status",
      header: "Status",
      cell: (item: OutstandingPaymentItem) => <StatusBadge status={item.status} type="booking" />,
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Outstanding Payments Report">
        <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/reports")}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back
        </Button>
      </PageHeader>

      {!report ? (
        isLoading ? (
          <LoadingState count={2} />
        ) : (
          <Card>
            <CardContent className="py-10 text-center text-muted-foreground">
              No outstanding payment data available
            </CardContent>
          </Card>
        )
      ) : (
        <>
          <div className="grid gap-4 grid-cols-1 sm:grid-cols-2">
            <StatCard title="Total Outstanding" value={formatINR(report.total_outstanding)} icon={IndianRupee} loading={isLoading} />
            <StatCard title="Bookings with Balance" value={report.total_bookings_with_balance} icon={CalendarCheck} loading={isLoading} />
          </div>

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Outstanding Payments</CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable
                columns={columns}
                data={report.payments}
                loading={isLoading}
                emptyMessage="No outstanding payments found"
                error={null}
              />
            </CardContent>
          </Card>
        </>
      )}
    </div>
  )
}
