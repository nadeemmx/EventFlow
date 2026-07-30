"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { PageHeader } from "@/components/common/PageHeader"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { useGenerateInvoice } from "@/hooks/use-invoices"
import { useBookings } from "@/hooks/use-bookings"
import { useToast } from "@/components/ui/toast"
import { formatINR, formatDate } from "@/lib/utils"
import { Check, ChevronsUpDown } from "lucide-react"
import { cn } from "@/lib/utils"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from "@/components/ui/command"

const formSchema = z.object({
  booking_id: z.number({ required_error: "Booking is required" }).positive(),
})

type FormValues = z.infer<typeof formSchema>

export default function NewInvoicePage() {
  const router = useRouter()
  const { toast } = useToast()
  const [bookingOpen, setBookingOpen] = useState(false)
  const [bookingSearch, setBookingSearch] = useState("")
  const [generatedInvoice, setGeneratedInvoice] = useState<any>(null)

  const generateMutation = useGenerateInvoice()
  const { data: bookingsData } = useBookings({ page: 1, page_size: 100, search: bookingSearch || undefined })

  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: { booking_id: undefined },
  })

  const bookings = bookingsData?.data ?? []
  const selectedBooking = bookings.find((b) => b.id === form.watch("booking_id"))

  async function onSubmit(values: FormValues) {
    try {
      const res = await generateMutation.mutateAsync(values.booking_id)
      toast({ title: "Invoice generated", variant: "success" })
      setGeneratedInvoice(res.data)
      router.push(`/invoices/${res.data.id}`)
    } catch {
      toast({ title: "Failed to generate invoice", variant: "destructive" })
    }
  }

  if (generatedInvoice) {
    return (
      <div className="space-y-6">
        <PageHeader title="Invoice Generated">
          <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/invoices")}>
            Back to Invoices
          </Button>
        </PageHeader>
        <Card>
          <CardHeader>
            <CardTitle>Invoice #{generatedInvoice.invoice_number}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <p className="text-sm text-muted-foreground">Booking #{generatedInvoice.booking}</p>
            <p className="text-lg font-bold">{formatINR(Number(generatedInvoice.total_amount))}</p>
            <p className="text-sm text-muted-foreground">{formatDate(generatedInvoice.created_at)}</p>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Generate Invoice">
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
                          className={cn("w-full justify-between cursor-pointer", !field.value && "text-muted-foreground")}
                        >
                          {field.value && selectedBooking
                            ? selectedBooking.booking_number
                            : "Search booking..."}
                          <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                        </Button>
                      </FormControl>
                    </PopoverTrigger>
                    <PopoverContent className="w-full p-0">
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

            <div className="flex gap-3">
              <Button type="submit" className="cursor-pointer" disabled={generateMutation.isPending}>
                {generateMutation.isPending ? "Generating..." : "Generate Invoice"}
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
