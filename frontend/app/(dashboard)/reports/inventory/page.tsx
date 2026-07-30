"use client"

import { useRouter } from "next/navigation"
import { ArrowLeft, Package, AlertTriangle } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { PageHeader } from "@/components/common/PageHeader"
import { StatCard } from "@/components/common/StatCard"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { useInventoryReport } from "@/hooks/use-reports"

export default function InventoryReportPage() {
  const router = useRouter()
  const { data, isLoading, isError, error, refetch } = useInventoryReport()
  const report = data?.data

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader title="Inventory Report">
          <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/reports")}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Button>
        </PageHeader>
        <ErrorState message={(error as Error)?.message} onRetry={() => refetch()} />
      </div>
    )
  }

  const byCategory = report?.by_category ?? {}

  return (
    <div className="space-y-6">
      <PageHeader title="Inventory Report">
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
              No inventory data available
            </CardContent>
          </Card>
        )
      ) : (
        <>
          <div className="grid gap-4 grid-cols-1 sm:grid-cols-2">
            <StatCard title="Total Items" value={report.total_items} icon={Package} loading={isLoading} />
            <StatCard
              title="Low Stock Items"
              value={report.low_stock_items}
              icon={AlertTriangle}
              loading={isLoading}
            />
          </div>

          {report.low_stock_items > 0 && (
            <div className="flex items-center gap-2 p-3 rounded-lg bg-warning/10 border border-warning/30 text-warning-foreground text-sm">
              <AlertTriangle className="h-4 w-4" />
              <span>{report.low_stock_items} item{report.low_stock_items !== 1 ? "s" : ""} below minimum stock level</span>
            </div>
          )}

          {Object.keys(byCategory).length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">By Category</CardTitle>
              </CardHeader>
              <CardContent>
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left py-2 font-medium text-muted-foreground">Category</th>
                      <th className="text-right py-2 font-medium text-muted-foreground">Count</th>
                    </tr>
                  </thead>
                  <tbody>
                    {Object.entries(byCategory).map(([category, count]) => (
                      <tr key={category} className="border-b last:border-0">
                        <td className="py-2 capitalize">{category.replace(/_/g, " ").toLowerCase()}</td>
                        <td className="py-2 text-right font-medium">{count}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </CardContent>
            </Card>
          )}
        </>
      )}
    </div>
  )
}
