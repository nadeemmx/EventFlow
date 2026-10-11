"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { ArrowLeft, CreditCard, ArrowDownFromLine, Wallet } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { PageHeader } from "@/components/common/PageHeader"
import { StatCard } from "@/components/common/StatCard"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { usePaymentReport } from "@/hooks/use-reports"
import { formatINR } from "@/lib/utils"

export default function PaymentsReportPage() {
  const router = useRouter()
  const today = new Date().toISOString().split("T")[0]
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split("T")[0]
  const [startDate, setStartDate] = useState(thirtyDaysAgo)
  const [endDate, setEndDate] = useState(today)

  const { data, isLoading, isError, error, refetch } = usePaymentReport({ start_date: startDate, end_date: endDate })
  const report = data?.data

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader title="Payments Report">
          <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/reports")}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Button>
        </PageHeader>
        <ErrorState message={(error as Error)?.message} onRetry={() => refetch()} />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Payments Report">
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

      <div className="grid gap-4 grid-cols-1 sm:grid-cols-3">
        <StatCard
          title="Total Collected"
          value={report ? formatINR(report.total_collected) : "—"}
          icon={CreditCard}
          loading={isLoading}
        />
        <StatCard
          title="Total Refunded"
          value={report ? formatINR(report.total_refunded) : "—"}
          icon={ArrowDownFromLine}
          loading={isLoading}
        />
        <StatCard
          title="Net Revenue"
          value={report ? formatINR(report.net_revenue) : "—"}
          icon={Wallet}
          loading={isLoading}
        />
      </div>

      {report && report.by_method && Object.keys(report.by_method).length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">By Payment Method</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {Object.entries(report.by_method).map(([method, amount]) => (
                <div key={method} className="flex items-center justify-between">
                  <span className="text-sm font-medium">{method.replace(/_/g, " ")}</span>
                  <span className="text-sm">{formatINR(amount)}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {report && (
        <div className="text-sm text-muted-foreground">
          Period: {new Date(report.period_start).toLocaleDateString()} –{" "}
          {new Date(report.period_end).toLocaleDateString()}
        </div>
      )}
    </div>
  )
}
