"use client"

import { useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { ArrowLeft, Edit, Trash2, Save, X, Building2 } from "lucide-react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { useVendor, useUpdateVendor, useDeleteVendor } from "@/hooks/use-vendors"
import { PageHeader } from "@/components/common/PageHeader"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { toast } from "@/components/ui/toast"
import { VENDOR_SERVICE_TYPES } from "@/lib/constants"
import type { Vendor } from "@/types/api"

const editSchema = z.object({
  company_name: z.string().min(1, "Company name is required"),
  service_type: z.string().min(1, "Service type is required"),
  contact_person: z.string().min(1, "Contact person is required"),
  mobile: z.string().min(1, "Mobile is required"),
  email: z.string().email("Invalid email").optional().or(z.literal("")),
  status: z.string(),
})

type EditValues = z.infer<typeof editSchema>

export default function VendorDetailClient() {
  const params = useParams()
  const router = useRouter()
  const id = Number(params.id)
  const [editing, setEditing] = useState(false)
  const [showDeleteDialog, setShowDeleteDialog] = useState(false)

  const { data: response, isLoading, error, refetch } = useVendor(id)
  const updateMutation = useUpdateVendor(id)
  const deleteMutation = useDeleteVendor()

  const vendor = response?.data as Vendor | undefined

  const form = useForm<EditValues>({
    resolver: zodResolver(editSchema),
    values: vendor ? {
      company_name: vendor.company_name,
      service_type: vendor.service_type,
      contact_person: vendor.contact_person,
      mobile: vendor.mobile,
      email: vendor.email,
      status: vendor.status,
    } : undefined,
  })

  const onSubmit = async (values: EditValues) => {
    try {
      await updateMutation.mutateAsync(values)
      toast({ title: "Vendor updated", variant: "success" })
      setEditing(false)
    } catch {
      toast({ title: "Failed to update vendor", variant: "destructive" })
    }
  }

  const handleDelete = async () => {
    try {
      await deleteMutation.mutateAsync(id)
      toast({ title: "Vendor deleted", variant: "success" })
      router.push("/vendors")
    } catch {
      toast({ title: "Failed to delete vendor", variant: "destructive" })
    }
  }

  if (isLoading) return <LoadingState type="page" />
  if (error) return <ErrorState message={(error as Error).message} onRetry={() => refetch()} />
  if (!vendor) return <ErrorState message="Vendor not found" />

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
        <button onClick={() => router.push("/vendors")} className="hover:text-foreground cursor-pointer">
          Vendors
        </button>
        <span>/</span>
        <span className="text-foreground font-medium">{vendor.company_name}</span>
      </div>

      <PageHeader title={editing ? "Edit Vendor" : vendor.company_name}>
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
            <Button variant="destructive" className="cursor-pointer" onClick={() => setShowDeleteDialog(true)}>
              <Trash2 className="mr-2 h-4 w-4" />
              Delete
            </Button>
          </>
        ) : (
          <>
            <Button variant="outline" className="cursor-pointer" onClick={() => { setEditing(false); form.reset() }}>
              <X className="mr-2 h-4 w-4" />
              Cancel
            </Button>
            <Button className="cursor-pointer" onClick={form.handleSubmit(onSubmit)} disabled={updateMutation.isPending}>
              <Save className="mr-2 h-4 w-4" />
              {updateMutation.isPending ? "Saving..." : "Save"}
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
                  <FormField control={form.control} name="company_name" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Company Name *</FormLabel>
                      <FormControl><Input {...field} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="service_type" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Service Type *</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value}>
                        <FormControl>
                          <SelectTrigger className="cursor-pointer"><SelectValue /></SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {VENDOR_SERVICE_TYPES.map((t) => (
                            <SelectItem key={t} value={t} className="cursor-pointer">{t.replace(/_/g, " ")}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="contact_person" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Contact Person *</FormLabel>
                      <FormControl><Input {...field} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="mobile" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Mobile *</FormLabel>
                      <FormControl><Input {...field} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="email" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Email</FormLabel>
                      <FormControl><Input type="email" {...field} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="status" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Status</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value}>
                        <FormControl>
                          <SelectTrigger className="cursor-pointer"><SelectValue /></SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="ACTIVE" className="cursor-pointer">Active</SelectItem>
                          <SelectItem value="INACTIVE" className="cursor-pointer">Inactive</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )} />
                </div>
              </form>
            </Form>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Building2 className="h-5 w-5 text-primary" />
              Vendor Details
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">Company Name</p>
                <p className="font-medium">{vendor.company_name}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Service Type</p>
                <p className="font-medium">{vendor.service_type.replace(/_/g, " ")}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Contact Person</p>
                <p className="font-medium">{vendor.contact_person}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Mobile</p>
                <p className="font-medium">{vendor.mobile}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Email</p>
                <p className="font-medium">{vendor.email || "—"}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Status</p>
                <StatusBadge status={vendor.status} type="generic" />
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      <ConfirmDialog
        open={showDeleteDialog}
        onOpenChange={setShowDeleteDialog}
        title="Delete Vendor"
        description={`Are you sure you want to delete "${vendor.company_name}"? This action cannot be undone.`}
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteMutation.isPending}
      />
    </div>
  )
}
