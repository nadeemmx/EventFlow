"use client"

import { useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { ArrowLeft, Edit, Trash2, Save, X, MapPin, ImageIcon } from "lucide-react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { useVenue, useUpdateVenue, useDeleteVenue } from "@/hooks/use-venues"
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
import { Separator } from "@/components/ui/separator"
import { toast } from "@/components/ui/toast"
import { formatINR, formatDate } from "@/lib/utils"
import { VENUE_TYPES } from "@/lib/constants"
import type { Venue } from "@/types/api"

const venueEditSchema = z.object({
  name: z.string().min(1, "Name is required"),
  venue_type: z.string().min(1, "Venue type is required"),
  capacity: z.coerce.number().min(1, "Capacity must be at least 1"),
  description: z.string().optional(),
  address: z.string().optional(),
  weekday_price: z.coerce.number().min(0).optional(),
  weekend_price: z.coerce.number().min(0).optional(),
  peak_price: z.coerce.number().min(0).optional(),
  status: z.string(),
})

type VenueEditValues = z.infer<typeof venueEditSchema>

export default function VenueDetailClient() {
  const params = useParams()
  const router = useRouter()
  const id = Number(params.id)
  const [editing, setEditing] = useState(false)
  const [showDeleteDialog, setShowDeleteDialog] = useState(false)

  const { data: response, isLoading, error, refetch } = useVenue(id)
  const updateVenue = useUpdateVenue(id)
  const deleteVenue = useDeleteVenue()

  const venue = response?.data as Venue | undefined

  const form = useForm<VenueEditValues>({
    resolver: zodResolver(venueEditSchema),
    values: venue
      ? {
          name: venue.name,
          venue_type: venue.venue_type,
          capacity: venue.capacity,
          description: (venue as unknown as Record<string, string>).description || "",
          address: (venue as unknown as Record<string, string>).address || "",
          weekday_price: Number(venue.weekday_price) || 0,
          weekend_price: Number(venue.weekend_price) || 0,
          peak_price: Number((venue as unknown as Record<string, string>).peak_price) || 0,
          status: venue.status,
        }
      : undefined,
  })

  const onSubmit = async (values: VenueEditValues) => {
    try {
      await updateVenue.mutateAsync(values)
      toast({ title: "Venue updated", variant: "success" })
      setEditing(false)
    } catch {
      toast({ title: "Failed to update venue", variant: "destructive" })
    }
  }

  const handleDelete = async () => {
    try {
      await deleteVenue.mutateAsync(id)
      toast({ title: "Venue deleted", variant: "success" })
      router.push("/venues")
    } catch {
      toast({ title: "Failed to delete venue", variant: "destructive" })
    }
  }

  if (isLoading) return <LoadingState type="page" />
  if (error) return <ErrorState message={(error as Error).message} onRetry={() => refetch()} />
  if (!venue) return <ErrorState message="Venue not found" />

  const images = (venue as unknown as { images?: string[] }).images

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
        <button onClick={() => router.push("/venues")} className="hover:text-foreground cursor-pointer">
          Venues
        </button>
        <span>/</span>
        <span className="text-foreground font-medium">{venue.name}</span>
      </div>

      <PageHeader title={editing ? "Edit Venue" : venue.name}>
        <Button variant="outline" className="cursor-pointer" onClick={() => router.back()}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back
        </Button>
        {!editing ? (
          <>
            <Button variant="outline" className="cursor-pointer" onClick={() => setEditing(true)}>
              <Edit className="mr-2 h-4 w-4" />
              Edit
            </Button>
            <Button
              variant="destructive"
              className="cursor-pointer"
              onClick={() => setShowDeleteDialog(true)}
            >
              <Trash2 className="mr-2 h-4 w-4" />
              Delete
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
            <Button className="cursor-pointer" onClick={form.handleSubmit(onSubmit)} disabled={updateVenue.isPending}>
              <Save className="mr-2 h-4 w-4" />
              {updateVenue.isPending ? "Saving..." : "Save"}
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
                    name="name"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Name *</FormLabel>
                        <FormControl>
                          <Input {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="venue_type"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Venue Type *</FormLabel>
                        <Select onValueChange={field.onChange} value={field.value}>
                          <FormControl>
                            <SelectTrigger className="cursor-pointer">
                              <SelectValue />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            {VENUE_TYPES.map((t) => (
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
                    name="capacity"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Capacity *</FormLabel>
                        <FormControl>
                          <Input type="number" min={1} {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="status"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Status</FormLabel>
                        <Select onValueChange={field.onChange} value={field.value}>
                          <FormControl>
                            <SelectTrigger className="cursor-pointer">
                              <SelectValue />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            <SelectItem value="ACTIVE" className="cursor-pointer">Active</SelectItem>
                            <SelectItem value="INACTIVE" className="cursor-pointer">Inactive</SelectItem>
                            <SelectItem value="MAINTENANCE" className="cursor-pointer">Maintenance</SelectItem>
                          </SelectContent>
                        </Select>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="weekday_price"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Weekday Price (₹)</FormLabel>
                        <FormControl>
                          <Input type="number" min={0} {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="weekend_price"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Weekend Price (₹)</FormLabel>
                        <FormControl>
                          <Input type="number" min={0} {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="peak_price"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Peak Season Price (₹)</FormLabel>
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
                  name="description"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Description</FormLabel>
                      <FormControl>
                        <Textarea rows={3} {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="address"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Address</FormLabel>
                      <FormControl>
                        <Textarea rows={2} {...field} />
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
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center gap-2">
                <MapPin className="h-5 w-5 text-primary" />
                Venue Details
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-muted-foreground">Name</p>
                  <p className="font-medium">{venue.name}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Type</p>
                  <p className="font-medium">{venue.venue_type.replace(/_/g, " ")}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Capacity</p>
                  <p className="font-medium">{venue.capacity.toLocaleString()}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Status</p>
                  <StatusBadge status={venue.status} type="venue" />
                </div>
              </div>
              <Separator />
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-muted-foreground">Weekday Price</p>
                  <p className="font-medium">{formatINR(Number(venue.weekday_price))}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Weekend Price</p>
                  <p className="font-medium">{formatINR(Number(venue.weekend_price))}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Peak Season Price</p>
                  <p className="font-medium">
                    {(venue as unknown as { peak_price: string }).peak_price
                      ? formatINR(Number((venue as unknown as { peak_price: string }).peak_price))
                      : "-"}
                  </p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Created At</p>
                  <p className="font-medium">{formatDate((venue as unknown as Record<string, string>).created_at || "")}</p>
                </div>
              </div>
              {(venue as unknown as Record<string, string>).address && (
                <>
                  <Separator />
                  <div>
                    <p className="text-sm text-muted-foreground">Address</p>
                    <p className="font-medium">{(venue as unknown as Record<string, string>).address}</p>
                  </div>
                </>
              )}
              {(venue as unknown as Record<string, string>).description && (
                <>
                  <Separator />
                  <div>
                    <p className="text-sm text-muted-foreground">Description</p>
                    <p className="font-medium">{(venue as unknown as Record<string, string>).description}</p>
                  </div>
                </>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center gap-2">
                <ImageIcon className="h-5 w-5 text-primary" />
                Images
              </CardTitle>
            </CardHeader>
            <CardContent>
              {images && images.length > 0 ? (
                <div className="grid grid-cols-2 gap-3">
                  {images.map((url, i) => (
                    <div key={i} className="aspect-video rounded-lg overflow-hidden border bg-muted">
                      <img
                        src={url}
                        alt={`${venue.name} ${i + 1}`}
                        className="w-full h-full object-cover"
                      />
                    </div>
                  ))}
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center py-8 text-muted-foreground">
                  <ImageIcon className="h-10 w-10 mb-2" />
                  <p className="text-sm">No images uploaded yet</p>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      )}

      <ConfirmDialog
        open={showDeleteDialog}
        onOpenChange={setShowDeleteDialog}
        title="Delete Venue"
        description={`Are you sure you want to delete "${venue.name}"? This action cannot be undone.`}
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteVenue.isPending}
      />
    </div>
  )
}
