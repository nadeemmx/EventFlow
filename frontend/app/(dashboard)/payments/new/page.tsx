"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { PageHeader } from "@/components/common/PageHeader"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { useCreatePayment } from "@/hooks/use-payments"
import { useBookings } from "@/hooks/use-bookings"
import { useToast } from "@/components/ui/toast"
import { PAYMENT_METHODS } from "@/lib/constants"
import { Check, ChevronsUpDown } from "lucide-react"
import { cn } from "@/lib/utils"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from "@/components/ui/command"

const formSchema = z.object({
  booking_id: z.number({ required_error: "Booking is required" }).positive(),
  amount: z.number({ required_error: "Amount is required" }).positive(),
  payment_method: z.string({ required_error: "Payment method is required" }),
  transaction_reference: z.string().optional(),
  payment_date: z.string({ required_error: "Payment date is required" }).min(1),
  notes: z.string().optional(),
})

type FormValues = z.infer<typeof formSchema>

export default function NewPaymentPage() {
  const router = useRouter()
  const { toast } = useToast()
  const [bookingOpen, setBookingOpen] = useState(false)
  const [bookingSearch, setBookingSearch] = useState("")

  const createMutation = useCreatePayment()
  const { data: bookingsData } = useBookings({ page: 1, page_size: 100, search: bookingSearch || undefined })

  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      booking_id: undefined,
      amount: undefined,
      payment_method: undefined,
      transaction_reference: "",
      payment_date: new Date().toISOString().split("T")[0],
      notes: "",
    },
  })

  const bookings = bookingsData?.data ?? []

  const selectedBooking = bookings.find((b) => b.id === form.watch("booking_id"))

  async function onSubmit(values: FormValues) {
    try {
      const res = await createMutation.mutateAsync({
        booking_id: values.booking_id,
        amount: values.amount,
        payment_method: values.payment_method,
        transaction_reference: values.transaction_reference || undefined,
        payment_date: values.payment_date,
        notes: values.notes || undefined,
      })
      toast({ title: "Payment recorded", variant: "success" })
      router.push("/payments")
    } catch {
      toast({ title: "Failed to record payment", variant: "destructive" })
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Record Payment">
        <Button variant="outline" className="cursor-pointer" onClick={() => router.back()}>
          Back
        </Button>
      </PageHeader>

      <div className="max-w-2xl">
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            <FormField
              control={form.control}
              name="booking_id"
              render={({ field }) => (
                <FormItem className="flex flex-col">
                  <FormLabel>Booking</FormLabel>
                  <Popover open={bookingOpen} onOpenChange={setBookingOpen}>
                    <PopoverTrigger asChild>
                      <FormControl>
                        <Button
                          variant="outline"
                          role="combobox"
                          aria-expanded={bookingOpen}
                          aria-controls="payment-booking-listbox"
                          aria-autocomplete="list"
                          className={cn("w-full justify-between cursor-pointer", !field.value && "text-muted-foreground")}
                        >
                          {field.value && selectedBooking
                            ? selectedBooking.booking_number
                            : "Search booking..."}
                          <ChevronsUpDown aria-hidden="true" focusable="false" className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                        </Button>
                      </FormControl>
                    </PopoverTrigger>
                    <PopoverContent id="payment-booking-listbox" className="w-full p-0">
                      <Command>
                        <CommandInput
                          placeholder="Search by booking number..."
                          value={bookingSearch}
                          onValueChange={setBookingSearch}
                        />
                        <CommandList>
                          <CommandEmpty>No bookings found.</CommandEmpty>
                          <CommandGroup>
                            {bookings.map((booking) => (
                              <CommandItem
                                key={booking.id}
                                value={String(booking.id)}
                                onSelect={() => {
                                  form.setValue("booking_id", booking.id)
                                  setBookingOpen(false)
                                }}
                                className="cursor-pointer"
                              >
                                <Check
                                  aria-hidden="true"
                                  focusable="false"
                                  className={cn(
                                    "mr-2 h-4 w-4",
                                    booking.id === field.value ? "opacity-100" : "opacity-0"
                                  )}
                                />
                                {booking.booking_number}
                              </CommandItem>
                            ))}
                          </CommandGroup>
                        </CommandList>
                      </Command>
                    </PopoverContent>
                  </Popover>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="amount"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Amount (₹)</FormLabel>
                  <FormControl>
                    <Input
                      type="number"
                      step="0.01"
                      placeholder="0.00"
                      className="cursor-pointer"
                      onChange={(e) => field.onChange(e.target.value ? Number(e.target.value) : undefined)}
                      value={field.value ?? ""}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="payment_method"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Payment Method</FormLabel>
                  <Select onValueChange={field.onChange} value={field.value}>
                    <FormControl>
                      <SelectTrigger className="cursor-pointer">
                        <SelectValue placeholder="Select payment method" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {PAYMENT_METHODS.map((method) => (
                        <SelectItem key={method} value={method} className="cursor-pointer">
                          {method.replace(/_/g, " ")}
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
              name="transaction_reference"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Transaction Reference</FormLabel>
                  <FormControl>
                    <Input placeholder="Optional reference" {...field} className="cursor-pointer" />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="payment_date"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Payment Date</FormLabel>
                  <FormControl>
                    <Input type="date" {...field} className="cursor-pointer" />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="notes"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Notes</FormLabel>
                  <FormControl>
                    <Textarea placeholder="Optional notes" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <div className="flex gap-3">
              <Button type="submit" className="cursor-pointer" disabled={createMutation.isPending}>
                {createMutation.isPending ? "Recording..." : "Record Payment"}
              </Button>
              <Button type="button" variant="outline" className="cursor-pointer" onClick={() => router.back()}>
                Cancel
              </Button>
            </div>
          </form>
        </Form>
      </div>
    </div>
  )
}
