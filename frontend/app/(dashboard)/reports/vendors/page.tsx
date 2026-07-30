"use client"

import { useRouter } from "next/navigation"
import { ArrowLeft, Briefcase, CheckCircle } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { PageHeader } from "@/components/common/PageHeader"
import { StatCard } from "@/components/common/StatCard"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { useVendorReport } from "@/hooks/use-reports"

export default function VendorsReportPage() {
  const router = useRouter()
  const { data, isLoading, isError, error, refetch } = useVendorReport()
  const report = data?.data

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader title="Vendors Report">
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
      <PageHeader title="Vendors Report">
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
              No vendor data available
            </CardContent>
          </Card>
        )
      ) : (
        <>
          <div className="grid gap-4 grid-cols-1 sm:grid-cols-2">
            <StatCard title="Total Vendors" value={report.total_vendors} icon={Briefcase} loading={isLoading} />
            <StatCard title="Active Vendors" value={report.active_vendors} icon={CheckCircle} loading={isLoading} />
          </div>

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
