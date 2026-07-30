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
  Mail,
  Phone,
  MapPin,
  FileText,
  Calendar,
  Clock,
  User,
} from "lucide-react"

import { useCustomer, useUpdateCustomer, useDeleteCustomer } from "@/hooks/use-customers"
import { formatDate, formatDateTime } from "@/lib/utils"
import { PageHeader } from "@/components/common/PageHeader"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { useToast } from "@/components/ui/toast"

const customerEditSchema = z.object({
  full_name: z.string().min(1, "Full name is required"),
  mobile: z
    .string()
    .min(1, "Mobile is required")
    .regex(/^[0-9+\-\s()]{7,15}$/, "Invalid mobile number"),
  email: z.string().email("Invalid email").optional().or(z.literal("")),
  address: z.string().optional(),
  remarks: z.string().optional(),
})

type CustomerEditForm = z.infer<typeof customerEditSchema>

export default function CustomerDetailClient() {
  const params = useParams()
  const router = useRouter()
  const { toast } = useToast()
  const id = Number(params.id)
  const [editing, setEditing] = useState(false)
  const [deleteOpen, setDeleteOpen] = useState(false)

  const { data, isLoading, error, refetch } = useCustomer(id)
  const updateMutation = useUpdateCustomer(id)
  const deleteMutation = useDeleteCustomer()

  const customer = data?.data as
    | (Record<string, string | number | undefined> & {
        id: number
        full_name: string
        mobile: string
        email?: string
        address?: string
        remarks?: string
        created_at?: string
        updated_at?: string
      })
    | undefined

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<CustomerEditForm>({
    resolver: zodResolver(customerEditSchema),
  })

  useEffect(() => {
    if (customer) {
      reset({
        full_name: customer.full_name || "",
        mobile: customer.mobile || "",
        email: customer.email || "",
        address: customer.address || "",
        remarks: customer.remarks || "",
      })
    }
  }, [customer, reset])

  const onSubmit = async (formData: CustomerEditForm) => {
    try {
      await updateMutation.mutateAsync({
        full_name: formData.full_name,
        mobile: formData.mobile,
        email: formData.email || undefined,
        address: formData.address || undefined,
        remarks: formData.remarks || undefined,
      })
      toast({ title: "Customer updated", variant: "success" })
      setEditing(false)
    } catch {
      toast({ title: "Failed to update customer", variant: "destructive" })
    }
  }

  const handleDelete = async () => {
    try {
      await deleteMutation.mutateAsync(id)
      toast({ title: "Customer deleted", variant: "success" })
      router.push("/customers")
    } catch {
      toast({ title: "Failed to delete customer", variant: "destructive" })
    }
  }

  if (isLoading) return <LoadingState type="page" />
  if (error) return <ErrorState message={(error as Error).message} onRetry={() => refetch()} />
  if (!customer) return <ErrorState message="Customer not found" />

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
        <Link href="/customers" className="hover:text-foreground">
          Customers
        </Link>
        <span>/</span>
        <span className="text-foreground font-medium truncate">{customer.full_name}</span>
      </div>

      <PageHeader title={customer.full_name}>
        <div className="flex gap-2">
          <Button variant="outline" asChild className="cursor-pointer">
            <Link href="/customers">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back
            </Link>
          </Button>
          {editing ? (
            <>
              <Button
                variant="outline"
                onClick={() => {
                  setEditing(false)
                  reset({
                    full_name: customer.full_name || "",
                    mobile: customer.mobile || "",
                    email: customer.email || "",
                    address: customer.address || "",
                    remarks: customer.remarks || "",
                  })
                }}
                className="cursor-pointer"
              >
                <X className="h-4 w-4 mr-2" />
                Cancel
              </Button>
              <Button
                onClick={handleSubmit(onSubmit)}
                disabled={isSubmitting}
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
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="full_name">Full Name</Label>
                  <Input id="full_name" {...register("full_name")} />
                  {errors.full_name && (
                    <p className="text-sm text-destructive">{errors.full_name.message}</p>
                  )}
                </div>
                <div className="space-y-2">
                  <Label htmlFor="mobile">Mobile</Label>
                  <Input id="mobile" {...register("mobile")} />
                  {errors.mobile && (
                    <p className="text-sm text-destructive">{errors.mobile.message}</p>
                  )}
                </div>
                <div className="space-y-2">
                  <Label htmlFor="email">Email</Label>
                  <Input id="email" type="email" {...register("email")} />
                  {errors.email && (
                    <p className="text-sm text-destructive">{errors.email.message}</p>
                  )}
                </div>
              </div>
              <div className="space-y-2">
                <Label htmlFor="address">Address</Label>
                <Textarea id="address" rows={3} {...register("address")} />
                {errors.address && (
                  <p className="text-sm text-destructive">{errors.address.message}</p>
                )}
              </div>
              <div className="space-y-2">
                <Label htmlFor="remarks">Remarks</Label>
                <Textarea id="remarks" rows={3} {...register("remarks")} />
                {errors.remarks && (
                  <p className="text-sm text-destructive">{errors.remarks.message}</p>
                )}
              </div>
            </form>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Contact Information</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-start gap-3">
                <User className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium">Full Name</p>
                  <p className="text-sm text-muted-foreground">{customer.full_name}</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <Phone className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium">Mobile</p>
                  <p className="text-sm text-muted-foreground">{customer.mobile}</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <Mail className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium">Email</p>
                  <p className="text-sm text-muted-foreground">{customer.email || "—"}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Additional Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-start gap-3">
                <MapPin className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium">Address</p>
                  <p className="text-sm text-muted-foreground whitespace-pre-wrap">
                    {customer.address || "—"}
                  </p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <FileText className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium">Remarks</p>
                  <p className="text-sm text-muted-foreground whitespace-pre-wrap">
                    {customer.remarks || "—"}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Timeline</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-start gap-3">
                <Calendar className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium">Created</p>
                  <p className="text-sm text-muted-foreground">
                    {customer.created_at ? formatDateTime(customer.created_at) : "—"}
                  </p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <Clock className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium">Last Updated</p>
                  <p className="text-sm text-muted-foreground">
                    {customer.updated_at ? formatDateTime(customer.updated_at) : "—"}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      <ConfirmDialog
        open={deleteOpen}
        onOpenChange={setDeleteOpen}
        title="Delete Customer"
        description="Are you sure you want to delete this customer? This action cannot be undone."
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteMutation.isPending}
      />
    </div>
  )
}
