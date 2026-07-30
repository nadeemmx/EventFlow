"use client"

import { useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { ArrowLeft, Edit, Trash2, Save, X, Gift } from "lucide-react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { usePackage, useUpdatePackage, useDeletePackage } from "@/hooks/use-packages"
import { PageHeader } from "@/components/common/PageHeader"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { toast } from "@/components/ui/toast"
import { formatINR } from "@/lib/utils"
import type { Package } from "@/types/api"

const editSchema = z.object({
  name: z.string().min(1, "Name is required"),
  description: z.string().optional(),
  price: z.coerce.number().min(0, "Price must be at least 0"),
  items_count: z.coerce.number().min(0).optional(),
  status: z.string(),
})

type EditValues = z.infer<typeof editSchema>

export default function PackageDetailClient() {
  const params = useParams()
  const router = useRouter()
  const id = Number(params.id)
  const [editing, setEditing] = useState(false)
  const [showDeleteDialog, setShowDeleteDialog] = useState(false)

  const { data: response, isLoading, error, refetch } = usePackage(id)
  const updateMutation = useUpdatePackage(id)
  const deleteMutation = useDeletePackage()

  const pkg = response?.data as Package | undefined

  const form = useForm<EditValues>({
    resolver: zodResolver(editSchema),
    values: pkg ? {
      name: pkg.name,
      description: pkg.description || "",
      price: Number(pkg.price) || 0,
      items_count: pkg.items_count || 0,
      status: pkg.status,
    } : undefined,
  })

  const onSubmit = async (values: EditValues) => {
    try {
      await updateMutation.mutateAsync(values)
      toast({ title: "Package updated", variant: "success" })
      setEditing(false)
    } catch {
      toast({ title: "Failed to update package", variant: "destructive" })
    }
  }

  const handleDelete = async () => {
    try {
      await deleteMutation.mutateAsync(id)
      toast({ title: "Package deleted", variant: "success" })
      router.push("/packages")
    } catch {
      toast({ title: "Failed to delete package", variant: "destructive" })
    }
  }

  if (isLoading) return <LoadingState type="page" />
  if (error) return <ErrorState message={(error as Error).message} onRetry={() => refetch()} />
  if (!pkg) return <ErrorState message="Package not found" />

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
        <button onClick={() => router.push("/packages")} className="hover:text-foreground cursor-pointer">
          Packages
        </button>
        <span>/</span>
        <span className="text-foreground font-medium">{pkg.name}</span>
      </div>

      <PageHeader title={editing ? "Edit Package" : pkg.name}>
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
                  <FormField control={form.control} name="name" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Name *</FormLabel>
                      <FormControl><Input {...field} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="price" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Price (₹) *</FormLabel>
                      <FormControl><Input type="number" min={0} {...field} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="items_count" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Items Count</FormLabel>
                      <FormControl><Input type="number" min={0} {...field} /></FormControl>
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
                <FormField control={form.control} name="description" render={({ field }) => (
                  <FormItem>
                    <FormLabel>Description</FormLabel>
                    <FormControl><Textarea rows={3} {...field} /></FormControl>
                    <FormMessage />
                  </FormItem>
                )} />
              </form>
            </Form>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Gift className="h-5 w-5 text-primary" />
              Package Details
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">Name</p>
                <p className="font-medium">{pkg.name}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Price</p>
                <p className="font-medium">{formatINR(Number(pkg.price))}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Items</p>
                <p className="font-medium">{pkg.items_count}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Status</p>
                <StatusBadge status={pkg.status} type="generic" />
              </div>
            </div>
            {pkg.description && (
              <>
                <Separator />
                <div>
                  <p className="text-sm text-muted-foreground">Description</p>
                  <p className="font-medium whitespace-pre-wrap">{pkg.description}</p>
                </div>
              </>
            )}
          </CardContent>
        </Card>
      )}

      <ConfirmDialog
        open={showDeleteDialog}
        onOpenChange={setShowDeleteDialog}
        title="Delete Package"
        description={`Are you sure you want to delete "${pkg.name}"? This action cannot be undone.`}
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteMutation.isPending}
      />
    </div>
  )
}
