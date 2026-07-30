"use client"

import { useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { ArrowLeft, Edit, Trash2, Save, X, CheckSquare } from "lucide-react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { useTask, useUpdateTask, useDeleteTask } from "@/hooks/use-tasks"
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
import { formatDate } from "@/lib/utils"
import { TASK_PRIORITIES, TASK_STATUSES } from "@/lib/constants"
import type { Task } from "@/types/api"

const editSchema = z.object({
  title: z.string().min(1, "Title is required"),
  description: z.string().optional(),
  assigned_to: z.coerce.number().optional(),
  priority: z.string().min(1, "Priority is required"),
  status: z.string().min(1, "Status is required"),
  due_date: z.string().optional(),
})

type EditValues = z.infer<typeof editSchema>

export default function TaskDetailClient() {
  const params = useParams()
  const router = useRouter()
  const id = Number(params.id)
  const [editing, setEditing] = useState(false)
  const [showDeleteDialog, setShowDeleteDialog] = useState(false)

  const { data: response, isLoading, error, refetch } = useTask(id)
  const updateMutation = useUpdateTask(id)
  const deleteMutation = useDeleteTask()

  const task = response?.data as Task | undefined

  const form = useForm<EditValues>({
    resolver: zodResolver(editSchema),
    values: task ? {
      title: task.title,
      description: task.description || "",
      assigned_to: task.assigned_to ?? undefined,
      priority: task.priority,
      status: task.status,
      due_date: task.due_date || "",
    } : undefined,
  })

  const onSubmit = async (values: EditValues) => {
    try {
      await updateMutation.mutateAsync(values)
      toast({ title: "Task updated", variant: "success" })
      setEditing(false)
    } catch {
      toast({ title: "Failed to update task", variant: "destructive" })
    }
  }

  const handleDelete = async () => {
    try {
      await deleteMutation.mutateAsync(id)
      toast({ title: "Task deleted", variant: "success" })
      router.push("/tasks")
    } catch {
      toast({ title: "Failed to delete task", variant: "destructive" })
    }
  }

  if (isLoading) return <LoadingState type="page" />
  if (error) return <ErrorState message={(error as Error).message} onRetry={() => refetch()} />
  if (!task) return <ErrorState message="Task not found" />

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
        <button onClick={() => router.push("/tasks")} className="hover:text-foreground cursor-pointer">
          Tasks
        </button>
        <span>/</span>
        <span className="text-foreground font-medium">{task.title}</span>
      </div>

      <PageHeader title={editing ? "Edit Task" : task.title}>
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
                  <FormField control={form.control} name="title" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Title *</FormLabel>
                      <FormControl><Input {...field} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="assigned_to" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Assigned To (ID)</FormLabel>
                      <FormControl><Input type="number" {...field} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="priority" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Priority *</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value}>
                        <FormControl>
                          <SelectTrigger className="cursor-pointer"><SelectValue /></SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {TASK_PRIORITIES.map((p) => (
                            <SelectItem key={p} value={p} className="cursor-pointer">{p}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="status" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Status *</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value}>
                        <FormControl>
                          <SelectTrigger className="cursor-pointer"><SelectValue /></SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {TASK_STATUSES.map((s) => (
                            <SelectItem key={s} value={s} className="cursor-pointer">{s.replace(/_/g, " ")}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="due_date" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Due Date</FormLabel>
                      <FormControl><Input type="date" {...field} /></FormControl>
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
              <CheckSquare className="h-5 w-5 text-primary" />
              Task Details
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">Title</p>
                <p className="font-medium">{task.title}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Assigned To</p>
                <p className="font-medium">{task.assigned_to_name || "—"}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Priority</p>
                <StatusBadge status={task.priority} type="generic" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Status</p>
                <StatusBadge status={task.status} type="generic" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Due Date</p>
                <p className="font-medium">{task.due_date ? formatDate(task.due_date) : "—"}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Created At</p>
                <p className="font-medium">{formatDate(task.created_at)}</p>
              </div>
            </div>
            {task.description && (
              <>
                <Separator />
                <div>
                  <p className="text-sm text-muted-foreground">Description</p>
                  <p className="font-medium whitespace-pre-wrap">{task.description}</p>
                </div>
              </>
            )}
          </CardContent>
        </Card>
      )}

      <ConfirmDialog
        open={showDeleteDialog}
        onOpenChange={setShowDeleteDialog}
        title="Delete Task"
        description={`Are you sure you want to delete "${task.title}"? This action cannot be undone.`}
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteMutation.isPending}
      />
    </div>
  )
}
