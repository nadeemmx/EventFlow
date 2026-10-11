"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { ArrowLeft, IndianRupee, CalendarCheck, Target } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { PageHeader } from "@/components/common/PageHeader"
import { StatCard } from "@/components/common/StatCard"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { DataTable } from "@/components/common/DataTable"
import { useMonthlyGrowthReport } from "@/hooks/use-reports"
import { formatINR } from "@/lib/utils"
import type { MonthlyGrowthItem } from "@/services/reports.service"

export default function MonthlyGrowthPage() {
  const router = useRouter()
  const currentYear = new Date().getFullYear()
  const [year, setYear] = useState(currentYear)

  const { data, isLoading, isError, error, refetch } = useMonthlyGrowthReport({ year })
  const report = data?.data

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader title="Monthly Growth Report">
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
    {
      key: "month",
      header: "Month",
      sortable: true,
      cell: (item: MonthlyGrowthItem) => {
        const date = new Date(item.month + "-01")
        return date.toLocaleDateString("en-IN", { month: "long", year: "numeric" })
      },
    },
    {
      key: "revenue",
      header: "Revenue",
      sortable: true,
      cell: (item: MonthlyGrowthItem) => formatINR(item.revenue),
    },
    { key: "bookings", header: "Bookings", sortable: true },
    { key: "new_leads", header: "New Leads", sortable: true },
    { key: "conversions", header: "Conversions", sortable: true },
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Monthly Growth Report">
        <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/reports")}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-3 items-start sm:items-end">
        <div className="space-y-1">
          <label htmlFor="report-year" className="text-xs text-muted-foreground">Year</label>
          <Input
            id="report-year"
            type="number"
            value={year}
            onChange={(e) => setYear(Number(e.target.value))}
            className="w-32 cursor-pointer"
            min={2020}
            max={currentYear + 5}
          />
        </div>
        <Button variant="secondary" size="sm" className="cursor-pointer" onClick={() => refetch()}>
          Apply
        </Button>
      </div>

      {!report ? (
        isLoading ? (
          <LoadingState count={3} />
        ) : (
          <Card>
            <CardContent className="py-10 text-center text-muted-foreground">
              No monthly growth data available
            </CardContent>
          </Card>
        )
      ) : (
        <>
          <div className="grid gap-4 grid-cols-1 sm:grid-cols-3">
            <StatCard title="Total Revenue (YTD)" value={formatINR(report.total_revenue_ytd)} icon={IndianRupee} loading={isLoading} />
            <StatCard title="Total Bookings" value={report.total_bookings} icon={CalendarCheck} loading={isLoading} />
            <StatCard title="Total Leads" value={report.total_leads} icon={Target} loading={isLoading} />
          </div>

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Monthly Breakdown</CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable
                columns={columns}
                data={report.months}
                loading={isLoading}
                emptyMessage="No data for the selected year"
                error={null}
              />
            </CardContent>
          </Card>
        </>
      )}
    </div>
  )
}
