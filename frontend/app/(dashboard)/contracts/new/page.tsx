"use client"

import { useRouter } from "next/navigation"
import { ArrowLeft, Save } from "lucide-react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { useGenerateContract } from "@/hooks/use-contracts"
import { useBookings } from "@/hooks/use-bookings"
import { PageHeader } from "@/components/common/PageHeader"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Card, CardContent } from "@/components/ui/card"
import { toast } from "@/components/ui/toast"
import { formatDate } from "@/lib/utils"
import type { Booking } from "@/types/api"

const contractSchema = z.object({
  booking_id: z.coerce.number().min(1, "Booking is required"),
  valid_from: z.string().min(1, "Valid from date is required"),
  valid_until: z.string().min(1, "Valid until date is required"),
  notes: z.string().optional(),
})

type ContractFormValues = z.infer<typeof contractSchema>

export default function NewContractPage() {
  const router = useRouter()

  const generateContract = useGenerateContract()
  const { data: bookingsData } = useBookings({ page_size: 100 })

  const bookings = bookingsData?.data ?? []

  const form = useForm<ContractFormValues>({
    resolver: zodResolver(contractSchema),
    defaultValues: {
      booking_id: undefined as unknown as number,
      valid_from: "",
      valid_until: "",
      notes: "",
    },
  })

  const onSubmit = async (values: ContractFormValues) => {
    try {
      const res = await generateContract.mutateAsync(values)
      toast({ title: "Contract generated", variant: "success" })
      const contractId = res?.data?.id
      if (contractId) {
        router.push(`/contracts/${contractId}`)
      } else {
        router.push("/contracts")
      }
    } catch {
      toast({ title: "Failed to generate contract", variant: "destructive" })
    }
  }

  const today = new Date().toISOString().split("T")[0]

  return (
    <div className="space-y-6">
      <PageHeader title="Generate Contract">
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
                  name="booking_id"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Booking *</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value ? String(field.value) : ""}>
                        <FormControl>
                          <SelectTrigger className="cursor-pointer">
                            <SelectValue placeholder="Select booking" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {bookings.length === 0 && (
                            <SelectItem value="none" disabled className="cursor-pointer">
                              No bookings found
                            </SelectItem>
                          )}
                          {bookings.map((b) => (
                            <SelectItem key={b.id} value={String(b.id)} className="cursor-pointer">
                              {(b as unknown as Booking).booking_number} — {(b as unknown as Booking).customer_name || `Customer #${(b as unknown as Booking).customer}`}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <div>
                  <p className="text-sm text-muted-foreground mb-1">Event Date</p>
                  <p className="text-sm font-medium">
                    {bookings.length > 0 && form.watch("booking_id")
                      ? formatDate(
                          (bookings.find((b) => b.id === form.watch("booking_id")) as unknown as Booking)
                            ?.event_date ?? ""
                        )
                      : "-"}
                  </p>
                </div>

                <FormField
                  control={form.control}
                  name="valid_from"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Valid From *</FormLabel>
                      <FormControl>
                        <Input type="date" min={today} {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="valid_until"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Valid Until *</FormLabel>
                      <FormControl>
                        <Input type="date" min={today} {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <FormField
                control={form.control}
                name="notes"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Notes</FormLabel>
                    <FormControl>
                      <Textarea rows={3} placeholder="Additional notes for the contract..." {...field} />
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
                <Button type="submit" className="cursor-pointer" disabled={generateContract.isPending}>
                  <Save className="mr-2 h-4 w-4" />
                  {generateContract.isPending ? "Generating..." : "Generate Contract"}
                </Button>
              </div>
            </form>
          </Form>
        </CardContent>
      </Card>
    </div>
  )
}
