"use client"

import { useState, useMemo } from "react"
import { useRouter } from "next/navigation"
import { ArrowLeft, Plus, Trash2, UserPlus } from "lucide-react"
import { useForm, useFieldArray } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"

import { useCreateQuotation } from "@/hooks/use-quotations"
import { useCustomers, useCreateCustomer } from "@/hooks/use-customers"
import { useVenues } from "@/hooks/use-venues"
import { PageHeader } from "@/components/common/PageHeader"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog"
import { Label } from "@/components/ui/label"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { useToast } from "@/components/ui/toast"
import { formatINR } from "@/lib/utils"

const itemSchema = z.object({
  item_name: z.string().min(1, "Item name is required"),
  quantity: z.coerce.number().min(1, "Min 1"),
  unit_price: z.coerce.number().min(0, "Min 0"),
})

const quotationSchema = z.object({
  customer_id: z.coerce.number().min(1, "Customer is required"),
  venue_id: z.coerce.number().optional().or(z.literal(0)),
  package_id: z.coerce.number().optional().or(z.literal(0)),
  valid_until: z.string().min(1, "Valid until date is required"),
  items: z.array(itemSchema).min(1, "At least one item is required"),
})

type QuotationFormValues = z.infer<typeof quotationSchema>

const customerSchema = z.object({
  full_name: z.string().min(1, "Name is required"),
  mobile: z.string().min(10, "Valid mobile number is required"),
  email: z.string().email("Invalid email").optional().or(z.literal("")),
  address: z.string().optional(),
})

type CustomerFormValues = z.infer<typeof customerSchema>

export default function NewQuotationPage() {
  const router = useRouter()
  const { toast } = useToast()
  const [showCustomerDialog, setShowCustomerDialog] = useState(false)

  const createQuotation = useCreateQuotation()
  const createCustomer = useCreateCustomer()
  const { data: customersData } = useCustomers({ page_size: 100 })
  const { data: venuesData } = useVenues({ page_size: 100 })

  const customers = customersData?.data ?? []
  const venues = venuesData?.data ?? []

  const form = useForm<QuotationFormValues>({
    resolver: zodResolver(quotationSchema),
    defaultValues: {
      customer_id: undefined as unknown as number,
      venue_id: 0,
      package_id: 0,
      valid_until: "",
      items: [{ item_name: "", quantity: 1, unit_price: 0 }],
    },
  })

  const { fields, append, remove } = useFieldArray({
    control: form.control,
    name: "items",
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

  const watchedItems = form.watch("items")

  const totals = useMemo(() => {
    const subtotal = (watchedItems || []).reduce(
      (sum, item) => sum + (Number(item.quantity) || 0) * (Number(item.unit_price) || 0),
      0,
    )
    const tax = Math.round(subtotal * 0.18 * 100) / 100
    const total = subtotal + tax
    return { subtotal, tax, total }
  }, [watchedItems])

  const onSubmit = async (values: QuotationFormValues) => {
    try {
      const res = await createQuotation.mutateAsync({
        customer: values.customer_id,
        venue: values.venue_id && values.venue_id !== 0 ? values.venue_id : undefined,
        package: values.package_id && values.package_id !== 0 ? values.package_id : undefined,
        valid_until: values.valid_until,
        items: values.items.map((item) => ({
          item_name: item.item_name,
          quantity: item.quantity,
          unit_price: item.unit_price,
        })),
      })
      toast({ title: "Quotation created", variant: "success" })
      const quotationId = res?.data?.id
      if (quotationId) {
        router.push(`/quotations/${quotationId}`)
      } else {
        router.push("/quotations")
      }
    } catch {
      toast({ title: "Failed to create quotation", variant: "destructive" })
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

  return (
    <div className="space-y-6">
      <PageHeader title="New Quotation">
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
                        <Select
                          onValueChange={field.onChange}
                          value={field.value ? String(field.value) : ""}
                        >
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
                      <FormLabel>Venue</FormLabel>
                      <Select
                        onValueChange={(v) => field.onChange(v ? Number(v) : 0)}
                        value={field.value ? String(field.value) : "0"}
                      >
                        <FormControl>
                          <SelectTrigger className="cursor-pointer">
                            <SelectValue placeholder="Select venue (optional)" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="0" className="cursor-pointer">
                            No venue
                          </SelectItem>
                          {venues.map((v) => (
                            <SelectItem key={v.id} value={String(v.id)} className="cursor-pointer">
                              {v.name} — Cap: {v.capacity}
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
                  name="package_id"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Package ID</FormLabel>
                      <FormControl>
                        <Input
                          type="number"
                          min={0}
                          placeholder="Package ID (optional)"
                          {...field}
                          onChange={(e) => field.onChange(e.target.value ? Number(e.target.value) : 0)}
                        />
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
                        <Input type="date" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between">
                  <CardTitle className="text-lg">Items</CardTitle>
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    className="cursor-pointer"
                    onClick={() => append({ item_name: "", quantity: 1, unit_price: 0 })}
                  >
                    <Plus className="h-4 w-4 mr-2" />
                    Add Item
                  </Button>
                </CardHeader>
                <CardContent>
                  {fields.length === 0 ? (
                    <p className="text-sm text-muted-foreground text-center py-4">
                      No items added. Click &quot;Add Item&quot; to add line items.
                    </p>
                  ) : (
                    <div className="overflow-x-auto">
                      <Table>
                        <TableHeader>
                          <TableRow>
                            <TableHead className="min-w-[200px]">Item Name</TableHead>
                            <TableHead className="text-right w-24">Quantity</TableHead>
                            <TableHead className="text-right w-32">Unit Price</TableHead>
                            <TableHead className="text-right w-32">Total</TableHead>
                            <TableHead className="w-16"></TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {fields.map((field, index) => {
                            const qty = form.watch(`items.${index}.quantity`) || 0
                            const price = form.watch(`items.${index}.unit_price`) || 0
                            const lineTotal = Number(qty) * Number(price)
                            return (
                              <TableRow key={field.id}>
                                <TableCell>
                                  <FormField
                                    control={form.control}
                                    name={`items.${index}.item_name`}
                                    render={({ field }) => (
                                      <FormItem>
                                        <FormControl>
                                          <Input
                                            placeholder="Item name"
                                            {...field}
                                          />
                                        </FormControl>
                                        <FormMessage />
                                      </FormItem>
                                    )}
                                  />
                                </TableCell>
                                <TableCell>
                                  <FormField
                                    control={form.control}
                                    name={`items.${index}.quantity`}
                                    render={({ field }) => (
                                      <FormItem>
                                        <FormControl>
                                          <Input
                                            type="number"
                                            min={1}
                                            {...field}
                                            onChange={(e) => field.onChange(Number(e.target.value))}
                                          />
                                        </FormControl>
                                        <FormMessage />
                                      </FormItem>
                                    )}
                                  />
                                </TableCell>
                                <TableCell>
                                  <FormField
                                    control={form.control}
                                    name={`items.${index}.unit_price`}
                                    render={({ field }) => (
                                      <FormItem>
                                        <FormControl>
                                          <Input
                                            type="number"
                                            min={0}
                                            step="0.01"
                                            placeholder="0.00"
                                            {...field}
                                            onChange={(e) => field.onChange(Number(e.target.value))}
                                          />
                                        </FormControl>
                                        <FormMessage />
                                      </FormItem>
                                    )}
                                  />
                                </TableCell>
                                <TableCell className="text-right font-medium">
                                  {formatINR(lineTotal)}
                                </TableCell>
                                <TableCell>
                                  <Button
                                    type="button"
                                    variant="ghost"
                                    size="icon"
                                    aria-label="Remove item"
                                    className="h-8 w-8 text-destructive hover:text-destructive cursor-pointer"
                                    onClick={() => remove(index)}
                                    disabled={fields.length <= 1}
                                  >
                                    <Trash2 aria-hidden="true" focusable="false" className="h-4 w-4" />
                                  </Button>
                                </TableCell>
                              </TableRow>
                            )
                          })}
                        </TableBody>
                      </Table>
                    </div>
                  )}

                  <div className="border-t pt-4 mt-4">
                    <div className="space-y-1 max-w-xs ml-auto">
                      <div className="flex justify-between text-sm">
                        <span className="text-muted-foreground">Subtotal</span>
                        <span>{formatINR(totals.subtotal)}</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-muted-foreground">Tax (18%)</span>
                        <span>{formatINR(totals.tax)}</span>
                      </div>
                      <div className="flex justify-between font-semibold text-base border-t pt-1">
                        <span>Total</span>
                        <span>{formatINR(totals.total)}</span>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <div className="flex gap-3 justify-end">
                <Button
                  type="button"
                  variant="outline"
                  className="cursor-pointer"
                  onClick={() => router.back()}
                >
                  Cancel
                </Button>
                <Button type="submit" className="cursor-pointer" disabled={createQuotation.isPending}>
                  {createQuotation.isPending ? "Creating..." : "Create Quotation"}
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
              Add a new customer. They will be available in the customer dropdown.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={customerForm.handleSubmit(handleCreateCustomer)} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="full_name">Full Name *</Label>
              <Input
                id="full_name"
                placeholder="John Doe"
                aria-invalid={customerForm.formState.errors.full_name ? true : undefined}
                aria-describedby={customerForm.formState.errors.full_name ? "customer-full_name-error" : undefined}
                {...customerForm.register("full_name")}
              />
              {customerForm.formState.errors.full_name && (
                <p id="customer-full_name-error" role="alert" className="text-sm text-destructive">
                  {customerForm.formState.errors.full_name.message}
                </p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="mobile">Mobile *</Label>
              <Input
                id="mobile"
                placeholder="9876543210"
                aria-invalid={customerForm.formState.errors.mobile ? true : undefined}
                aria-describedby={customerForm.formState.errors.mobile ? "customer-mobile-error" : undefined}
                {...customerForm.register("mobile")}
              />
              {customerForm.formState.errors.mobile && (
                <p id="customer-mobile-error" role="alert" className="text-sm text-destructive">
                  {customerForm.formState.errors.mobile.message}
                </p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="john@example.com"
                aria-invalid={customerForm.formState.errors.email ? true : undefined}
                aria-describedby={customerForm.formState.errors.email ? "customer-email-error" : undefined}
                {...customerForm.register("email")}
              />
              {customerForm.formState.errors.email && (
                <p id="customer-email-error" role="alert" className="text-sm text-destructive">
                  {customerForm.formState.errors.email.message}
                </p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="address">Address</Label>
              <Input
                id="address"
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
