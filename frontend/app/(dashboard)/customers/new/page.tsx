"use client"

import { useRouter } from "next/navigation"
import Link from "next/link"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { ArrowLeft, Save } from "lucide-react"

import { useCreateCustomer } from "@/hooks/use-customers"
import { PageHeader } from "@/components/common/PageHeader"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import { Card, CardContent } from "@/components/ui/card"
import { useToast } from "@/components/ui/toast"

const customerSchema = z.object({
  full_name: z.string().min(1, "Full name is required").max(255, "Name is too long"),
  mobile: z
    .string()
    .min(1, "Mobile number is required")
    .regex(/^[0-9+\-\s()]{7,15}$/, "Please enter a valid mobile number"),
  email: z.string().email("Invalid email address").optional().or(z.literal("")),
  address: z.string().optional(),
  remarks: z.string().optional(),
})

type CustomerForm = z.infer<typeof customerSchema>

export default function NewCustomerPage() {
  const router = useRouter()
  const { toast } = useToast()
  const createCustomer = useCreateCustomer()

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CustomerForm>({
    resolver: zodResolver(customerSchema),
  })

  const onSubmit = async (data: CustomerForm) => {
    try {
      await createCustomer.mutateAsync({
        full_name: data.full_name,
        mobile: data.mobile,
        email: data.email || undefined,
        address: data.address || undefined,
        remarks: data.remarks || undefined,
      })
      toast({ title: "Customer created", description: "Customer has been added successfully.", variant: "success" })
      router.push("/customers")
    } catch (err: unknown) {
      const message =
        err && typeof err === "object" && "response" in err
          ? (err as { response: { data: { message: string } } }).response?.data?.message
          : "Failed to create customer"
      toast({ title: "Error", description: message, variant: "destructive" })
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Add Customer">
        <Button variant="outline" asChild className="cursor-pointer">
          <Link href="/customers">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Link>
        </Button>
      </PageHeader>

      <Card>
        <CardContent className="pt-6">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="full_name">
                  Full Name <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="full_name"
                  placeholder="John Doe"
                  {...register("full_name")}
                />
                {errors.full_name && (
                  <p className="text-sm text-destructive">{errors.full_name.message}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="mobile">
                  Mobile <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="mobile"
                  placeholder="+91 98765 43210"
                  {...register("mobile")}
                />
                {errors.mobile && (
                  <p className="text-sm text-destructive">{errors.mobile.message}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="john@example.com"
                  {...register("email")}
                />
                {errors.email && (
                  <p className="text-sm text-destructive">{errors.email.message}</p>
                )}
                <p className="text-xs text-muted-foreground">Optional</p>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="address">Address</Label>
              <Textarea
                id="address"
                placeholder="Enter full address"
                rows={3}
                {...register("address")}
              />
              {errors.address && (
                <p className="text-sm text-destructive">{errors.address.message}</p>
              )}
              <p className="text-xs text-muted-foreground">Optional</p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="remarks">Remarks</Label>
              <Textarea
                id="remarks"
                placeholder="Any additional notes..."
                rows={3}
                {...register("remarks")}
              />
              {errors.remarks && (
                <p className="text-sm text-destructive">{errors.remarks.message}</p>
              )}
              <p className="text-xs text-muted-foreground">Optional</p>
            </div>

            <div className="flex gap-3 justify-end">
              <Button variant="outline" asChild className="cursor-pointer">
                <Link href="/customers">Cancel</Link>
              </Button>
              <Button type="submit" disabled={isSubmitting} className="cursor-pointer">
                {isSubmitting ? (
                  <span className="flex items-center gap-2">
                    <span className="h-4 w-4 animate-spin rounded-full border-2 border-background border-t-transparent" />
                    Saving...
                  </span>
                ) : (
                  <span className="flex items-center gap-2">
                    <Save className="h-4 w-4" />
                    Save Customer
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
