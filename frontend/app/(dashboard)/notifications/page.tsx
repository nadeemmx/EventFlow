"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Search, Bell, Eye, Trash2, CheckCheck } from "lucide-react"
import { useNotifications, useMarkNotificationAsRead, useDeleteNotification } from "@/hooks/use-notifications"
import { PageHeader } from "@/components/common/PageHeader"
import { DataTable } from "@/components/common/DataTable"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { toast } from "@/components/ui/toast"
import { cn, formatDateTime } from "@/lib/utils"
import { NOTIFICATION_TYPES } from "@/lib/constants"
import type { Notification } from "@/types/api"

const readFilters = ["All", "Read", "Unread"] as const

export default function NotificationsPage() {
  const router = useRouter()
  const [search, setSearch] = useState("")
  const [typeFilter, setTypeFilter] = useState("All")
  const [readFilter, setReadFilter] = useState("All")
  const [page, setPage] = useState(1)
  const [deleteId, setDeleteId] = useState<number | null>(null)

  const type = typeFilter === "All" ? undefined : typeFilter
  const is_read = readFilter === "All" ? undefined : readFilter === "Read"

  const { data, isLoading, error, refetch } = useNotifications({
    page,
    page_size: 10,
    search: search || undefined,
    type,
    is_read,
  })

  const markAsRead = useMarkNotificationAsRead()
  const deleteNotification = useDeleteNotification()

  const notifications = data?.data ?? []
  const pagination = data?.pagination

  const handleMarkAsRead = async (id: number) => {
    try {
      await markAsRead.mutateAsync(id)
      toast({ title: "Notification marked as read", variant: "success" })
    } catch {
      toast({ title: "Failed to mark notification as read", variant: "destructive" })
    }
  }

  const handleDelete = async () => {
    if (!deleteId) return
    try {
      await deleteNotification.mutateAsync(deleteId)
      toast({ title: "Notification deleted", variant: "success" })
      setDeleteId(null)
    } catch {
      toast({ title: "Failed to delete notification", variant: "destructive" })
    }
  }

  const columns: import("@/components/common/DataTable").Column<Record<string, unknown>>[] = [
    {
      key: "title",
      header: "Title",
      cell: (item) => {
        const notif = item as unknown as Notification
        return (
          <div className="flex items-center gap-2">
            <Bell className={cn("h-4 w-4 shrink-0", notif.is_read ? "text-slate-400" : "text-amber-600")} />
            <span className={cn("font-medium", !notif.is_read && "text-amber-600")}>{notif.title}</span>
          </div>
        )
      },
    },
    {
      key: "type",
      header: "Type",
      cell: (item) => {
        const notif = item as unknown as Notification
        return (
          <span className={cn(
            "text-sm font-medium",
            notif.type === "ERROR" && "text-destructive",
            notif.type === "WARNING" && "text-amber-600",
            notif.type === "SUCCESS" && "text-green-600",
            notif.type === "INFO" && "text-blue-600",
          )}>
            {notif.type}
          </span>
        )
      },
    },
    {
      key: "is_read",
      header: "Status",
      cell: (item) => {
        const notif = item as unknown as Notification
        return (
          <span className={cn("text-sm", notif.is_read ? "text-slate-500" : "text-amber-600 font-medium")}>
            {notif.is_read ? "Read" : "Unread"}
          </span>
        )
      },
    },
    {
      key: "created_at",
      header: "Received",
      sortable: true,
      cell: (item) => {
        const notif = item as unknown as Notification
        return <span className="font-mono text-sm">{formatDateTime(notif.created_at)}</span>
      },
    },
    {
      key: "actions",
      header: "Actions",
      cell: (item) => {
        const notif = item as unknown as Notification
        return (
          <div className="flex items-center gap-1">
            {!notif.is_read && (
              <Button
                variant="ghost"
                size="icon"
                aria-label="Mark notification as read"
                className="cursor-pointer"
                onClick={(e) => { e.stopPropagation(); handleMarkAsRead(notif.id) }}
                title="Mark as read"
              >
                <CheckCheck aria-hidden="true" focusable="false" className="h-4 w-4" />
              </Button>
            )}
            <Button
              variant="ghost"
              size="icon"
              aria-label="View notification"
              className="cursor-pointer"
              onClick={(e) => { e.stopPropagation(); router.push(`/notifications/${notif.id}`) }}
            >
              <Eye aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              aria-label="Delete notification"
              className="cursor-pointer text-destructive hover:text-destructive"
              onClick={(e) => { e.stopPropagation(); setDeleteId(notif.id) }}
            >
              <Trash2 aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
          </div>
        )
      },
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Notifications" description="View and manage notifications" />

      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-700" />
          <Input
            placeholder="Search notifications..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            className="pl-9"
          />
        </div>
        <Select value={typeFilter} onValueChange={(v) => { setTypeFilter(v); setPage(1) }}>
          <SelectTrigger className="w-full sm:w-[180px] cursor-pointer">
            <SelectValue placeholder="All Types" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="All">All Types</SelectItem>
            {NOTIFICATION_TYPES.map((t) => (
              <SelectItem key={t} value={t}>{t}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="flex gap-2 flex-wrap">
        {readFilters.map((f) => (
          <button
            key={f}
            onClick={() => { setReadFilter(f); setPage(1) }}
            className={cn(
              "px-3 py-1.5 text-sm rounded-full border transition-colors cursor-pointer",
              readFilter === f
                ? "bg-amber-600 text-white border-amber-600"
                : "bg-white text-slate-700 border-input hover:bg-slate-100"
            )}
          >
            {f}
          </button>
        ))}
      </div>

      <DataTable
        columns={columns}
        data={notifications as unknown as Record<string, unknown>[]}
        loading={isLoading}
        error={error ? (error as Error).message : null}
        onRetry={() => refetch()}
        emptyMessage="No notifications yet."
        onRowClick={(item) => router.push(`/notifications/${(item as unknown as Notification).id}`)}
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
        title="Delete Notification"
        description="Are you sure you want to delete this notification? This action cannot be undone."
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteNotification.isPending}
      />
    </div>
  )
}
