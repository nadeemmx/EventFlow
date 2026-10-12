"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import Link from "next/link"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { ArrowLeft, Save, ChevronsUpDown, Check } from "lucide-react"

import { useCreateLead } from "@/hooks/use-leads"
import { useCustomers } from "@/hooks/use-customers"
import { EVENT_TYPES, LEAD_STATUSES } from "@/lib/constants"
import { PageHeader } from "@/components/common/PageHeader"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent } from "@/components/ui/card"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover"
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command"
import { cn } from "@/lib/utils"
import { useToast } from "@/components/ui/toast"

const LEAD_SOURCES = [
  "WEBSITE",
  "GOOGLE",
  "FACEBOOK",
  "INSTAGRAM",
  "WHATSAPP",
  "WALK_IN",
  "REFERRAL",
] as const

const leadSchema = z.object({
  customer_id: z.number({ required_error: "Please select a customer" }),
  lead_source: z.string().min(1, "Lead source is required"),
  event_type: z.string().min(1, "Event type is required"),
  expected_event_date: z.string().min(1, "Expected event date is required"),
  expected_guest_count: z.coerce.number().min(1, "Guest count must be at least 1"),
  lead_status: z.string().min(1, "Lead status is required"),
  assigned_to: z.number().nullable().optional(),
})

type LeadForm = z.infer<typeof leadSchema>

export default function NewLeadPage() {
  const router = useRouter()
  const { toast } = useToast()
  const createLead = useCreateLead()
  const [customerSearch, setCustomerSearch] = useState("")
  const [customerOpen, setCustomerOpen] = useState(false)
  const [selectedCustomerName, setSelectedCustomerName] = useState("")

  const { data: customersData } = useCustomers({
    search: customerSearch || undefined,
    page_size: 50,
  })

  const customers = customersData?.data || []

  const {
    register,
    handleSubmit,
    setValue,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<LeadForm>({
    resolver: zodResolver(leadSchema),
    defaultValues: {
      lead_status: "NEW",
      expected_guest_count: 1,
    },
  })

  const onSubmit = async (data: LeadForm) => {
    try {
      await createLead.mutateAsync({
        customer_id: data.customer_id,
        lead_source: data.lead_source,
        event_type: data.event_type,
        expected_event_date: data.expected_event_date,
        expected_guest_count: data.expected_guest_count,
        lead_status: data.lead_status,
        assigned_to: data.assigned_to ?? null,
      })
      toast({ title: "Lead created", description: "Lead has been added successfully.", variant: "success" })
      router.push("/leads")
    } catch (err: unknown) {
      const message =
        err && typeof err === "object" && "response" in err
          ? (err as { response: { data: { message: string } } }).response?.data?.message
          : "Failed to create lead"
      toast({ title: "Error", description: message, variant: "destructive" })
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Add Lead">
        <Button variant="outline" asChild className="cursor-pointer">
          <Link href="/leads">
            <ArrowLeft aria-hidden="true" focusable="false" className="h-4 w-4 mr-2" />
            Back
          </Link>
        </Button>
      </PageHeader>

      <Card>
        <CardContent className="pt-6">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="lead-customer" id="lead-customer-label">
                  Customer <span className="text-destructive">*</span>
                </Label>
                <Popover open={customerOpen} onOpenChange={setCustomerOpen}>
                  <PopoverTrigger asChild>
                    <Button
                      id="lead-customer"
                      variant="outline"
                      role="combobox"
                      aria-expanded={customerOpen}
                      aria-controls="lead-customer-listbox"
                      aria-labelledby="lead-customer-label"
                      aria-autocomplete="list"
                      aria-invalid={errors.customer_id ? true : undefined}
                      aria-describedby={errors.customer_id ? "customer-id-error" : undefined}
                      className="w-full justify-between font-normal cursor-pointer"
                    >
                      {selectedCustomerName || "Search for a customer..."}
                      <ChevronsUpDown aria-hidden="true" focusable="false" className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent id="lead-customer-listbox" className="w-[--radix-popover-trigger-width] p-0">
                    <Command>
                      <CommandInput
                        placeholder="Search customers..."
                        value={customerSearch}
                        onValueChange={setCustomerSearch}
                      />
                      <CommandList>
                        <CommandEmpty>
                          <div className="py-4 text-center space-y-2">
                            <p className="text-sm text-muted-foreground">No customer found</p>
                            <Link
                              href="/customers/new"
                              className="text-sm text-primary hover:underline"
                              onClick={() => setCustomerOpen(false)}
                            >
                              Create New Customer
                            </Link>
                          </div>
                        </CommandEmpty>
                        <CommandGroup>
                          {customers.map((customer) => (
                            <CommandItem
                              key={customer.id}
                              value={String(customer.id)}
                              onSelect={() => {
                                setValue("customer_id", customer.id, { shouldValidate: true })
                                setSelectedCustomerName(customer.full_name)
                                setCustomerOpen(false)
                              }}
                              className="cursor-pointer"
                            >
                              <Check
                                aria-hidden="true"
                                focusable="false"
                                className={cn(
                                  "mr-2 h-4 w-4",
                                  watch("customer_id") === customer.id
                                    ? "opacity-100"
                                    : "opacity-0"
                                )}
                              />
                              <div>
                                <p className="text-sm font-medium">{customer.full_name}</p>
                                <p className="text-xs text-muted-foreground">{customer.mobile}</p>
                              </div>
                            </CommandItem>
                          ))}
                        </CommandGroup>
                      </CommandList>
                    </Command>
                  </PopoverContent>
                </Popover>
                {errors.customer_id && (
                  <p id="customer-id-error" role="alert" className="text-sm text-destructive">
                    {errors.customer_id.message}
                  </p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="event_type">
                  Event Type <span className="text-destructive">*</span>
                </Label>
                <Select
                  onValueChange={(v) => setValue("event_type", v, { shouldValidate: true })}
                >
                  <SelectTrigger
                    id="event_type"
                    aria-invalid={errors.event_type ? true : undefined}
                    aria-describedby={errors.event_type ? "event-type-error" : undefined}
                    className="cursor-pointer"
                  >
                    <SelectValue placeholder="Select event type" />
                  </SelectTrigger>
                  <SelectContent>
                    {EVENT_TYPES.map((type) => (
                      <SelectItem key={type} value={type}>
                        {type.replace(/_/g, " ")}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.event_type && (
                  <p id="event-type-error" role="alert" className="text-sm text-destructive">
                    {errors.event_type.message}
                  </p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="lead_source">
                  Lead Source <span className="text-destructive">*</span>
                </Label>
                <Select
                  onValueChange={(v) => setValue("lead_source", v, { shouldValidate: true })}
                >
                  <SelectTrigger
                    id="lead_source"
                    aria-invalid={errors.lead_source ? true : undefined}
                    aria-describedby={errors.lead_source ? "lead-source-error" : undefined}
                    className="cursor-pointer"
                  >
                    <SelectValue placeholder="Select source" />
                  </SelectTrigger>
                  <SelectContent>
                    {LEAD_SOURCES.map((source) => (
                      <SelectItem key={source} value={source}>
                        {source.replace(/_/g, " ")}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.lead_source && (
                  <p id="lead-source-error" role="alert" className="text-sm text-destructive">
                    {errors.lead_source.message}
                  </p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="lead_status">
                  Lead Status <span className="text-destructive">*</span>
                </Label>
                <Select
                  defaultValue="NEW"
                  onValueChange={(v) => setValue("lead_status", v, { shouldValidate: true })}
                >
                  <SelectTrigger
                    id="lead_status"
                    aria-invalid={errors.lead_status ? true : undefined}
                    aria-describedby={errors.lead_status ? "lead-status-error" : undefined}
                    className="cursor-pointer"
                  >
                    <SelectValue placeholder="Select status" />
                  </SelectTrigger>
                  <SelectContent>
                    {LEAD_STATUSES.map((status) => (
                      <SelectItem key={status} value={status}>
                        {status.replace(/_/g, " ")}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.lead_status && (
                  <p id="lead-status-error" role="alert" className="text-sm text-destructive">
                    {errors.lead_status.message}
                  </p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="expected_event_date">
                  Expected Event Date <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="expected_event_date"
                  type="date"
                  aria-invalid={errors.expected_event_date ? true : undefined}
                  aria-describedby={errors.expected_event_date ? "expected-event-date-error" : undefined}
                  {...register("expected_event_date")}
                />
                {errors.expected_event_date && (
                  <p id="expected-event-date-error" role="alert" className="text-sm text-destructive">
                    {errors.expected_event_date.message}
                  </p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="expected_guest_count">
                  Expected Guest Count <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="expected_guest_count"
                  type="number"
                  min={1}
                  aria-invalid={errors.expected_guest_count ? true : undefined}
                  aria-describedby={errors.expected_guest_count ? "expected-guest-count-error" : undefined}
                  {...register("expected_guest_count")}
                />
                {errors.expected_guest_count && (
                  <p id="expected-guest-count-error" role="alert" className="text-sm text-destructive">
                    {errors.expected_guest_count.message}
                  </p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="assigned_to">Assigned To</Label>
                <Select
                  onValueChange={(v) =>
                    setValue("assigned_to", v ? Number(v) : null, { shouldValidate: true })
                  }
                >
                  <SelectTrigger id="assigned_to" className="cursor-pointer">
                    <SelectValue placeholder="Assign to..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="0">Unassigned</SelectItem>
                  </SelectContent>
                </Select>
                <p className="text-xs text-muted-foreground">Optional</p>
              </div>
            </div>

            <div className="flex gap-3 justify-end">
              <Button variant="outline" asChild className="cursor-pointer">
                <Link href="/leads">Cancel</Link>
              </Button>
              <Button type="submit" disabled={isSubmitting} className="cursor-pointer">
                {isSubmitting ? (
                  <span className="flex items-center gap-2">
                    <span className="h-4 w-4 animate-spin rounded-full border-2 border-background border-t-transparent" />
                    Saving...
                  </span>
                ) : (
                  <span className="flex items-center gap-2">
                    <Save aria-hidden="true" focusable="false" className="h-4 w-4" />
                    Save Lead
                  </span>
                )}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
