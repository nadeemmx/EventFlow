"use client"

import { useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { ArrowLeft, Edit, Check, XCircle, Save, X, MapPin, User, DollarSign, MessageSquare, Clock, Play, CheckCircle2, FileText } from "lucide-react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { useBooking, useUpdateBooking, useBookingTimeline, useConfirmBooking, useCancelBooking, useMarkBookingInProgress, useMarkBookingCompleted, useBookingOutstanding } from "@/hooks/use-bookings"
import { PageHeader } from "@/components/common/PageHeader"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog"
import { Separator } from "@/components/ui/separator"
import { toast } from "@/components/ui/toast"
import { cn, formatDate, formatDateTime, formatINR } from "@/lib/utils"
import { EVENT_TYPES } from "@/lib/constants"
import type { Booking, Customer, Contract } from "@/types/api"
import type { TimelineEntry } from "@/services/bookings.service"

const bookingEditSchema = z.object({
  event_type: z.string().min(1, "Event type is required"),
  event_date: z.string().min(1, "Date is required"),
  guest_count: z.coerce.number().min(1, "Guest count must be at least 1"),
  total_amount: z.coerce.number().min(0),
  advance_amount: z.coerce.number().min(0),
  remarks: z.string().optional(),
})

type BookingEditValues = z.infer<typeof bookingEditSchema>

export default function BookingDetailClient() {
  const params = useParams()
  const router = useRouter()
  const id = Number(params.id)
  const [editing, setEditing] = useState(false)
  const [showCancelDialog, setShowCancelDialog] = useState(false)
  const [cancelReason, setCancelReason] = useState("")
  const [showConfirmDialog, setShowConfirmDialog] = useState(false)
  const [showMarkInProgressDialog, setShowMarkInProgressDialog] = useState(false)
  const [showMarkCompletedDialog, setShowMarkCompletedDialog] = useState(false)

  const { data: bookingRes, isLoading, error, refetch } = useBooking(id)
  const { data: timelineRes } = useBookingTimeline(id)
  const { data: outstandingRes } = useBookingOutstanding(id)
  const updateBooking = useUpdateBooking(id)
  const confirmBooking = useConfirmBooking()
  const cancelBooking = useCancelBooking()
  const markInProgress = useMarkBookingInProgress()
  const markCompleted = useMarkBookingCompleted()

  const booking = bookingRes?.data as (Booking & { customer_details?: Customer; venue_name?: string; contract?: Contract; balance_due?: number; payment_status?: string }) | undefined
  const timeline = (timelineRes?.data ?? []) as TimelineEntry[]
  const outstanding = outstandingRes?.data

  const canExecute = booking && (booking.status === "CONFIRMED" || booking.status === "IN_PROGRESS")

  const form = useForm<BookingEditValues>({
    resolver: zodResolver(bookingEditSchema),
    values: booking
      ? {
          event_type: booking.event_type,
          event_date: booking.event_date,
          guest_count: booking.guest_count,
          total_amount: Number(booking.total_amount),
          advance_amount: Number(booking.advance_amount),
          remarks: booking.remarks || "",
        }
      : undefined,
  })

  const onSubmit = async (values: BookingEditValues) => {
    try {
      await updateBooking.mutateAsync(values)
      toast({ title: "Booking updated", variant: "success" })
      setEditing(false)
    } catch {
      toast({ title: "Failed to update booking", variant: "destructive" })
    }
  }

  const handleConfirm = async () => {
    try {
      await confirmBooking.mutateAsync(id)
      toast({ title: "Booking confirmed", variant: "success" })
      setShowConfirmDialog(false)
      refetch()
    } catch {
      toast({ title: "Failed to confirm booking", variant: "destructive" })
    }
  }

  const handleCancel = async () => {
    try {
      await cancelBooking.mutateAsync({ id, remarks: cancelReason || undefined })
      toast({ title: "Booking cancelled", variant: "warning" })
      setShowCancelDialog(false)
      setCancelReason("")
      refetch()
    } catch {
      toast({ title: "Failed to cancel booking", variant: "destructive" })
    }
  }

  const handleMarkInProgress = async () => {
    try {
      await markInProgress.mutateAsync(id)
      toast({ title: "Event marked as in progress", variant: "success" })
      setShowMarkInProgressDialog(false)
      refetch()
    } catch {
      toast({ title: "Failed to mark in progress", variant: "destructive" })
    }
  }

  const handleMarkCompleted = async () => {
    try {
      await markCompleted.mutateAsync(id)
      toast({ title: "Event marked as completed", variant: "success" })
      setShowMarkCompletedDialog(false)
      refetch()
    } catch {
      toast({ title: "Failed to mark completed", variant: "destructive" })
    }
  }

  if (isLoading) return <LoadingState type="page" />
  if (error) return <ErrorState message={(error as Error).message} onRetry={() => refetch()} />
  if (!booking) return <ErrorState message="Booking not found" />

  const balance = outstanding
    ? Number(outstanding.balance_due)
    : Number(booking.total_amount) - Number(booking.advance_amount)
  const paymentStatus = outstanding
    ? Number(outstanding.balance_due) <= 0
      ? "PAID"
      : Number(outstanding.paid_amount) > 0
        ? "PARTIAL"
        : "PENDING"
    : balance <= 0
      ? "PAID"
      : Number(booking.advance_amount) > 0
        ? "PARTIAL"
        : "PENDING"
  const canConfirm = booking.status === "TENTATIVE"
  const canCancel = !["CANCELLED", "COMPLETED", "REFUNDED"].includes(booking.status)

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
        <button onClick={() => router.push("/bookings")} className="hover:text-foreground cursor-pointer">
          Bookings
        </button>
        <span>/</span>
        <span className="text-foreground font-mono font-medium">{booking.booking_number}</span>
      </div>

      <PageHeader title={editing ? "Edit Booking" : booking.booking_number}>
        <StatusBadge status={booking.status} type="booking" />
        <Button variant="outline" className="cursor-pointer" onClick={() => router.back()}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back
        </Button>
        {!editing ? (
          <>
            {canConfirm && (
              <Button
                variant="default"
                className="cursor-pointer"
                onClick={() => setShowConfirmDialog(true)}
              >
                <Check className="mr-2 h-4 w-4" />
                Confirm
              </Button>
            )}
            {canCancel && (
              <Button
                variant="outline"
                className="cursor-pointer text-destructive border-destructive hover:bg-destructive/10"
                onClick={() => setShowCancelDialog(true)}
              >
                <XCircle className="mr-2 h-4 w-4" />
                Cancel
              </Button>
            )}
            <Button variant="outline" className="cursor-pointer" onClick={() => setEditing(true)}>
              <Edit className="mr-2 h-4 w-4" />
              Edit
            </Button>
          </>
        ) : (
          <>
            <Button
              variant="outline"
              className="cursor-pointer"
              onClick={() => {
                setEditing(false)
                form.reset()
              }}
            >
              <X className="mr-2 h-4 w-4" />
              Cancel
            </Button>
            <Button className="cursor-pointer" onClick={form.handleSubmit(onSubmit)} disabled={updateBooking.isPending}>
              <Save className="mr-2 h-4 w-4" />
              {updateBooking.isPending ? "Saving..." : "Save"}
            </Button>
          </>
        )}
      </PageHeader>

      {editing ? (
        <Card>
          <CardContent className="pt-6">
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
                <div className="grid gap-6 md:grid-cols-2">
                  <FormField
                    control={form.control}
                    name="event_type"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Event Type</FormLabel>
                        <Select onValueChange={field.onChange} value={field.value}>
                          <FormControl>
                            <SelectTrigger className="cursor-pointer">
                              <SelectValue />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            {EVENT_TYPES.map((t) => (
                              <SelectItem key={t} value={t} className="cursor-pointer">
                                {t.replace(/_/g, " ")}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="event_date"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Event Date</FormLabel>
                        <FormControl>
                          <Input type="date" {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="guest_count"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Guest Count</FormLabel>
                        <FormControl>
                          <Input type="number" min={1} {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="total_amount"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Total Amount (₹)</FormLabel>
                        <FormControl>
                          <Input type="number" min={0} {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="advance_amount"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Advance Amount (₹)</FormLabel>
                        <FormControl>
                          <Input type="number" min={0} {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>
                <FormField
                  control={form.control}
                  name="remarks"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Remarks</FormLabel>
                      <FormControl>
                        <Textarea rows={3} {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </form>
            </Form>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-6 md:grid-cols-2">
          <div className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <MapPin className="h-5 w-5 text-primary" />
                  Booking Info
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground">Event Type</p>
                    <p className="font-medium">{booking.event_type.replace(/_/g, " ")}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Event Date</p>
                    <p className="font-medium">{formatDate(booking.event_date)}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Guest Count</p>
                    <p className="font-medium">{booking.guest_count.toLocaleString()}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Venue</p>
                    <p className="font-medium">{booking.venue_name || `Venue #${booking.venue}`}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Status</p>
                    <StatusBadge status={booking.status} type="booking" />
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <User className="h-5 w-5 text-primary" />
                  Customer Info
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground">Name</p>
                    <p className="font-medium">
                      {booking.customer_details?.full_name || `Customer #${booking.customer}`}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Mobile</p>
                    <p className="font-medium">{booking.customer_details?.mobile || "-"}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Email</p>
                    <p className="font-medium">{booking.customer_details?.email || "-"}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Address</p>
                    <p className="font-medium">{booking.customer_details?.address || "-"}</p>
                  </div>
                </div>
                {booking.customer_details && (
                  <Button
                    variant="link"
                    size="sm"
                    className="p-0 h-auto cursor-pointer"
                    onClick={() => router.push(`/customers/${booking.customer}`)}
                  >
                    View Customer Details →
                  </Button>
                )}
              </CardContent>
            </Card>
          </div>

          <div className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <DollarSign className="h-5 w-5 text-primary" />
                  Financial Info
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground">Total Amount</p>
                    <p className="text-xl font-bold">{formatINR(Number(booking.total_amount))}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Advance Paid</p>
                    <p className="text-xl font-bold text-green-600">{formatINR(Number(booking.advance_amount))}</p>
                  </div>
                </div>
                {outstanding && (
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-sm text-muted-foreground">Total Paid</p>
                      <p className="text-lg font-semibold text-green-600">{formatINR(Number(outstanding.paid_amount))}</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Payment Status</p>
                      <StatusBadge status={paymentStatus} type="booking" />
                    </div>
                  </div>
                )}
                <Separator />
                <div>
                  <p className="text-sm text-muted-foreground">Balance Due</p>
                  <p className={cn(
                    "text-xl font-bold",
                    balance <= 0 ? "text-green-600" : "text-destructive"
                  )}>
                    {formatINR(balance)}
                  </p>
                </div>
              </CardContent>
            </Card>

            {canExecute && (
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg flex items-center gap-2">
                    <Play className="h-5 w-5 text-primary" />
                    Event Execution
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex items-center gap-3">
                    <div className={cn(
                      "flex items-center gap-2 text-sm font-medium px-3 py-1.5 rounded-full",
                      booking.status === "IN_PROGRESS"
                        ? "bg-blue-100 text-blue-700"
                        : "bg-amber-100 text-amber-700"
                    )}>
                      <span className={cn(
                        "w-2 h-2 rounded-full",
                        booking.status === "IN_PROGRESS" ? "bg-blue-500 animate-pulse" : "bg-amber-500"
                      )} />
                      {booking.status === "IN_PROGRESS" ? "In Progress" : "Not Started"}
                    </div>
                  </div>
                  <div className="flex gap-3">
                    {booking.status === "CONFIRMED" && (
                      <Button
                        variant="default"
                        className="cursor-pointer"
                        onClick={() => setShowMarkInProgressDialog(true)}
                        disabled={markInProgress.isPending}
                      >
                        <Play className="mr-2 h-4 w-4" />
                        {markInProgress.isPending ? "Marking..." : "Mark In Progress"}
                      </Button>
                    )}
                    {booking.status === "IN_PROGRESS" && (
                      <Button
                        variant="default"
                        className="cursor-pointer"
                        onClick={() => setShowMarkCompletedDialog(true)}
                        disabled={markCompleted.isPending}
                      >
                        <CheckCircle2 className="mr-2 h-4 w-4" />
                        {markCompleted.isPending ? "Completing..." : "Mark Complete"}
                      </Button>
                    )}
                  </div>
                </CardContent>
              </Card>
            )}

            {booking.remarks && (
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg flex items-center gap-2">
                    <MessageSquare className="h-5 w-5 text-primary" />
                    Remarks
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-sm whitespace-pre-wrap">{booking.remarks}</p>
                </CardContent>
              </Card>
            )}

            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Clock className="h-5 w-5 text-primary" />
                  Timeline
                </CardTitle>
              </CardHeader>
              <CardContent>
                {timeline.length === 0 ? (
                  <p className="text-sm text-muted-foreground text-center py-4">No timeline entries yet</p>
                ) : (
                  <div className="relative space-y-0">
                    {timeline.map((entry, idx) => (
                      <div key={entry.id} className="flex gap-4 pb-6 last:pb-0 relative">
                        <div className="flex flex-col items-center">
                          <div className={cn(
                            "w-3 h-3 rounded-full border-2 shrink-0 mt-1.5 z-10",
                            entry.status === "CONFIRMED"
                              ? "bg-green-500 border-green-500"
                              : entry.status === "CANCELLED"
                                ? "bg-red-500 border-red-500"
                                : entry.status === "COMPLETED"
                                  ? "bg-blue-500 border-blue-500"
                                  : "bg-gray-300 border-gray-300"
                          )} />
                          {idx < timeline.length - 1 && (
                            <div className="w-0.5 bg-border flex-1 absolute top-4 left-[5.5px]" />
                          )}
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 flex-wrap">
                            <StatusBadge status={entry.status} type="booking" />
                            <span className="text-xs text-muted-foreground">
                              {formatDateTime(entry.created_at)}
                            </span>
                          </div>
                          {entry.notes && (
                            <p className="text-sm text-muted-foreground mt-1">{entry.notes}</p>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <FileText className="h-5 w-5 text-primary" />
                  Contracts
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {booking.contract ? (
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm text-muted-foreground">Contract</p>
                        <p className="font-medium">{booking.contract.contract_number}</p>
                      </div>
                      <Button
                        variant="outline"
                        size="sm"
                        className="cursor-pointer"
                        onClick={() => router.push(`/contracts/${booking.contract!.id}`)}
                      >
                        View Contract
                      </Button>
                    </div>
                    <div className="flex items-center gap-2">
                      <StatusBadge status={booking.contract.status} type="booking" />
                    </div>
                  </div>
                ) : (
                  <p className="text-sm text-muted-foreground">No contract generated yet</p>
                )}
                <Button
                  variant="outline"
                  className="cursor-pointer w-full"
                  onClick={() => router.push(`/contracts/new?booking_id=${id}`)}
                >
                  <FileText className="mr-2 h-4 w-4" />
                  Generate Contract
                </Button>
              </CardContent>
            </Card>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={showConfirmDialog}
        onOpenChange={setShowConfirmDialog}
        title="Confirm Booking"
        description={`Are you sure you want to confirm ${booking.booking_number}?`}
        onConfirm={handleConfirm}
        confirmLabel="Confirm"
        loading={confirmBooking.isPending}
      />

      <Dialog open={showCancelDialog} onOpenChange={setShowCancelDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Cancel Booking</DialogTitle>
            <DialogDescription>
              Are you sure you want to cancel {booking.booking_number}?
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
                setShowCancelDialog(false)
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
        open={showMarkInProgressDialog}
        onOpenChange={setShowMarkInProgressDialog}
        title="Mark Event In Progress"
        description={`Start execution for ${booking.booking_number}?`}
        onConfirm={handleMarkInProgress}
        confirmLabel="Mark In Progress"
        loading={markInProgress.isPending}
      />

      <ConfirmDialog
        open={showMarkCompletedDialog}
        onOpenChange={setShowMarkCompletedDialog}
        title="Mark Event Complete"
        description={`Complete ${booking.booking_number}?`}
        onConfirm={handleMarkCompleted}
        confirmLabel="Mark Complete"
        loading={markCompleted.isPending}
      />
    </div>
  )
}
