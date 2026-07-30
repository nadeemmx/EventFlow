"use client"

import { useState, useEffect, useCallback } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { Plus, Search, Eye, Pencil, Trash2 } from "lucide-react"

import { useCustomers, useDeleteCustomer } from "@/hooks/use-customers"
import { formatDate } from "@/lib/utils"
import { PageHeader } from "@/components/common/PageHeader"
import { DataTable, type Column } from "@/components/common/DataTable"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { useToast } from "@/components/ui/toast"

export default function CustomersPage() {
  const router = useRouter()
  const { toast } = useToast()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState("")
  const [debouncedSearch, setDebouncedSearch] = useState("")
  const [pageSize, setPageSize] = useState("10")
  const [deleteId, setDeleteId] = useState<number | null>(null)

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearch(search), 300)
    return () => clearTimeout(timer)
  }, [search])

  const { data, isLoading, error, refetch } = useCustomers({
    page,
    page_size: parseInt(pageSize),
    search: debouncedSearch || undefined,
  })

  const deleteMutation = useDeleteCustomer()

  const handleDelete = useCallback(async () => {
    if (!deleteId) return
    try {
      await deleteMutation.mutateAsync(deleteId)
      toast({ title: "Customer deleted", variant: "success" })
      setDeleteId(null)
    } catch {
      toast({ title: "Failed to delete customer", variant: "destructive" })
    }
  }, [deleteId, deleteMutation, toast])

  const columns: Column<Record<string, unknown>>[] = [
    {
      key: "full_name",
      header: "Name",
      cell: (item) => (
        <Link
          href={`/customers/${item.id as number}`}
          className="font-medium text-amber-600 hover:underline"
        >
          {item.full_name as string}
        </Link>
      ),
    },
    { key: "mobile", header: "Mobile" },
    { key: "email", header: "Email" },
    {
      key: "address",
      header: "Address",
      cell: (item) => (
        <span className="text-slate-700 truncate max-w-[200px] block">
          {(item.address as string) || "—"}
        </span>
      ),
    },
    {
      key: "created_at",
      header: "Created",
      cell: (item) =>
        item.created_at ? formatDate(item.created_at as string) : "—",
    },
    {
      key: "actions",
      header: "Actions",
      cell: (item) => (
        <div className="flex items-center gap-1">
          <Button
            variant="ghost"
            size="icon"
            className="h-8 w-8 cursor-pointer"
            onClick={(e) => {
              e.stopPropagation()
              router.push(`/customers/${item.id as number}`)
            }}
          >
            <Eye className="h-4 w-4" />
          </Button>
          <Button
            variant="ghost"
            size="icon"
            className="h-8 w-8 cursor-pointer"
            onClick={(e) => {
              e.stopPropagation()
              router.push(`/customers/${item.id as number}`)
            }}
          >
            <Pencil className="h-4 w-4" />
          </Button>
          <Button
            variant="ghost"
            size="icon"
            className="h-8 w-8 text-destructive hover:text-destructive cursor-pointer"
            onClick={(e) => {
              e.stopPropagation()
              setDeleteId(item.id as number)
            }}
          >
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      ),
    },
  ]

  const customers = (data?.data || []) as unknown as Record<string, unknown>[]
  const pagination = data?.pagination

  return (
    <div className="space-y-6">
      <PageHeader title="Customers" description="Manage your customer relationships">
        <Button asChild className="cursor-pointer">
          <Link href="/customers/new">
            <Plus className="h-4 w-4 mr-2" />
            Add Customer
          </Link>
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-700" />
          <Input
            placeholder="Search customers..."
            className="pl-9"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setPage(1)
            }}
          />
        </div>
      </div>

      <DataTable
        columns={columns}
        data={customers}
        loading={isLoading}
        error={error ? (error as Error).message : null}
        onRetry={() => refetch()}
        emptyMessage="No customers found. Add your first customer to get started."
        emptyAction={{ label: "Add Customer", onClick: () => router.push("/customers/new") }}
      />

      {pagination && pagination.total_pages > 1 && !isLoading && (
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-2 text-sm text-slate-700">
            <span>Rows per page:</span>
            <Select value={pageSize} onValueChange={(v) => { setPageSize(v); setPage(1) }}>
              <SelectTrigger className="h-8 w-16">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="10">10</SelectItem>
                <SelectItem value="20">20</SelectItem>
                <SelectItem value="50">50</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="flex items-center gap-2 text-sm text-slate-700">
            <span>
              Page {pagination.page} of {pagination.total_pages}
            </span>
            <div className="flex gap-1">
              <Button
                variant="outline"
                size="sm"
                disabled={page <= 1}
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                className="cursor-pointer"
              >
                Previous
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={page >= pagination.total_pages}
                onClick={() => setPage((p) => p + 1)}
                className="cursor-pointer"
              >
                Next
              </Button>
            </div>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={deleteId !== null}
        onOpenChange={(open) => !open && setDeleteId(null)}
        title="Delete Customer"
        description="Are you sure you want to delete this customer? This action cannot be undone."
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteMutation.isPending}
      />
    </div>
  )
}
