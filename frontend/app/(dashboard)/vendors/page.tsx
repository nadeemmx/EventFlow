"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Plus, Search, Building2, Eye, Edit, Trash2 } from "lucide-react"
import { useVendors, useDeleteVendor } from "@/hooks/use-vendors"
import { PageHeader } from "@/components/common/PageHeader"
import { DataTable } from "@/components/common/DataTable"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { toast } from "@/components/ui/toast"
import { cn } from "@/lib/utils"
import { VENDOR_SERVICE_TYPES } from "@/lib/constants"
import type { Vendor } from "@/types/api"

const statusFilters = ["All", "ACTIVE", "INACTIVE"] as const

export default function VendorsPage() {
  const router = useRouter()
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState("All")
  const [serviceFilter, setServiceFilter] = useState("All")
  const [page, setPage] = useState(1)
  const [deleteId, setDeleteId] = useState<number | null>(null)

  const status = statusFilter === "All" ? undefined : statusFilter
  const service_type = serviceFilter === "All" ? undefined : serviceFilter

  const { data, isLoading, error, refetch } = useVendors({
    page,
    page_size: 10,
    search: search || undefined,
    status,
    service_type,
  })

  const deleteVendor = useDeleteVendor()

  const vendors = data?.data ?? []
  const pagination = data?.pagination

  const handleDelete = async () => {
    if (!deleteId) return
    try {
      await deleteVendor.mutateAsync(deleteId)
      toast({ title: "Vendor deleted", variant: "success" })
      setDeleteId(null)
    } catch {
      toast({ title: "Failed to delete vendor", variant: "destructive" })
    }
  }

  const columns: import("@/components/common/DataTable").Column<Record<string, unknown>>[] = [
    {
      key: "company_name",
      header: "Company",
      cell: (item) => {
        const vendor = item as unknown as Vendor
        return (
          <div className="flex items-center gap-2">
            <Building2 className="h-4 w-4 text-slate-700 shrink-0" />
            <span className="font-medium">{vendor.company_name}</span>
          </div>
        )
      },
    },
    {
      key: "service_type",
      header: "Service Type",
      cell: (item) => {
        const vendor = item as unknown as Vendor
        return <span className="text-sm text-slate-700">{vendor.service_type.replace(/_/g, " ")}</span>
      },
    },
    {
      key: "contact_person",
      header: "Contact Person",
      cell: (item) => {
        const vendor = item as unknown as Vendor
        return <span className="text-sm">{vendor.contact_person}</span>
      },
    },
    {
      key: "mobile",
      header: "Mobile",
      cell: (item) => {
        const vendor = item as unknown as Vendor
        return <span className="font-mono text-sm">{vendor.mobile}</span>
      },
    },
    {
      key: "status",
      header: "Status",
      cell: (item) => {
        const vendor = item as unknown as Vendor
        return <StatusBadge status={vendor.status} type="generic" />
      },
    },
    {
      key: "actions",
      header: "Actions",
      cell: (item) => {
        const vendor = item as unknown as Vendor
        return (
          <div className="flex items-center gap-1">
            <Button variant="ghost" size="icon" aria-label="View vendor" className="cursor-pointer" onClick={(e) => { e.stopPropagation(); router.push(`/vendors/${vendor.id}`) }}>
              <Eye aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
            <Button variant="ghost" size="icon" aria-label="Edit vendor" className="cursor-pointer" onClick={(e) => { e.stopPropagation(); router.push(`/vendors/${vendor.id}`) }}>
              <Edit aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
            <Button variant="ghost" size="icon" aria-label="Delete vendor" className="cursor-pointer text-destructive hover:text-destructive" onClick={(e) => { e.stopPropagation(); setDeleteId(vendor.id) }}>
              <Trash2 aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
          </div>
        )
      },
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Vendors" description="Manage your event vendors">
        <Button className="cursor-pointer" onClick={() => router.push("/vendors/new")}>
          <Plus className="mr-2 h-4 w-4" />
          Add Vendor
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-700" />
          <Input
            placeholder="Search vendors..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            className="pl-9"
          />
        </div>
        <Select value={serviceFilter} onValueChange={(v) => { setServiceFilter(v); setPage(1) }}>
          <SelectTrigger className="w-full sm:w-[180px] cursor-pointer">
            <SelectValue placeholder="All Services" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="All">All Services</SelectItem>
            {VENDOR_SERVICE_TYPES.map((t) => (
              <SelectItem key={t} value={t}>{t.replace(/_/g, " ")}</SelectItem>
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
        data={vendors as unknown as Record<string, unknown>[]}
        loading={isLoading}
        error={error ? (error as Error).message : null}
        onRetry={() => refetch()}
        emptyMessage="No vendors found. Add your first vendor to get started."
        emptyAction={{ label: "Add Vendor", onClick: () => router.push("/vendors/new") }}
        onRowClick={(item) => router.push(`/vendors/${(item as unknown as Vendor).id}`)}
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
        title="Delete Vendor"
        description="Are you sure you want to delete this vendor? This action cannot be undone."
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteVendor.isPending}
      />
    </div>
  )
}
