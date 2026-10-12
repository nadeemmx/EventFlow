"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Plus, Search, Gift, Eye, Edit, Trash2 } from "lucide-react"
import { usePackages, useDeletePackage } from "@/hooks/use-packages"
import { PageHeader } from "@/components/common/PageHeader"
import { DataTable } from "@/components/common/DataTable"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { toast } from "@/components/ui/toast"
import { cn, formatINR } from "@/lib/utils"
import type { Package } from "@/types/api"

const statusFilters = ["All", "ACTIVE", "INACTIVE"] as const

export default function PackagesPage() {
  const router = useRouter()
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState("All")
  const [page, setPage] = useState(1)
  const [deleteId, setDeleteId] = useState<number | null>(null)

  const status = statusFilter === "All" ? undefined : statusFilter

  const { data, isLoading, error, refetch } = usePackages({
    page,
    page_size: 10,
    search: search || undefined,
    status,
  })

  const deletePkg = useDeletePackage()

  const packages = data?.data ?? []
  const pagination = data?.pagination

  const handleDelete = async () => {
    if (!deleteId) return
    try {
      await deletePkg.mutateAsync(deleteId)
      toast({ title: "Package deleted", variant: "success" })
      setDeleteId(null)
    } catch {
      toast({ title: "Failed to delete package", variant: "destructive" })
    }
  }

  const columns: import("@/components/common/DataTable").Column<Record<string, unknown>>[] = [
    {
      key: "name",
      header: "Name",
      cell: (item) => {
        const pkg = item as unknown as Package
        return (
          <div className="flex items-center gap-2">
            <Gift className="h-4 w-4 text-slate-700 shrink-0" />
            <span className="font-medium">{pkg.name}</span>
          </div>
        )
      },
    },
    {
      key: "items_count",
      header: "Items",
      sortable: true,
      cell: (item) => {
        const pkg = item as unknown as Package
        return <span className="font-mono text-sm">{pkg.items_count}</span>
      },
    },
    {
      key: "price",
      header: "Price",
      sortable: true,
      cell: (item) => {
        const pkg = item as unknown as Package
        return <span className="font-mono text-sm">{formatINR(Number(pkg.price))}</span>
      },
    },
    {
      key: "status",
      header: "Status",
      cell: (item) => {
        const pkg = item as unknown as Package
        return <StatusBadge status={pkg.status} type="generic" />
      },
    },
    {
      key: "actions",
      header: "Actions",
      cell: (item) => {
        const pkg = item as unknown as Package
        return (
          <div className="flex items-center gap-1">
            <Button variant="ghost" size="icon" aria-label="View package" className="cursor-pointer" onClick={(e) => { e.stopPropagation(); router.push(`/packages/${pkg.id}`) }}>
              <Eye aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
            <Button variant="ghost" size="icon" aria-label="Edit package" className="cursor-pointer" onClick={(e) => { e.stopPropagation(); router.push(`/packages/${pkg.id}`) }}>
              <Edit aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
            <Button variant="ghost" size="icon" aria-label="Delete package" className="cursor-pointer text-destructive hover:text-destructive" onClick={(e) => { e.stopPropagation(); setDeleteId(pkg.id) }}>
              <Trash2 aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
          </div>
        )
      },
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Packages" description="Manage your event packages">
        <Button className="cursor-pointer" onClick={() => router.push("/packages/new")}>
          <Plus className="mr-2 h-4 w-4" />
          Add Package
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-700" />
          <Input
            placeholder="Search packages..."
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
        data={packages as unknown as Record<string, unknown>[]}
        loading={isLoading}
        error={error ? (error as Error).message : null}
        onRetry={() => refetch()}
        emptyMessage="No packages found. Create your first package to get started."
        emptyAction={{ label: "Add Package", onClick: () => router.push("/packages/new") }}
        onRowClick={(item) => router.push(`/packages/${(item as unknown as Package).id}`)}
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
        title="Delete Package"
        description="Are you sure you want to delete this package? This action cannot be undone."
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deletePkg.isPending}
      />
    </div>
  )
}
