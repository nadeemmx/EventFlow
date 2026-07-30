"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Plus, Search, Eye, Download, XCircle, MoreHorizontal } from "lucide-react"
import { useContracts, useCancelContract } from "@/hooks/use-contracts"
import { contractsService } from "@/services/contracts.service"
import { PageHeader } from "@/components/common/PageHeader"
import { DataTable } from "@/components/common/DataTable"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { toast } from "@/components/ui/toast"
import { formatDate } from "@/lib/utils"
import { CONTRACT_STATUSES } from "@/lib/constants"
import type { Contract } from "@/types/api"

export default function ContractsPage() {
  const router = useRouter()
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState("All")
  const [page, setPage] = useState(1)
  const [cancelId, setCancelId] = useState<number | null>(null)

  const status = statusFilter === "All" ? undefined : statusFilter

  const { data, isLoading, error, refetch } = useContracts({
    page,
    page_size: 10,
    search: search || undefined,
    status,
  })

  const cancelContract = useCancelContract()

  const contracts = data?.data ?? []
  const pagination = data?.pagination

  const handleDownloadPdf = async (id: number) => {
    try {
      const blob = await contractsService.downloadPdf(id)
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = `contract-${id}.pdf`
      a.click()
      window.URL.revokeObjectURL(url)
      toast({ title: "PDF downloaded", variant: "success" })
    } catch {
      toast({ title: "Failed to download PDF", variant: "destructive" })
    }
  }

  const handleCancel = async () => {
    if (!cancelId) return
    try {
      await cancelContract.mutateAsync(cancelId)
      toast({ title: "Contract cancelled", variant: "warning" })
      setCancelId(null)
    } catch {
      toast({ title: "Failed to cancel contract", variant: "destructive" })
    }
  }

  const columns: import("@/components/common/DataTable").Column<Record<string, unknown>>[] = [
    {
      key: "contract_number",
      header: "Contract #",
      cell: (item) => {
        const contract = item as unknown as Contract
        return <span className="font-mono font-medium text-amber-600 text-sm">{contract.contract_number}</span>
      },
    },
    {
      key: "booking_number",
      header: "Booking #",
      cell: (item) => {
        const contract = item as unknown as Contract
        return <span className="text-sm text-slate-700">{contract.booking_number || `#${contract.booking}`}</span>
      },
    },
    {
      key: "customer_name",
      header: "Customer",
      cell: (item) => {
        const contract = item as unknown as Contract
        return <span className="text-sm">{contract.customer_name || "-"}</span>
      },
    },
    {
      key: "status",
      header: "Status",
      cell: (item) => {
        const contract = item as unknown as Contract
        return <StatusBadge status={contract.status} type="contract" />
      },
    },
    {
      key: "valid_until",
      header: "Valid Until",
      cell: (item) => {
        const contract = item as unknown as Contract
        return <span className="text-sm">{formatDate(contract.valid_until)}</span>
      },
    },
    {
      key: "created_at",
      header: "Created",
      cell: (item) => {
        const contract = item as unknown as Contract
        return <span className="text-sm">{formatDate(contract.created_at)}</span>
      },
    },
    {
      key: "actions",
      header: "Actions",
      cell: (item) => {
        const contract = item as unknown as Contract
        const canCancel = !["SIGNED", "CANCELLED", "EXPIRED"].includes(contract.status)
        return (
          <div className="flex items-center gap-1" onClick={(e) => e.stopPropagation()}>
            <Button
              variant="ghost"
              size="icon"
              className="cursor-pointer"
              onClick={() => router.push(`/contracts/${contract.id}`)}
            >
              <Eye className="h-4 w-4" />
            </Button>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="cursor-pointer">
                  <MoreHorizontal className="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem
                  className="cursor-pointer"
                  onClick={() => router.push(`/contracts/${contract.id}`)}
                >
                  <Eye className="mr-2 h-4 w-4" />
                  View
                </DropdownMenuItem>
                <DropdownMenuItem
                  className="cursor-pointer"
                  onClick={() => handleDownloadPdf(contract.id)}
                >
                  <Download className="mr-2 h-4 w-4" />
                  Download PDF
                </DropdownMenuItem>
                {canCancel && (
                  <DropdownMenuItem
                    className="cursor-pointer text-red-600"
                    onClick={() => setCancelId(contract.id)}
                  >
                    <XCircle className="mr-2 h-4 w-4" />
                    Cancel
                  </DropdownMenuItem>
                )}
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        )
      },
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Contracts" description="Manage all event contracts">
        <Button className="cursor-pointer" onClick={() => router.push("/contracts/new")}>
          <Plus className="mr-2 h-4 w-4" />
          Generate Contract
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-700" />
          <Input
            placeholder="Search by contract number..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setPage(1)
            }}
            className="pl-9"
          />
        </div>
        <Select
          value={statusFilter}
          onValueChange={(v) => {
            setStatusFilter(v)
            setPage(1)
          }}
        >
          <SelectTrigger className="w-full sm:w-[160px] cursor-pointer">
            <SelectValue placeholder="Status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="All">All Status</SelectItem>
            {CONTRACT_STATUSES.map((s) => (
              <SelectItem key={s} value={s} className="cursor-pointer">
                {s.replace(/_/g, " ")}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <DataTable
        columns={columns}
        data={contracts as unknown as Record<string, unknown>[]}
        loading={isLoading}
        error={error ? (error as Error).message : null}
        onRetry={() => refetch()}
        emptyMessage="No contracts found. Generate your first contract to get started."
        emptyAction={{ label: "Generate Contract", onClick: () => router.push("/contracts/new") }}
        onRowClick={(item) => router.push(`/contracts/${(item as unknown as Contract).id}`)}
      />

      {pagination && pagination.total_pages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-slate-700">
            Page {pagination.page} of {pagination.total_pages} ({pagination.total_records} total)
          </p>
          <div className="flex gap-2">
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
      )}

      <ConfirmDialog
        open={!!cancelId}
        onOpenChange={(open) => !open && setCancelId(null)}
        title="Cancel Contract"
        description="Are you sure you want to cancel this contract? This action cannot be undone."
        onConfirm={handleCancel}
        confirmLabel="Cancel Contract"
        variant="destructive"
        loading={cancelContract.isPending}
      />
    </div>
  )
}
