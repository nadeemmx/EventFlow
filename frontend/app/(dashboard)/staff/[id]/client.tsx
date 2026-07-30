"use client"

import { useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { ArrowLeft, Edit, Trash2, Save, X, Users } from "lucide-react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { useStaffMember, useUpdateStaffMember, useDeleteStaffMember } from "@/hooks/use-staff"
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
import { formatDate } from "@/lib/utils"
import { STAFF_ROLES } from "@/lib/constants"
import type { StaffMember } from "@/types/api"

const editSchema = z.object({
  full_name: z.string().min(1, "Name is required"),
  email: z.string().email("Invalid email").optional().or(z.literal("")),
  mobile: z.string().min(1, "Mobile is required"),
  role: z.string().min(1, "Role is required"),
  status: z.string(),
})

type EditValues = z.infer<typeof editSchema>

export default function StaffDetailClient() {
  const params = useParams()
  const router = useRouter()
  const id = Number(params.id)
  const [editing, setEditing] = useState(false)
  const [showDeleteDialog, setShowDeleteDialog] = useState(false)

  const { data: response, isLoading, error, refetch } = useStaffMember(id)
  const updateMutation = useUpdateStaffMember(id)
  const deleteMutation = useDeleteStaffMember()

  const member = response?.data as StaffMember | undefined

  const form = useForm<EditValues>({
    resolver: zodResolver(editSchema),
    values: member ? {
      full_name: member.full_name,
      email: member.email,
      mobile: member.mobile,
      role: member.role,
      status: member.status,
    } : undefined,
  })

  const onSubmit = async (values: EditValues) => {
    try {
      await updateMutation.mutateAsync(values)
      toast({ title: "Staff member updated", variant: "success" })
      setEditing(false)
    } catch {
      toast({ title: "Failed to update staff member", variant: "destructive" })
    }
  }

  const handleDelete = async () => {
    try {
      await deleteMutation.mutateAsync(id)
      toast({ title: "Staff member deleted", variant: "success" })
      router.push("/staff")
    } catch {
      toast({ title: "Failed to delete staff member", variant: "destructive" })
    }
  }

  if (isLoading) return <LoadingState type="page" />
  if (error) return <ErrorState message={(error as Error).message} onRetry={() => refetch()} />
  if (!member) return <ErrorState message="Staff member not found" />

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
        <button onClick={() => router.push("/staff")} className="hover:text-foreground cursor-pointer">
          Staff
        </button>
        <span>/</span>
        <span className="text-foreground font-medium">{member.full_name}</span>
      </div>

      <PageHeader title={editing ? "Edit Staff Member" : member.full_name}>
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
                  <FormField control={form.control} name="full_name" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Full Name *</FormLabel>
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
                  <FormField control={form.control} name="mobile" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Mobile *</FormLabel>
                      <FormControl><Input {...field} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="role" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Role *</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value}>
                        <FormControl>
                          <SelectTrigger className="cursor-pointer"><SelectValue /></SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {STAFF_ROLES.map((r) => (
                            <SelectItem key={r} value={r} className="cursor-pointer">{r.replace(/_/g, " ")}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
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
              <Users className="h-5 w-5 text-primary" />
              Staff Details
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">Full Name</p>
                <p className="font-medium">{member.full_name}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Role</p>
                <p className="font-medium">{member.role.replace(/_/g, " ")}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Email</p>
                <p className="font-medium">{member.email || "—"}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Mobile</p>
                <p className="font-medium">{member.mobile}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Status</p>
                <StatusBadge status={member.status} type="generic" />
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      <ConfirmDialog
        open={showDeleteDialog}
        onOpenChange={setShowDeleteDialog}
        title="Delete Staff Member"
        description={`Are you sure you want to delete "${member.full_name}"? This action cannot be undone.`}
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteMutation.isPending}
      />
    </div>
  )
}
