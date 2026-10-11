"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { ArrowLeft, Target, CheckCircle, XCircle, Zap, TrendingUp } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { PageHeader } from "@/components/common/PageHeader"
import { StatCard } from "@/components/common/StatCard"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { useLeadReport } from "@/hooks/use-reports"

export default function LeadsReportPage() {
  const router = useRouter()
  const today = new Date().toISOString().split("T")[0]
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split("T")[0]
  const [startDate, setStartDate] = useState(thirtyDaysAgo)
  const [endDate, setEndDate] = useState(today)

  const { data, isLoading, isError, error, refetch } = useLeadReport({ start_date: startDate, end_date: endDate })
  const report = data?.data

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader title="Leads Report">
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
  const bySource = report?.by_source ?? {}
  const converted = byStatus.CONVERTED ?? 0
  const lost = byStatus.LOST ?? 0
  const active = byStatus.ACTIVE ?? 0

  return (
    <div className="space-y-6">
      <PageHeader title="Leads Report">
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
        <Button variant="secondary" size="sm" className="cursor-pointer" onClick={() => refetch()}>
          Apply
        </Button>
      </div>

      {!report ? (
        isLoading ? (
          <LoadingState count={5} />
        ) : (
          <Card>
            <CardContent className="py-10 text-center text-muted-foreground">
              No lead data available
            </CardContent>
          </Card>
        )
      ) : (
        <>
          <div className="grid gap-4 grid-cols-2 sm:grid-cols-5">
            <StatCard title="Total Leads" value={report.total_leads} icon={Target} loading={isLoading} />
            <StatCard title="Converted" value={converted} icon={CheckCircle} loading={isLoading} />
            <StatCard title="Lost" value={lost} icon={XCircle} loading={isLoading} />
            <StatCard title="Active" value={active} icon={Zap} loading={isLoading} />
            <StatCard title="Conversion Rate" value={`${report.conversion_rate.toFixed(1)}%`} icon={TrendingUp} loading={isLoading} />
          </div>

          <div className="grid gap-6 grid-cols-1 md:grid-cols-2">
            {Object.keys(byStatus).length > 0 && (
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">By Status</CardTitle>
                </CardHeader>
                <CardContent>
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b">
                        <th className="text-left py-2 font-medium text-muted-foreground">Status</th>
                        <th className="text-right py-2 font-medium text-muted-foreground">Count</th>
                      </tr>
                    </thead>
                    <tbody>
                      {Object.entries(byStatus).map(([status, count]) => (
                        <tr key={status} className="border-b last:border-0">
                          <td className="py-2 capitalize">{status.replace(/_/g, " ").toLowerCase()}</td>
                          <td className="py-2 text-right font-medium">{count}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </CardContent>
              </Card>
            )}

            {Object.keys(bySource).length > 0 && (
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">By Source</CardTitle>
                </CardHeader>
                <CardContent>
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b">
                        <th className="text-left py-2 font-medium text-muted-foreground">Source</th>
                        <th className="text-right py-2 font-medium text-muted-foreground">Count</th>
                      </tr>
                    </thead>
                    <tbody>
                      {Object.entries(bySource).map(([source, count]) => (
                        <tr key={source} className="border-b last:border-0">
                          <td className="py-2 capitalize">{source.replace(/_/g, " ").toLowerCase()}</td>
                          <td className="py-2 text-right font-medium">{count}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </CardContent>
              </Card>
            )}
          </div>
        </>
      )}
    </div>
  )
}
