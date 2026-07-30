"use client"

import { useRouter } from "next/navigation"
import { ArrowLeft, Save } from "lucide-react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { useCreateVenue } from "@/hooks/use-venues"
import { PageHeader } from "@/components/common/PageHeader"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Card, CardContent } from "@/components/ui/card"
import { toast } from "@/components/ui/toast"
import { VENUE_TYPES } from "@/lib/constants"

const venueSchema = z.object({
  name: z.string().min(1, "Name is required"),
  venue_type: z.string().min(1, "Venue type is required"),
  capacity: z.coerce.number().min(1, "Capacity must be at least 1"),
  description: z.string().optional(),
  address: z.string().optional(),
  weekday_price: z.coerce.number().min(0).optional(),
  weekend_price: z.coerce.number().min(0).optional(),
  peak_price: z.coerce.number().min(0).optional(),
  status: z.string().default("ACTIVE"),
})

type VenueFormValues = z.infer<typeof venueSchema>

export default function NewVenuePage() {
  const router = useRouter()
  const createVenue = useCreateVenue()

  const form = useForm<VenueFormValues>({
    resolver: zodResolver(venueSchema),
    defaultValues: {
      name: "",
      venue_type: "",
      capacity: undefined as unknown as number,
      description: "",
      address: "",
      weekday_price: undefined as unknown as number,
      weekend_price: undefined as unknown as number,
      peak_price: undefined as unknown as number,
      status: "ACTIVE",
    },
  })

  const onSubmit = async (values: VenueFormValues) => {
    try {
      await createVenue.mutateAsync(values)
      toast({ title: "Venue created successfully", variant: "success" })
      router.push("/venues")
    } catch {
      toast({ title: "Failed to create venue", variant: "destructive" })
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Add Venue">
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
                  name="name"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Name *</FormLabel>
                      <FormControl>
                        <Input placeholder="Grand Ballroom" {...field} />
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
                            <SelectValue placeholder="Select type" />
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
                        <Input type="number" min={1} placeholder="500" {...field} />
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
                            <SelectValue placeholder="Select status" />
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
                        <Input type="number" min={0} placeholder="50000" {...field} />
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
                        <Input type="number" min={0} placeholder="75000" {...field} />
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
                        <Input type="number" min={0} placeholder="100000" {...field} />
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
                      <Textarea rows={3} placeholder="Describe the venue..." {...field} />
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
                      <Textarea rows={2} placeholder="Venue address..." {...field} />
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
                <Button type="submit" className="cursor-pointer" disabled={createVenue.isPending}>
                  <Save className="mr-2 h-4 w-4" />
                  {createVenue.isPending ? "Saving..." : "Save Venue"}
                </Button>
              </div>
            </form>
          </Form>
        </CardContent>
      </Card>
    </div>
  )
}
