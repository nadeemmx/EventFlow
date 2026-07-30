"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Plus, Search, Package, Eye, Edit, Trash2 } from "lucide-react"
import { useInventory, useDeleteInventoryItem } from "@/hooks/use-inventory"
import { PageHeader } from "@/components/common/PageHeader"
import { DataTable } from "@/components/common/DataTable"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { toast } from "@/components/ui/toast"
import { cn } from "@/lib/utils"
import { INVENTORY_CATEGORIES } from "@/lib/constants"
import type { InventoryItem } from "@/types/api"

const statusFilters = ["All", "IN_STOCK", "LOW_STOCK", "OUT_OF_STOCK"] as const

export default function InventoryPage() {
  const router = useRouter()
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState("All")
  const [categoryFilter, setCategoryFilter] = useState("All")
  const [page, setPage] = useState(1)
  const [deleteId, setDeleteId] = useState<number | null>(null)

  const status = statusFilter === "All" ? undefined : statusFilter
  const category = categoryFilter === "All" ? undefined : categoryFilter

  const { data, isLoading, error, refetch } = useInventory({
    page,
    page_size: 10,
    search: search || undefined,
    status,
    category,
  })

  const deleteItem = useDeleteInventoryItem()

  const items = data?.data ?? []
  const pagination = data?.pagination

  const handleDelete = async () => {
    if (!deleteId) return
    try {
      await deleteItem.mutateAsync(deleteId)
      toast({ title: "Item deleted", variant: "success" })
      setDeleteId(null)
    } catch {
      toast({ title: "Failed to delete item", variant: "destructive" })
    }
  }

  const columns: import("@/components/common/DataTable").Column<Record<string, unknown>>[] = [
    {
      key: "name",
      header: "Name",
      cell: (item) => {
        const inv = item as unknown as InventoryItem
        return (
          <div className="flex items-center gap-2">
            <Package className="h-4 w-4 text-slate-700 shrink-0" />
            <span className="font-medium">{inv.name}</span>
          </div>
        )
      },
    },
    {
      key: "category",
      header: "Category",
      cell: (item) => {
        const inv = item as unknown as InventoryItem
        return <span className="text-sm text-slate-700">{inv.category.replace(/_/g, " ")}</span>
      },
    },
    {
      key: "quantity",
      header: "Quantity",
      sortable: true,
      cell: (item) => {
        const inv = item as unknown as InventoryItem
        return <span className="font-mono text-sm">{inv.quantity.toLocaleString()}</span>
      },
    },
    {
      key: "unit",
      header: "Unit",
      cell: (item) => {
        const inv = item as unknown as InventoryItem
        return <span className="text-sm">{inv.unit}</span>
      },
    },
    {
      key: "status",
      header: "Status",
      cell: (item) => {
        const inv = item as unknown as InventoryItem
        return <StatusBadge status={inv.status} type="generic" />
      },
    },
    {
      key: "actions",
      header: "Actions",
      cell: (item) => {
        const inv = item as unknown as InventoryItem
        return (
          <div className="flex items-center gap-1">
            <Button
              variant="ghost"
              size="icon"
              className="cursor-pointer"
              onClick={(e) => { e.stopPropagation(); router.push(`/inventory/${inv.id}`) }}
            >
              <Eye className="h-4 w-4" />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              className="cursor-pointer"
              onClick={(e) => { e.stopPropagation(); router.push(`/inventory/${inv.id}`) }}
            >
              <Edit className="h-4 w-4" />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              className="cursor-pointer text-destructive hover:text-destructive"
              onClick={(e) => { e.stopPropagation(); setDeleteId(inv.id) }}
            >
              <Trash2 className="h-4 w-4" />
            </Button>
          </div>
        )
      },
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Inventory" description="Manage your event inventory items">
        <Button className="cursor-pointer" onClick={() => router.push("/inventory/new")}>
          <Plus className="mr-2 h-4 w-4" />
          Add Item
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-700" />
          <Input
            placeholder="Search inventory..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            className="pl-9"
          />
        </div>
        <Select
          value={categoryFilter}
          onValueChange={(v) => { setCategoryFilter(v); setPage(1) }}
        >
          <SelectTrigger className="w-full sm:w-[180px] cursor-pointer">
            <SelectValue placeholder="All Categories" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="All">All Categories</SelectItem>
            {INVENTORY_CATEGORIES.map((c) => (
              <SelectItem key={c} value={c}>{c.replace(/_/g, " ")}</SelectItem>
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
        data={items as unknown as Record<string, unknown>[]}
        loading={isLoading}
        error={error ? (error as Error).message : null}
        onRetry={() => refetch()}
        emptyMessage="No inventory items found. Create your first item to get started."
        emptyAction={{ label: "Add Item", onClick: () => router.push("/inventory/new") }}
        onRowClick={(item) => router.push(`/inventory/${(item as unknown as InventoryItem).id}`)}
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
        title="Delete Item"
        description="Are you sure you want to delete this inventory item? This action cannot be undone."
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteItem.isPending}
      />
    </div>
  )
}
