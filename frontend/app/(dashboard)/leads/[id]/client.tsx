"use client"

import { useState, useEffect } from "react"
import { useParams, useRouter } from "next/navigation"
import Link from "next/link"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import {
  ArrowLeft,
  Pencil,
  Trash2,
  Save,
  X,
  Calendar,
  Target,
  Phone,
  User,
  ArrowRight,
  Plus,
  MessageSquare,
} from "lucide-react"

import {
  useLead,
  useUpdateLead,
  useDeleteLead,
  useConvertLead,
  useLeadFollowups,
  useAddFollowup,
} from "@/hooks/use-leads"
import { EVENT_TYPES, LEAD_STATUSES } from "@/lib/constants"
import { formatDate, formatDateTime } from "@/lib/utils"
import { PageHeader } from "@/components/common/PageHeader"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { useToast } from "@/components/ui/toast"

const leadEditSchema = z.object({
  lead_source: z.string().min(1, "Lead source is required"),
  event_type: z.string().min(1, "Event type is required"),
  lead_status: z.string().min(1, "Lead status is required"),
})

type LeadEditForm = z.infer<typeof leadEditSchema>

const followupSchema = z.object({
  followup_date: z.string().min(1, "Date is required"),
  notes: z.string().min(1, "Notes are required"),
  next_action: z.string().optional(),
})

type FollowupForm = z.infer<typeof followupSchema>

const LEAD_SOURCES = [
  "REFERRAL",
  "WEBSITE",
  "SOCIAL_MEDIA",
  "WALK_IN",
  "PHONE_INQUIRY",
  "EVENT",
  "OTHER",
] as const

export default function LeadDetailClient() {
  const params = useParams()
  const router = useRouter()
  const { toast } = useToast()
  const id = Number(params.id)
  const [editing, setEditing] = useState(false)
  const [deleteOpen, setDeleteOpen] = useState(false)
  const [convertOpen, setConvertOpen] = useState(false)
  const [followupOpen, setFollowupOpen] = useState(false)

  const { data, isLoading, error, refetch } = useLead(id)
  const updateMutation = useUpdateLead(id)
  const deleteMutation = useDeleteLead()
  const convertMutation = useConvertLead()
  const { data: followupsData, isLoading: followupsLoading } = useLeadFollowups(id)
  const addFollowupMutation = useAddFollowup(id)

  const lead = data?.data as
    | (Record<string, unknown> & {
        id: number
        customer: number
        customer_name?: string
        lead_source: string
        event_type: string
        lead_status: string
        assigned_to?: number | null
        assigned_to_name?: string
        expected_event_date?: string
        expected_guest_count?: number
        created_at: string
        updated_at?: string
      })
    | undefined

  const followups = (followupsData?.data || []) as Array<{
    id: number
    followup_date: string
    notes: string
    next_action: string
    created_at: string
  }>

  const {
    register: editRegister,
    handleSubmit: handleEditSubmit,
    reset: resetEdit,
    setValue: setEditValue,
    formState: { errors: editErrors, isSubmitting: isEditSubmitting },
  } = useForm<LeadEditForm>({
    resolver: zodResolver(leadEditSchema),
  })

  const {
    register: followupRegister,
    handleSubmit: handleFollowupSubmit,
    reset: resetFollowup,
    formState: { errors: followupErrors, isSubmitting: isFollowupSubmitting },
  } = useForm<FollowupForm>({
    resolver: zodResolver(followupSchema),
  })

  useEffect(() => {
    if (lead && editing) {
      resetEdit({
        lead_source: lead.lead_source || "",
        event_type: lead.event_type || "",
        lead_status: lead.lead_status || "",
      })
    }
  }, [lead, editing, resetEdit])

  const onEditSubmit = async (formData: LeadEditForm) => {
    try {
      await updateMutation.mutateAsync(formData)
      toast({ title: "Lead updated", variant: "success" })
      setEditing(false)
    } catch {
      toast({ title: "Failed to update lead", variant: "destructive" })
    }
  }

  const handleDelete = async () => {
    try {
      await deleteMutation.mutateAsync(id)
      toast({ title: "Lead deleted", variant: "success" })
      router.push("/leads")
    } catch {
      toast({ title: "Failed to delete lead", variant: "destructive" })
    }
  }

  const handleConvert = async () => {
    try {
      const result = await convertMutation.mutateAsync(id)
      const bookingId = result?.data?.booking_id
      toast({ title: "Lead converted", description: "Lead has been converted to a booking.", variant: "success" })
      setConvertOpen(false)
      if (bookingId) {
        router.push(`/bookings/${bookingId}`)
      } else {
        router.push("/bookings")
      }
    } catch {
      toast({ title: "Failed to convert lead", variant: "destructive" })
    }
  }

  const onFollowupSubmit = async (formData: FollowupForm) => {
    try {
      await addFollowupMutation.mutateAsync(formData)
      toast({ title: "Followup added", variant: "success" })
      setFollowupOpen(false)
      resetFollowup()
    } catch {
      toast({ title: "Failed to add followup", variant: "destructive" })
    }
  }

  const canConvert = lead ? !["CONVERTED", "LOST"].includes(lead.lead_status) : false

  if (isLoading) return <LoadingState type="page" />
  if (error) return <ErrorState message={(error as Error).message} onRetry={() => refetch()} />
  if (!lead) return <ErrorState message="Lead not found" />

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
        <Link href="/leads" className="hover:text-foreground">
          Leads
        </Link>
        <span>/</span>
        <span className="text-foreground font-medium truncate">
          {lead.customer_name || `Lead #${lead.id}`}
        </span>
      </div>

      <PageHeader title={lead.customer_name || `Lead #${lead.id}`}>
        <div className="flex gap-2">
          <Button variant="outline" asChild className="cursor-pointer">
            <Link href="/leads">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back
            </Link>
          </Button>
          {editing ? (
            <>
              <Button
                variant="outline"
                onClick={() => setEditing(false)}
                className="cursor-pointer"
              >
                <X className="h-4 w-4 mr-2" />
                Cancel
              </Button>
              <Button
                onClick={handleEditSubmit(onEditSubmit)}
                disabled={isEditSubmitting}
                className="cursor-pointer"
              >
                <Save className="h-4 w-4 mr-2" />
                Save
              </Button>
            </>
          ) : (
            <>
              <Button
                variant="outline"
                onClick={() => setEditing(true)}
                className="cursor-pointer"
              >
                <Pencil className="h-4 w-4 mr-2" />
                Edit
              </Button>
              {canConvert && (
                <Button
                  variant="default"
                  onClick={() => setConvertOpen(true)}
                  className="cursor-pointer"
                >
                  <ArrowRight className="h-4 w-4 mr-2" />
                  Convert
                </Button>
              )}
              <Button
                variant="destructive"
                onClick={() => setDeleteOpen(true)}
                className="cursor-pointer"
              >
                <Trash2 className="h-4 w-4 mr-2" />
                Delete
              </Button>
            </>
          )}
        </div>
      </PageHeader>

      {editing ? (
        <Card>
          <CardContent className="pt-6">
            <form onSubmit={handleEditSubmit(onEditSubmit)} className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="lead_source">Lead Source</Label>
                  <Select
                    defaultValue={lead.lead_source}
                    onValueChange={(v) =>
                      setEditValue("lead_source", v, { shouldValidate: true })
                    }
                  >
                    <SelectTrigger id="lead_source" className="cursor-pointer">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {LEAD_SOURCES.map((s) => (
                        <SelectItem key={s} value={s}>
                          {s.replace(/_/g, " ")}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  {editErrors.lead_source && (
                    <p className="text-sm text-destructive">{editErrors.lead_source.message}</p>
                  )}
                </div>
                <div className="space-y-2">
                  <Label htmlFor="event_type">Event Type</Label>
                  <Select
                    defaultValue={lead.event_type}
                    onValueChange={(v) =>
                      setEditValue("event_type", v, { shouldValidate: true })
                    }
                  >
                    <SelectTrigger id="event_type" className="cursor-pointer">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {EVENT_TYPES.map((t) => (
                        <SelectItem key={t} value={t}>
                          {t.replace(/_/g, " ")}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  {editErrors.event_type && (
                    <p className="text-sm text-destructive">{editErrors.event_type.message}</p>
                  )}
                </div>
                <div className="space-y-2">
                  <Label htmlFor="lead_status">Lead Status</Label>
                  <Select
                    defaultValue={lead.lead_status}
                    onValueChange={(v) =>
                      setEditValue("lead_status", v, { shouldValidate: true })
                    }
                  >
                    <SelectTrigger id="lead_status" className="cursor-pointer">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {LEAD_STATUSES.map((s) => (
                        <SelectItem key={s} value={s}>
                          {s.replace(/_/g, " ")}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  {editErrors.lead_status && (
                    <p className="text-sm text-destructive">{editErrors.lead_status.message}</p>
                  )}
                </div>
              </div>
            </form>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Lead Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-start gap-3">
                <User className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium">Customer</p>
                  <p className="text-sm text-muted-foreground">
                    {lead.customer_name || `ID: ${lead.customer}`}
                  </p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <Target className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium">Event Type</p>
                  <p className="text-sm text-muted-foreground">
                    {lead.event_type.replace(/_/g, " ")}
                  </p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <Phone className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium">Lead Source</p>
                  <p className="text-sm text-muted-foreground">
                    {lead.lead_source.replace(/_/g, " ")}
                  </p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="mt-0.5 shrink-0">
                  <StatusBadge status={lead.lead_status} type="lead" />
                </div>
                <div>
                  <p className="text-sm font-medium">Status</p>
                  <p className="text-sm text-muted-foreground">
                    {lead.lead_status.replace(/_/g, " ")}
                  </p>
                </div>
              </div>
              {lead.assigned_to_name && (
                <div className="flex items-start gap-3">
                  <User className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                  <div>
                    <p className="text-sm font-medium">Assigned To</p>
                    <p className="text-sm text-muted-foreground">
                      {lead.assigned_to_name}
                    </p>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Event Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {lead.expected_event_date && (
                <div className="flex items-start gap-3">
                  <Calendar className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                  <div>
                    <p className="text-sm font-medium">Expected Event Date</p>
                    <p className="text-sm text-muted-foreground">
                      {formatDate(lead.expected_event_date)}
                    </p>
                  </div>
                </div>
              )}
              {lead.expected_guest_count && (
                <div className="flex items-start gap-3">
                  <User className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                  <div>
                    <p className="text-sm font-medium">Expected Guest Count</p>
                    <p className="text-sm text-muted-foreground">
                      {lead.expected_guest_count}
                    </p>
                  </div>
                </div>
              )}
              <div className="flex items-start gap-3">
                <Calendar className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium">Created</p>
                  <p className="text-sm text-muted-foreground">
                    {formatDateTime(lead.created_at)}
                  </p>
                </div>
              </div>
              {lead.updated_at && (
                <div className="flex items-start gap-3">
                  <Calendar className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                  <div>
                    <p className="text-sm font-medium">Last Updated</p>
                    <p className="text-sm text-muted-foreground">
                      {formatDateTime(lead.updated_at)}
                    </p>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      )}

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-lg">Followups</CardTitle>
          <Dialog open={followupOpen} onOpenChange={setFollowupOpen}>
            <DialogTrigger asChild>
              <Button size="sm" className="cursor-pointer">
                <Plus className="h-4 w-4 mr-2" />
                Add Followup
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Add Followup</DialogTitle>
                <DialogDescription>
                  Schedule a follow-up activity for this lead.
                </DialogDescription>
              </DialogHeader>
              <form
                onSubmit={handleFollowupSubmit(onFollowupSubmit)}
                className="space-y-4"
              >
                <div className="space-y-2">
                  <Label htmlFor="followup_date">Followup Date</Label>
                  <Input
                    id="followup_date"
                    type="date"
                    {...followupRegister("followup_date")}
                  />
                  {followupErrors.followup_date && (
                    <p className="text-sm text-destructive">
                      {followupErrors.followup_date.message}
                    </p>
                  )}
                </div>
                <div className="space-y-2">
                  <Label htmlFor="notes">Notes</Label>
                  <Textarea
                    id="notes"
                    rows={3}
                    placeholder="Details about the followup..."
                    {...followupRegister("notes")}
                  />
                  {followupErrors.notes && (
                    <p className="text-sm text-destructive">
                      {followupErrors.notes.message}
                    </p>
                  )}
                </div>
                <div className="space-y-2">
                  <Label htmlFor="next_action">Next Action</Label>
                  <Textarea
                    id="next_action"
                    rows={2}
                    placeholder="What needs to happen next..."
                    {...followupRegister("next_action")}
                  />
                </div>
                <DialogFooter>
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => setFollowupOpen(false)}
                    className="cursor-pointer"
                  >
                    Cancel
                  </Button>
                  <Button
                    type="submit"
                    disabled={isFollowupSubmitting}
                    className="cursor-pointer"
                  >
                    {isFollowupSubmitting ? "Saving..." : "Save Followup"}
                  </Button>
                </DialogFooter>
              </form>
            </DialogContent>
          </Dialog>
        </CardHeader>
        <CardContent>
          {followupsLoading ? (
            <div className="text-sm text-muted-foreground">Loading followups...</div>
          ) : followups.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-8 text-center">
              <MessageSquare className="h-8 w-8 text-muted-foreground mb-2" />
              <p className="text-sm text-muted-foreground">No followups yet</p>
              <p className="text-xs text-muted-foreground mt-1">
                Schedule your first follow-up activity.
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {followups.map((followup) => (
                <div
                  key={followup.id}
                  className="flex gap-4 p-4 rounded-lg border"
                >
                  <div className="flex flex-col items-center gap-1">
                    <div className="w-2 h-2 rounded-full bg-primary mt-2" />
                    <div className="w-px flex-1 bg-border" />
                  </div>
                  <div className="flex-1 space-y-1 min-w-0">
                    <div className="flex items-center gap-2 text-sm">
                      <Calendar className="h-3.5 w-3.5 text-muted-foreground" />
                      <span className="font-medium">
                        {formatDate(followup.followup_date)}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        &middot; {formatDateTime(followup.created_at)}
                      </span>
                    </div>
                    <p className="text-sm">{followup.notes}</p>
                    {followup.next_action && (
                      <div className="flex items-start gap-1.5 pt-1">
                        <ArrowRight className="h-3.5 w-3.5 text-muted-foreground mt-0.5 shrink-0" />
                        <p className="text-sm text-muted-foreground">
                          {followup.next_action}
                        </p>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      <ConfirmDialog
        open={deleteOpen}
        onOpenChange={setDeleteOpen}
        title="Delete Lead"
        description="Are you sure you want to delete this lead? This action cannot be undone."
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteMutation.isPending}
      />

      <ConfirmDialog
        open={convertOpen}
        onOpenChange={setConvertOpen}
        title="Convert Lead"
        description="Convert this lead to a booking? This will create a new booking from this lead."
        onConfirm={handleConvert}
        confirmLabel="Convert to Booking"
        loading={convertMutation.isPending}
      />
    </div>
  )
}
