"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Plus, Search, CheckSquare, Eye, Edit, Trash2 } from "lucide-react"
import { useTasks, useDeleteTask } from "@/hooks/use-tasks"
import { PageHeader } from "@/components/common/PageHeader"
import { DataTable } from "@/components/common/DataTable"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { toast } from "@/components/ui/toast"
import { cn, formatDate } from "@/lib/utils"
import { TASK_PRIORITIES } from "@/lib/constants"
import type { Task } from "@/types/api"

const statusFilters = ["All", "TODO", "IN_PROGRESS", "DONE", "CANCELLED"] as const

export default function TasksPage() {
  const router = useRouter()
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState("All")
  const [priorityFilter, setPriorityFilter] = useState("All")
  const [page, setPage] = useState(1)
  const [deleteId, setDeleteId] = useState<number | null>(null)

  const status = statusFilter === "All" ? undefined : statusFilter
  const priority = priorityFilter === "All" ? undefined : priorityFilter

  const { data, isLoading, error, refetch } = useTasks({
    page,
    page_size: 10,
    search: search || undefined,
    status,
    priority,
  })

  const deleteTask = useDeleteTask()

  const tasks = data?.data ?? []
  const pagination = data?.pagination

  const handleDelete = async () => {
    if (!deleteId) return
    try {
      await deleteTask.mutateAsync(deleteId)
      toast({ title: "Task deleted", variant: "success" })
      setDeleteId(null)
    } catch {
      toast({ title: "Failed to delete task", variant: "destructive" })
    }
  }

  const columns: import("@/components/common/DataTable").Column<Record<string, unknown>>[] = [
    {
      key: "title",
      header: "Title",
      cell: (item) => {
        const task = item as unknown as Task
        return (
          <div className="flex items-center gap-2">
            <CheckSquare className="h-4 w-4 text-slate-700 shrink-0" />
            <span className="font-medium">{task.title}</span>
          </div>
        )
      },
    },
    {
      key: "assigned_to_name",
      header: "Assigned To",
      cell: (item) => {
        const task = item as unknown as Task
        return <span className="text-sm text-slate-700">{task.assigned_to_name || "—"}</span>
      },
    },
    {
      key: "priority",
      header: "Priority",
      cell: (item) => {
        const task = item as unknown as Task
        return <StatusBadge status={task.priority} type="generic" />
      },
    },
    {
      key: "status",
      header: "Status",
      cell: (item) => {
        const task = item as unknown as Task
        return <StatusBadge status={task.status} type="generic" />
      },
    },
    {
      key: "due_date",
      header: "Due Date",
      sortable: true,
      cell: (item) => {
        const task = item as unknown as Task
        return <span className="font-mono text-sm">{task.due_date ? formatDate(task.due_date) : "—"}</span>
      },
    },
    {
      key: "actions",
      header: "Actions",
      cell: (item) => {
        const task = item as unknown as Task
        return (
          <div className="flex items-center gap-1">
            <Button variant="ghost" size="icon" className="cursor-pointer" onClick={(e) => { e.stopPropagation(); router.push(`/tasks/${task.id}`) }}>
              <Eye className="h-4 w-4" />
            </Button>
            <Button variant="ghost" size="icon" className="cursor-pointer" onClick={(e) => { e.stopPropagation(); router.push(`/tasks/${task.id}`) }}>
              <Edit className="h-4 w-4" />
            </Button>
            <Button variant="ghost" size="icon" className="cursor-pointer text-destructive hover:text-destructive" onClick={(e) => { e.stopPropagation(); setDeleteId(task.id) }}>
              <Trash2 className="h-4 w-4" />
            </Button>
          </div>
        )
      },
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Tasks" description="Manage your event tasks">
        <Button className="cursor-pointer" onClick={() => router.push("/tasks/new")}>
          <Plus className="mr-2 h-4 w-4" />
          Add Task
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-700" />
          <Input
            placeholder="Search tasks..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            className="pl-9"
          />
        </div>
        <Select value={priorityFilter} onValueChange={(v) => { setPriorityFilter(v); setPage(1) }}>
          <SelectTrigger className="w-full sm:w-[180px] cursor-pointer">
            <SelectValue placeholder="All Priorities" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="All">All Priorities</SelectItem>
            {TASK_PRIORITIES.map((p) => (
              <SelectItem key={p} value={p}>{p.replace(/_/g, " ")}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="flex gap-2 flex-wrap">
        {statusFilters.map((s) => (
          <button
            key={s}
            onClick={() => { setStatusFilter(s); setPage(1) }}
            className={cn(
              "px-3 py-1.5 text-sm rounded-full border transition-colors cursor-pointer",
              statusFilter === s
                ? "bg-amber-600 text-white border-amber-600"
                : "bg-white text-slate-700 border-input hover:bg-slate-100"
            )}
          >
            {s === "All" ? "All" : s.replace(/_/g, " ")}
          </button>
        ))}
      </div>

      <DataTable
        columns={columns}
        data={tasks as unknown as Record<string, unknown>[]}
        loading={isLoading}
        error={error ? (error as Error).message : null}
        onRetry={() => refetch()}
        emptyMessage="No tasks found. Create your first task to get started."
        emptyAction={{ label: "Add Task", onClick: () => router.push("/tasks/new") }}
        onRowClick={(item) => router.push(`/tasks/${(item as unknown as Task).id}`)}
      />

      {pagination && pagination.total_pages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-slate-700">
            Page {pagination.page} of {pagination.total_pages} ({pagination.total_records} total)
          </p>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => setPage((p) => Math.max(1, p - 1))} className="cursor-pointer">Previous</Button>
            <Button variant="outline" size="sm" disabled={page >= pagination.total_pages} onClick={() => setPage((p) => p + 1)} className="cursor-pointer">Next</Button>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={!!deleteId}
        onOpenChange={(open) => !open && setDeleteId(null)}
        title="Delete Task"
        description="Are you sure you want to delete this task? This action cannot be undone."
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteTask.isPending}
      />
    </div>
  )
}
