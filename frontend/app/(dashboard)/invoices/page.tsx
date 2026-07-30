"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Plus, Search, Eye, Download, Trash2, Mail } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { PageHeader } from "@/components/common/PageHeader"
import { DataTable } from "@/components/common/DataTable"
import type { Column } from "@/components/common/DataTable"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { StatusBadge } from "@/components/common/StatusBadge"
import { useInvoices, useDeleteInvoice, useEmailInvoice } from "@/hooks/use-invoices"
import { useToast } from "@/components/ui/toast"
import { invoicesService } from "@/services/invoices.service"
import { formatINR, formatDate } from "@/lib/utils"
import type { Invoice } from "@/types/api"

export default function InvoicesPage() {
  const router = useRouter()
  const { toast } = useToast()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState("")
  const [deleteId, setDeleteId] = useState<number | null>(null)
  const [emailingId, setEmailingId] = useState<number | null>(null)
  const [dateFrom, setDateFrom] = useState("")
  const [dateTo, setDateTo] = useState("")

  const { data, isLoading, isError, error, refetch } = useInvoices({ page, search: search || undefined, date_from: dateFrom || undefined, date_to: dateTo || undefined })
  const deleteMutation = useDeleteInvoice()
  const emailMutation = useEmailInvoice()

  const invoices = data?.data ?? []
  const pagination = data?.pagination

  const handleDownloadPdf = async (id: number) => {
    try {
      const blob = await invoicesService.downloadPdf(id)
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = `invoice-${id}.pdf`
      a.click()
      window.URL.revokeObjectURL(url)
      toast({ title: "PDF downloaded", variant: "success" })
    } catch {
      toast({ title: "Download failed", variant: "destructive" })
    }
  }

  const handleDelete = async () => {
    if (!deleteId) return
    try {
      await deleteMutation.mutateAsync(deleteId)
      toast({ title: "Invoice deleted", variant: "success" })
      setDeleteId(null)
      refetch()
    } catch {
      toast({ title: "Delete failed", variant: "destructive" })
    }
  }

  const handleEmailInvoice = async (id: number) => {
    setEmailingId(id)
    try {
      await emailMutation.mutateAsync(id)
      toast({ title: "Invoice emailed successfully", variant: "success" })
      refetch()
    } catch {
      toast({ title: "Failed to email invoice", variant: "destructive" })
    } finally {
      setEmailingId(null)
    }
  }

  const columns: Column<Invoice & { is_emailed?: boolean }>[] = [
    { key: "invoice_number", header: "Invoice #" },
    {
      key: "booking",
      header: "Booking #",
      cell: (item) => (
        <button
          className="text-primary hover:underline cursor-pointer"
          onClick={(e) => {
            e.stopPropagation()
            router.push(`/bookings/${item.booking}`)
          }}
        >
          #{item.booking}
        </button>
      ),
    },
    {
      key: "created_at",
      header: "Invoice Date",
      cell: (item) => formatDate(item.created_at),
    },
    {
      key: "total_amount",
      header: "Total",
      cell: (item) => formatINR(Number(item.total_amount)),
    },
    {
      key: "is_emailed",
      header: "Emailed",
      cell: (item) => item.is_emailed ? (
        <StatusBadge status="emailed" type="booking" />
      ) : (
        <span className="text-xs text-muted-foreground">No</span>
      ),
    },
    {
      key: "actions",
      header: "Actions",
      cell: (item) => (
        <div className="flex items-center gap-2">
          <Button
            variant="ghost"
            size="sm"
            className="cursor-pointer"
            onClick={(e) => {
              e.stopPropagation()
              router.push(`/invoices/${item.id}`)
            }}
          >
            <Eye className="h-4 w-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="cursor-pointer"
            disabled={emailingId === item.id}
            onClick={(e) => {
              e.stopPropagation()
              handleEmailInvoice(item.id)
            }}
          >
            <Mail className="h-4 w-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="cursor-pointer"
            onClick={(e) => {
              e.stopPropagation()
              handleDownloadPdf(item.id)
            }}
          >
            <Download className="h-4 w-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="cursor-pointer text-destructive"
            onClick={(e) => {
              e.stopPropagation()
              setDeleteId(item.id)
            }}
          >
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Invoices">
        <Button className="cursor-pointer" onClick={() => router.push("/invoices/new")}>
          <Plus className="h-4 w-4 mr-2" />
          Generate Invoice
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-3 flex-wrap">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search by invoice number..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
        <div className="flex items-center gap-2">
          <Input
            type="date"
            value={dateFrom}
            onChange={(e) => setDateFrom(e.target.value)}
            className="w-full sm:w-40"
            placeholder="From date"
          />
          <span className="text-sm text-muted-foreground">to</span>
          <Input
            type="date"
            value={dateTo}
            onChange={(e) => setDateTo(e.target.value)}
            className="w-full sm:w-40"
            placeholder="To date"
          />
        </div>
      </div>

      <DataTable
        columns={columns}
        data={invoices}
        loading={isLoading}
        emptyMessage="No invoices found"
        error={isError ? (error as Error)?.message : null}
        onRetry={() => refetch()}
      />

      {pagination && pagination.total_pages > 1 && (
        <div className="flex items-center justify-center gap-2">
          <Button
            variant="outline"
            size="sm"
            className="cursor-pointer"
            disabled={page <= 1}
            onClick={() => setPage((p) => Math.max(1, p - 1))}
          >
            Previous
          </Button>
          <span className="text-sm text-muted-foreground">
            Page {pagination.page} of {pagination.total_pages}
          </span>
          <Button
            variant="outline"
            size="sm"
            className="cursor-pointer"
            disabled={page >= pagination.total_pages}
            onClick={() => setPage((p) => p + 1)}
          >
            Next
          </Button>
        </div>
      )}

      <ConfirmDialog
        open={!!deleteId}
        onOpenChange={(open) => !open && setDeleteId(null)}
        title="Delete Invoice"
        description="Are you sure you want to delete this invoice? This action cannot be undone."
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteMutation.isPending}
      />
    </div>
  )
}
