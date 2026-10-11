"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Plus, Search, Eye, Check, XCircle, Trash2, MoreHorizontal, Calendar } from "lucide-react"
import { useBookings, useConfirmBooking, useCancelBooking, useDeleteBooking } from "@/hooks/use-bookings"
import { PageHeader } from "@/components/common/PageHeader"
import { DataTable } from "@/components/common/DataTable"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { toast } from "@/components/ui/toast"
import { formatDate, formatINR } from "@/lib/utils"
import { BOOKING_STATUSES, EVENT_TYPES } from "@/lib/constants"
import type { Booking } from "@/types/api"

export default function BookingsPage() {
  const router = useRouter()
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState("All")
  const [eventTypeFilter, setEventTypeFilter] = useState("All")
  const [venueFilter, setVenueFilter] = useState("All")
  const [page, setPage] = useState(1)

  const [confirmId, setConfirmId] = useState<number | null>(null)
  const [cancelId, setCancelId] = useState<number | null>(null)
  const [cancelReason, setCancelReason] = useState("")
  const [deleteId, setDeleteId] = useState<number | null>(null)

  const status = statusFilter === "All" ? undefined : statusFilter
  const event_type = eventTypeFilter === "All" ? undefined : eventTypeFilter

  const { data, isLoading, error, refetch } = useBookings({
    page,
    page_size: 10,
    search: search || undefined,
    status,
    event_type,
  })

  const confirmBooking = useConfirmBooking()
  const cancelBooking = useCancelBooking()
  const deleteBooking = useDeleteBooking()

  const bookings = data?.data ?? []
  const pagination = data?.pagination

  const handleConfirm = async () => {
    if (!confirmId) return
    try {
      await confirmBooking.mutateAsync(confirmId)
      toast({ title: "Booking confirmed", variant: "success" })
      setConfirmId(null)
    } catch {
      toast({ title: "Failed to confirm booking", variant: "destructive" })
    }
  }

  const handleCancel = async () => {
    if (!cancelId) return
    try {
      await cancelBooking.mutateAsync({ id: cancelId, remarks: cancelReason || undefined })
      toast({ title: "Booking cancelled", variant: "warning" })
      setCancelId(null)
      setCancelReason("")
    } catch {
      toast({ title: "Failed to cancel booking", variant: "destructive" })
    }
  }

  const handleDelete = async () => {
    if (!deleteId) return
    try {
      await deleteBooking.mutateAsync(deleteId)
      toast({ title: "Booking deleted", variant: "success" })
      setDeleteId(null)
    } catch {
      toast({ title: "Failed to delete booking", variant: "destructive" })
    }
  }

  const columns: import("@/components/common/DataTable").Column<Record<string, unknown>>[] = [
    {
      key: "booking_number",
      header: "Booking #",
      cell: (item) => {
        const booking = item as unknown as Booking
        return <span className="font-mono font-medium text-amber-600 text-sm">{booking.booking_number}</span>
      },
    },
    {
      key: "customer_name",
      header: "Customer",
      cell: (item) => {
        const booking = item as unknown as Booking
        return <span className="text-sm text-slate-700">{booking.customer_name || `ID: ${booking.customer}`}</span>
      },
    },
    {
      key: "venue_name",
      header: "Venue",
      cell: (item) => {
        const booking = item as unknown as Booking
        return <span className="text-sm">{booking.venue_name || `ID: ${booking.venue}`}</span>
      },
    },
    {
      key: "event_date",
      header: "Event Date",
      cell: (item) => {
        const booking = item as unknown as Booking
        return <span className="text-sm">{formatDate(booking.event_date)}</span>
      },
    },
    {
      key: "event_type",
      header: "Event Type",
      cell: (item) => {
        const booking = item as unknown as Booking
        return <span className="text-sm text-slate-700">{booking.event_type.replace(/_/g, " ")}</span>
      },
    },
    {
      key: "total_amount",
      header: "Amount",
      sortable: true,
      cell: (item) => {
        const booking = item as unknown as Booking
        return <span className="font-mono text-sm">{formatINR(Number(booking.total_amount))}</span>
      },
    },
    {
      key: "status",
      header: "Status",
      cell: (item) => {
        const booking = item as unknown as Booking
        return <StatusBadge status={booking.status} type="booking" />
      },
    },
    {
      key: "actions",
      header: "Actions",
      cell: (item) => {
        const booking = item as unknown as Booking
        const canConfirm = booking.status === "TENTATIVE"
        const canCancel = !["CANCELLED", "COMPLETED", "REFUNDED"].includes(booking.status)
        return (
          <div
            className="flex items-center gap-1"
            role="button"
            tabIndex={0}
            aria-label="Booking actions"
            onClick={(e) => e.stopPropagation()}
            onKeyDown={(e) => {
              if (e.key === "Enter" || e.key === " ") {
                e.preventDefault()
                e.stopPropagation()
              }
            }}
          >
            <Button
              variant="ghost"
              size="icon"
              aria-label="View booking"
              className="cursor-pointer"
              onClick={() => router.push(`/bookings/${booking.id}`)}
            >
              <Eye aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button
                  variant="ghost"
                  size="icon"
            aria-label="Booking row actions"
                  className="cursor-pointer"
                >
                  <MoreHorizontal aria-hidden="true" focusable="false" className="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem
                  className="cursor-pointer"
                  onClick={() => router.push(`/bookings/${booking.id}`)}
                >
                  <Eye className="mr-2 h-4 w-4" />
                  View
                </DropdownMenuItem>
                {canConfirm && (
                  <DropdownMenuItem
                    className="cursor-pointer text-green-600"
                    onClick={() => setConfirmId(booking.id)}
                  >
                    <Check className="mr-2 h-4 w-4" />
                    Confirm
                  </DropdownMenuItem>
                )}
                {canCancel && (
                  <DropdownMenuItem
                    className="cursor-pointer text-red-600"
                    onClick={() => setCancelId(booking.id)}
                  >
                    <XCircle className="mr-2 h-4 w-4" />
                    Cancel
                  </DropdownMenuItem>
                )}
                <DropdownMenuItem
                  className="cursor-pointer text-destructive"
                  onClick={() => setDeleteId(booking.id)}
                >
                  <Trash2 className="mr-2 h-4 w-4" />
                  Delete
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        )
      },
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Bookings" description="Manage all event bookings">
        <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/bookings/calendar")}>
          <Calendar className="mr-2 h-4 w-4" />
          Calendar
        </Button>
        <Button className="cursor-pointer" onClick={() => router.push("/bookings/new")}>
          <Plus className="mr-2 h-4 w-4" />
          New Booking
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-700" />
          <Input
            placeholder="Search bookings..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setPage(1)
            }}
            className="pl-9"
          />
        </div>
        <Select
          value={statusFilter}
          onValueChange={(v) => {
            setStatusFilter(v)
            setPage(1)
          }}
        >
          <SelectTrigger className="w-full sm:w-[160px] cursor-pointer">
            <SelectValue placeholder="Status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="All">All Status</SelectItem>
            {BOOKING_STATUSES.map((s) => (
              <SelectItem key={s} value={s} className="cursor-pointer">
                {s.replace(/_/g, " ")}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select
          value={eventTypeFilter}
          onValueChange={(v) => {
            setEventTypeFilter(v)
            setPage(1)
          }}
        >
          <SelectTrigger className="w-full sm:w-[180px] cursor-pointer">
            <SelectValue placeholder="Event Type" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="All">All Events</SelectItem>
            {EVENT_TYPES.map((t) => (
              <SelectItem key={t} value={t} className="cursor-pointer">
                {t.replace(/_/g, " ")}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <DataTable
        columns={columns}
        data={bookings as unknown as Record<string, unknown>[]}
        loading={isLoading}
        error={error ? (error as Error).message : null}
        onRetry={() => refetch()}
        emptyMessage="No bookings found. Create your first booking to get started."
        emptyAction={{ label: "New Booking", onClick: () => router.push("/bookings/new") }}
        onRowClick={(item) => router.push(`/bookings/${(item as unknown as Booking).id}`)}
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
        open={!!confirmId}
        onOpenChange={(open) => !open && setConfirmId(null)}
        title="Confirm Booking"
        description="Are you sure you want to confirm this booking?"
        onConfirm={handleConfirm}
        confirmLabel="Confirm"
        loading={confirmBooking.isPending}
      />

      <Dialog open={!!cancelId} onOpenChange={(open) => !open && setCancelId(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Cancel Booking</DialogTitle>
            <DialogDescription>
              Are you sure you want to cancel this booking? You can provide a reason below.
            </DialogDescription>
          </DialogHeader>
          <Textarea
            placeholder="Cancellation reason (optional)..."
            value={cancelReason}
            onChange={(e) => setCancelReason(e.target.value)}
            rows={3}
          />
          <DialogFooter>
            <Button
              variant="outline"
              className="cursor-pointer"
              onClick={() => {
                setCancelId(null)
                setCancelReason("")
              }}
              disabled={cancelBooking.isPending}
            >
              Keep Booking
            </Button>
            <Button
              variant="destructive"
              className="cursor-pointer"
              onClick={handleCancel}
              disabled={cancelBooking.isPending}
            >
              {cancelBooking.isPending ? "Cancelling..." : "Cancel Booking"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={!!deleteId}
        onOpenChange={(open) => !open && setDeleteId(null)}
        title="Delete Booking"
        description="Are you sure you want to delete this booking? This action cannot be undone."
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteBooking.isPending}
      />
    </div>
  )
}
