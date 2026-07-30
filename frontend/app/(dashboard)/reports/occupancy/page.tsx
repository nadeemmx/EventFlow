"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { ArrowLeft, Building2, Percent, CalendarCheck } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { PageHeader } from "@/components/common/PageHeader"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { useOccupancyReport } from "@/hooks/use-reports"
import { Progress } from "@/components/ui/progress"

export default function OccupancyReportPage() {
  const router = useRouter()
  const [venueFilter, setVenueFilter] = useState("")

  const params = venueFilter ? { venue: Number(venueFilter) } : undefined
  const { data, isLoading, isError, error, refetch } = useOccupancyReport(params)
  const venues = data?.data ?? []

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader title="Occupancy Report">
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
      <PageHeader title="Occupancy Report">
        <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/reports")}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back
        </Button>
      </PageHeader>

      <div className="max-w-xs">
        <Input
          placeholder="Filter by Venue ID"
          type="number"
          value={venueFilter}
          onChange={(e) => setVenueFilter(e.target.value)}
          className="cursor-pointer"
        />
      </div>

      {isLoading ? (
        <LoadingState count={3} />
      ) : venues.length === 0 ? (
        <Card>
          <CardContent className="py-10 text-center text-muted-foreground">
            No occupancy data available
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {venues.map((venue) => (
            <Card key={venue.venue_id}>
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <Building2 className="h-5 w-5 text-muted-foreground" />
                  <CardTitle className="text-base">{venue.venue_name}</CardTitle>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Occupancy</span>
                  <span className="font-semibold">{venue.occupancy_rate.toFixed(1)}%</span>
                </div>
                <Progress value={venue.occupancy_rate} className="h-2" />
                <div className="flex items-center gap-4 text-xs text-muted-foreground">
                  <span className="flex items-center gap-1">
                    <CalendarCheck className="h-3.5 w-3.5" />
                    {venue.bookings_count} bookings
                  </span>
                  <span className="flex items-center gap-1">
                    <Building2 className="h-3.5 w-3.5" />
                    Capacity: {venue.total_capacity}
                  </span>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
