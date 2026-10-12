"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Plus, Search, MapPin, Eye, Edit, Trash2 } from "lucide-react"
import { useVenues, useDeleteVenue } from "@/hooks/use-venues"
import { PageHeader } from "@/components/common/PageHeader"
import { DataTable } from "@/components/common/DataTable"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { toast } from "@/components/ui/toast"
import { cn, formatINR } from "@/lib/utils"
import { VENUE_TYPES } from "@/lib/constants"
import type { Venue } from "@/types/api"

const statusFilters = ["All", "ACTIVE", "INACTIVE", "MAINTENANCE"] as const

export default function VenuesPage() {
  const router = useRouter()
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState("All")
  const [venueTypeFilter, setVenueTypeFilter] = useState("All")
  const [page, setPage] = useState(1)
  const [deleteId, setDeleteId] = useState<number | null>(null)

  const status = statusFilter === "All" ? undefined : statusFilter
  const venue_type = venueTypeFilter === "All" ? undefined : venueTypeFilter

  const { data, isLoading, error, refetch } = useVenues({
    page,
    page_size: 10,
    search: search || undefined,
    status,
    venue_type,
  })

  const deleteVenue = useDeleteVenue()

  const venues = data?.data ?? []
  const pagination = data?.pagination

  const handleDelete = async () => {
    if (!deleteId) return
    try {
      await deleteVenue.mutateAsync(deleteId)
      toast({ title: "Venue deleted", variant: "success" })
      setDeleteId(null)
    } catch {
      toast({ title: "Failed to delete venue", variant: "destructive" })
    }
  }

  const columns: import("@/components/common/DataTable").Column<Record<string, unknown>>[] = [
    {
      key: "name",
      header: "Name",
      cell: (item) => {
        const venue = item as unknown as Venue
        return (
          <div className="flex items-center gap-2">
            <MapPin className="h-4 w-4 text-slate-700 shrink-0" />
            <span className="font-medium">{venue.name}</span>
          </div>
        )
      },
    },
    {
      key: "venue_type",
      header: "Type",
      cell: (item) => {
        const venue = item as unknown as Venue
        return <span className="text-sm text-slate-700">{venue.venue_type.replace(/_/g, " ")}</span>
      },
    },
    {
      key: "capacity",
      header: "Capacity",
      sortable: true,
      cell: (item) => {
        const venue = item as unknown as Venue
        return <span className="font-mono text-sm">{venue.capacity.toLocaleString()}</span>
      },
    },
    {
      key: "weekday_price",
      header: "Weekday Price",
      sortable: true,
      cell: (item) => {
        const venue = item as unknown as Venue
        return <span className="font-mono text-sm">{formatINR(Number(venue.weekday_price))}</span>
      },
    },
    {
      key: "weekend_price",
      header: "Weekend Price",
      sortable: true,
      cell: (item) => {
        const venue = item as unknown as Venue
        return <span className="font-mono text-sm">{formatINR(Number(venue.weekend_price))}</span>
      },
    },
    {
      key: "status",
      header: "Status",
      cell: (item) => {
        const venue = item as unknown as Venue
        return <StatusBadge status={venue.status} type="venue" />
      },
    },
    {
      key: "actions",
      header: "Actions",
      cell: (item) => {
        const venue = item as unknown as Venue
        return (
          <div className="flex items-center gap-1">
            <Button
              variant="ghost"
              size="icon"
              aria-label="View venue"
              className="cursor-pointer"
              onClick={(e) => {
                e.stopPropagation()
                router.push(`/venues/${venue.id}`)
              }}
            >
              <Eye aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              aria-label="Edit venue"
              className="cursor-pointer"
              onClick={(e) => {
                e.stopPropagation()
                router.push(`/venues/${venue.id}`)
              }}
            >
              <Edit aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              aria-label="Delete venue"
              className="cursor-pointer text-destructive hover:text-destructive"
              onClick={(e) => {
                e.stopPropagation()
                setDeleteId(venue.id)
              }}
            >
              <Trash2 aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
          </div>
        )
      },
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Venues" description="Manage your event venues">
        <Button className="cursor-pointer" onClick={() => router.push("/venues/new")}>
          <Plus className="mr-2 h-4 w-4" />
          Add Venue
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-700" />
          <Input
            placeholder="Search venues..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setPage(1)
            }}
            className="pl-9"
          />
        </div>
        <Select
          value={venueTypeFilter}
          onValueChange={(v) => {
            setVenueTypeFilter(v)
            setPage(1)
          }}
        >
          <SelectTrigger className="w-full sm:w-[180px] cursor-pointer">
            <SelectValue placeholder="All Types" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="All">All Types</SelectItem>
            {VENUE_TYPES.map((t) => (
              <SelectItem key={t} value={t}>
                {t.replace(/_/g, " ")}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="flex gap-2 flex-wrap">
        {statusFilters.map((s) => (
          <button
            key={s}
            onClick={() => {
              setStatusFilter(s)
              setPage(1)
            }}
            className={cn(
              "px-3 py-1.5 text-sm rounded-full border transition-colors cursor-pointer",
              statusFilter === s
                ? "bg-amber-600 text-white border-amber-600"
                : "bg-white text-slate-700 border-input hover:bg-slate-100"
            )}
          >
            {s === "All" ? "All" : s.replace(/_/g, " ")}
          </button>
        ))}
      </div>

      <DataTable
        columns={columns}
        data={venues as unknown as Record<string, unknown>[]}
        loading={isLoading}
        error={error ? (error as Error).message : null}
        onRetry={() => refetch()}
        emptyMessage="No venues found. Create your first venue to get started."
        emptyAction={{ label: "Add Venue", onClick: () => router.push("/venues/new") }}
        onRowClick={(item) => router.push(`/venues/${(item as unknown as Venue).id}`)}
      />

      {pagination && pagination.total_pages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-slate-700">
            Page {pagination.page} of {pagination.total_pages} ({pagination.total_records} total)
          </p>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={page <= 1}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              className="cursor-pointer"
            >
              Previous
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={page >= pagination.total_pages}
              onClick={() => setPage((p) => p + 1)}
              className="cursor-pointer"
            >
              Next
            </Button>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={!!deleteId}
        onOpenChange={(open) => !open && setDeleteId(null)}
        title="Delete Venue"
        description="Are you sure you want to delete this venue? This action cannot be undone."
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteVenue.isPending}
      />
    </div>
  )
}
