"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Plus, Search, CreditCard, Eye, Edit, Trash2 } from "lucide-react"
import { useSubscriptions, useDeleteSubscription } from "@/hooks/use-subscriptions"
import { PageHeader } from "@/components/common/PageHeader"
import { DataTable } from "@/components/common/DataTable"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { toast } from "@/components/ui/toast"
import { cn, formatINR, formatDate } from "@/lib/utils"
import type { Subscription } from "@/types/api"

const statusFilters = ["All", "ACTIVE", "EXPIRED", "CANCELLED"] as const

export default function SubscriptionsPage() {
  const router = useRouter()
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState("All")
  const [page, setPage] = useState(1)
  const [deleteId, setDeleteId] = useState<number | null>(null)

  const status = statusFilter === "All" ? undefined : statusFilter

  const { data, isLoading, error, refetch } = useSubscriptions({
    page,
    page_size: 10,
    search: search || undefined,
    status,
  })

  const deleteSub = useDeleteSubscription()

  const subscriptions = data?.data ?? []
  const pagination = data?.pagination

  const handleDelete = async () => {
    if (!deleteId) return
    try {
      await deleteSub.mutateAsync(deleteId)
      toast({ title: "Subscription deleted", variant: "success" })
      setDeleteId(null)
    } catch {
      toast({ title: "Failed to delete subscription", variant: "destructive" })
    }
  }

  const columns: import("@/components/common/DataTable").Column<Record<string, unknown>>[] = [
    {
      key: "plan_name",
      header: "Plan Name",
      cell: (item) => {
        const sub = item as unknown as Subscription
        return (
          <div className="flex items-center gap-2">
            <CreditCard className="h-4 w-4 text-slate-700 shrink-0" />
            <span className="font-medium">{sub.plan_name}</span>
          </div>
        )
      },
    },
    {
      key: "start_date",
      header: "Start Date",
      sortable: true,
      cell: (item) => {
        const sub = item as unknown as Subscription
        return <span className="font-mono text-sm">{formatDate(sub.start_date)}</span>
      },
    },
    {
      key: "end_date",
      header: "End Date",
      sortable: true,
      cell: (item) => {
        const sub = item as unknown as Subscription
        return <span className="font-mono text-sm">{formatDate(sub.end_date)}</span>
      },
    },
    {
      key: "amount",
      header: "Amount",
      sortable: true,
      cell: (item) => {
        const sub = item as unknown as Subscription
        return <span className="font-mono text-sm">{formatINR(Number(sub.amount))}</span>
      },
    },
    {
      key: "status",
      header: "Status",
      cell: (item) => {
        const sub = item as unknown as Subscription
        return <StatusBadge status={sub.status} type="generic" />
      },
    },
    {
      key: "actions",
      header: "Actions",
      cell: (item) => {
        const sub = item as unknown as Subscription
        return (
          <div className="flex items-center gap-1">
            <Button variant="ghost" size="icon" className="cursor-pointer" onClick={(e) => { e.stopPropagation(); router.push(`/subscriptions/${sub.id}`) }}>
              <Eye className="h-4 w-4" />
            </Button>
            <Button variant="ghost" size="icon" className="cursor-pointer" onClick={(e) => { e.stopPropagation(); router.push(`/subscriptions/${sub.id}`) }}>
              <Edit className="h-4 w-4" />
            </Button>
            <Button variant="ghost" size="icon" className="cursor-pointer text-destructive hover:text-destructive" onClick={(e) => { e.stopPropagation(); setDeleteId(sub.id) }}>
              <Trash2 className="h-4 w-4" />
            </Button>
          </div>
        )
      },
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Subscriptions" description="Manage your subscriptions">
        <Button className="cursor-pointer" onClick={() => router.push("/subscriptions/new")}>
          <Plus className="mr-2 h-4 w-4" />
          Add Subscription
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-700" />
          <Input
            placeholder="Search subscriptions..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            className="pl-9"
          />
        </div>
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
        data={subscriptions as unknown as Record<string, unknown>[]}
        loading={isLoading}
        error={error ? (error as Error).message : null}
        onRetry={() => refetch()}
        emptyMessage="No subscriptions found. Create your first subscription to get started."
        emptyAction={{ label: "Add Subscription", onClick: () => router.push("/subscriptions/new") }}
        onRowClick={(item) => router.push(`/subscriptions/${(item as unknown as Subscription).id}`)}
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
        title="Delete Subscription"
        description="Are you sure you want to delete this subscription? This action cannot be undone."
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteSub.isPending}
      />
    </div>
  )
}
