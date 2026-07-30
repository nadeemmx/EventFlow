"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { ArrowLeft, IndianRupee, ArrowDownFromLine, Wallet } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { PageHeader } from "@/components/common/PageHeader"
import { StatCard } from "@/components/common/StatCard"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { useRevenueReport } from "@/hooks/use-reports"
import { formatINR } from "@/lib/utils"

export default function RevenueReportPage() {
  const router = useRouter()
  const today = new Date().toISOString().split("T")[0]
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split("T")[0]
  const [startDate, setStartDate] = useState(thirtyDaysAgo)
  const [endDate, setEndDate] = useState(today)

  const { data, isLoading, isError, error, refetch } = useRevenueReport({ start_date: startDate, end_date: endDate })
  const report = data?.data

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader title="Revenue Report">
          <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/reports")}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Button>
        </PageHeader>
        <ErrorState message={(error as Error)?.message} onRetry={() => refetch()} />
      </div>
    )
  }

  const netRevenue = report ? report.total_revenue - (report as any).total_refunds : 0

  return (
    <div className="space-y-6">
      <PageHeader title="Revenue Report">
        <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/reports")}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-3 items-start sm:items-end">
        <div className="space-y-1">
          <label className="text-xs text-muted-foreground">Start Date</label>
          <Input
            type="date"
            value={startDate}
            onChange={(e) => setStartDate(e.target.value)}
            className="w-44 cursor-pointer"
          />
        </div>
        <div className="space-y-1">
          <label className="text-xs text-muted-foreground">End Date</label>
          <Input
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
          title="Total Revenue"
          value={report ? formatINR(report.total_revenue) : "—"}
          icon={IndianRupee}
          loading={isLoading}
        />
        <StatCard
          title="Total Refunds"
          value={report ? formatINR((report as any).total_refunds ?? 0) : "—"}
          icon={ArrowDownFromLine}
          loading={isLoading}
        />
        <StatCard
          title="Net Revenue"
          value={report ? formatINR(netRevenue) : "—"}
          icon={Wallet}
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
