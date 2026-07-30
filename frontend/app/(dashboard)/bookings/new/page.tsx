"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { ArrowLeft, Save, Plus, UserPlus } from "lucide-react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { useCreateBooking } from "@/hooks/use-bookings"
import { useCustomers, useCreateCustomer } from "@/hooks/use-customers"
import { useVenues } from "@/hooks/use-venues"
import { PageHeader } from "@/components/common/PageHeader"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog"
import { Label } from "@/components/ui/label"
import { toast } from "@/components/ui/toast"
import { formatINR } from "@/lib/utils"
import { EVENT_TYPES } from "@/lib/constants"

const bookingSchema = z.object({
  customer_id: z.coerce.number().min(1, "Customer is required"),
  venue_id: z.coerce.number().min(1, "Venue is required"),
  event_type: z.string().min(1, "Event type is required"),
  event_date: z.string().min(1, "Event date is required"),
  guest_count: z.coerce.number().min(1, "Guest count must be at least 1"),
  total_amount: z.coerce.number().min(0, "Total amount must be at least 0"),
  advance_amount: z.coerce.number().min(0, "Advance amount must be at least 0"),
  remarks: z.string().optional(),
})

type BookingFormValues = z.infer<typeof bookingSchema>

const customerSchema = z.object({
  full_name: z.string().min(1, "Name is required"),
  mobile: z.string().min(10, "Valid mobile number is required"),
  email: z.string().email("Invalid email").optional().or(z.literal("")),
  address: z.string().optional(),
})

type CustomerFormValues = z.infer<typeof customerSchema>

export default function NewBookingPage() {
  const router = useRouter()
  const [showCustomerDialog, setShowCustomerDialog] = useState(false)

  const createBooking = useCreateBooking()
  const createCustomer = useCreateCustomer()
  const { data: customersData } = useCustomers({ page_size: 100 })
  const { data: venuesData } = useVenues({ page_size: 100 })

  const customers = customersData?.data ?? []
  const venues = venuesData?.data ?? []

  const form = useForm<BookingFormValues>({
    resolver: zodResolver(bookingSchema),
    defaultValues: {
      customer_id: undefined as unknown as number,
      venue_id: undefined as unknown as number,
      event_type: "",
      event_date: "",
      guest_count: undefined as unknown as number,
      total_amount: undefined as unknown as number,
      advance_amount: 0,
      remarks: "",
    },
  })

  const customerForm = useForm<CustomerFormValues>({
    resolver: zodResolver(customerSchema),
    defaultValues: {
      full_name: "",
      mobile: "",
      email: "",
      address: "",
    },
  })

  const onSubmit = async (values: BookingFormValues) => {
    try {
      const res = await createBooking.mutateAsync(values)
      toast({ title: "Booking created", variant: "success" })
      const bookingId = res?.data?.id
      if (bookingId) {
        router.push(`/bookings/${bookingId}`)
      } else {
        router.push("/bookings")
      }
    } catch {
      toast({ title: "Failed to create booking", variant: "destructive" })
    }
  }

  const handleCreateCustomer = async (values: CustomerFormValues) => {
    try {
      const res = await createCustomer.mutateAsync(values as Parameters<typeof createCustomer.mutateAsync>[0])
      toast({ title: "Customer created", variant: "success" })
      setShowCustomerDialog(false)
      customerForm.reset()
      if (res?.data?.id) {
        form.setValue("customer_id", res.data.id)
      }
    } catch {
      toast({ title: "Failed to create customer", variant: "destructive" })
    }
  }

  const selectedVenue = venues.find((v) => v.id === form.watch("venue_id"))

  return (
    <div className="space-y-6">
      <PageHeader title="New Booking">
        <Button variant="outline" className="cursor-pointer" onClick={() => router.back()}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back
        </Button>
      </PageHeader>

      <Card>
        <CardContent className="pt-6">
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
              <div className="grid gap-6 md:grid-cols-2">
                <FormField
                  control={form.control}
                  name="customer_id"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Customer *</FormLabel>
                      <div className="flex gap-2">
                        <Select onValueChange={field.onChange} value={field.value ? String(field.value) : ""}>
                          <FormControl>
                            <SelectTrigger className="flex-1 cursor-pointer">
                              <SelectValue placeholder="Select customer" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            {customers.length === 0 && (
                              <SelectItem value="none" disabled className="cursor-pointer">
                                No customers found
                              </SelectItem>
                            )}
                            {customers.map((c) => (
                              <SelectItem key={c.id} value={String(c.id)} className="cursor-pointer">
                                {c.full_name} ({c.mobile})
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        <Button
                          type="button"
                          variant="outline"
                          size="icon"
                          className="cursor-pointer shrink-0"
                          onClick={() => setShowCustomerDialog(true)}
                          title="Create new customer"
                        >
                          <UserPlus className="h-4 w-4" />
                        </Button>
                      </div>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="venue_id"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Venue *</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value ? String(field.value) : ""}>
                        <FormControl>
                          <SelectTrigger className="cursor-pointer">
                            <SelectValue placeholder="Select venue">
                              {selectedVenue
                                ? `${selectedVenue.name} (Capacity: ${selectedVenue.capacity})`
                                : "Select venue"}
                            </SelectValue>
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {venues.length === 0 && (
                            <SelectItem value="none" disabled className="cursor-pointer">
                              No venues found
                            </SelectItem>
                          )}
                          {venues.map((v) => (
                            <SelectItem key={v.id} value={String(v.id)} className="cursor-pointer">
                              {v.name} — Cap: {v.capacity} | {formatINR(Number(v.weekday_price))}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      {selectedVenue && (
                        <p className="text-xs text-muted-foreground mt-1">
                          Capacity: {selectedVenue.capacity} guests | Weekday: {formatINR(Number(selectedVenue.weekday_price))} | Weekend: {formatINR(Number(selectedVenue.weekend_price))}
                        </p>
                      )}
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="event_type"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Event Type *</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value}>
                        <FormControl>
                          <SelectTrigger className="cursor-pointer">
                            <SelectValue placeholder="Select event type" />
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
                      <FormLabel>Event Date *</FormLabel>
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
                      <FormLabel>Guest Count *</FormLabel>
                      <FormControl>
                        <Input type="number" min={1} placeholder="100" {...field} />
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
                      <FormLabel>Total Amount (₹) *</FormLabel>
                      <FormControl>
                        <Input type="number" min={0} placeholder="50000" {...field} />
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
                        <Input type="number" min={0} placeholder="10000" {...field} />
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
                      <Textarea rows={3} placeholder="Special requests, notes..." {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="flex gap-3 justify-end">
                <Button
                  type="button"
                  variant="outline"
                  className="cursor-pointer"
                  onClick={() => router.back()}
                >
                  Cancel
                </Button>
                <Button type="submit" className="cursor-pointer" disabled={createBooking.isPending}>
                  <Save className="mr-2 h-4 w-4" />
                  {createBooking.isPending ? "Creating..." : "Create Booking"}
                </Button>
              </div>
            </form>
          </Form>
        </CardContent>
      </Card>

      <Dialog open={showCustomerDialog} onOpenChange={setShowCustomerDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create New Customer</DialogTitle>
            <DialogDescription>
              Add a new customer quickly. They will be available in the customer dropdown.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={customerForm.handleSubmit(handleCreateCustomer)} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="full_name">Full Name *</Label>
              <Input
                id="full_name"
                placeholder="John Doe"
                {...customerForm.register("full_name")}
              />
              {customerForm.formState.errors.full_name && (
                <p className="text-sm text-destructive">{customerForm.formState.errors.full_name.message}</p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="mobile">Mobile *</Label>
              <Input
                id="mobile"
                placeholder="9876543210"
                {...customerForm.register("mobile")}
              />
              {customerForm.formState.errors.mobile && (
                <p className="text-sm text-destructive">{customerForm.formState.errors.mobile.message}</p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="john@example.com"
                {...customerForm.register("email")}
              />
              {customerForm.formState.errors.email && (
                <p className="text-sm text-destructive">{customerForm.formState.errors.email.message}</p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="address">Address</Label>
              <Textarea
                id="address"
                rows={2}
                placeholder="Customer address..."
                {...customerForm.register("address")}
              />
            </div>
            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                className="cursor-pointer"
                onClick={() => setShowCustomerDialog(false)}
              >
                Cancel
              </Button>
              <Button type="submit" className="cursor-pointer" disabled={createCustomer.isPending}>
                <Plus className="mr-2 h-4 w-4" />
                {createCustomer.isPending ? "Creating..." : "Create Customer"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  )
}
