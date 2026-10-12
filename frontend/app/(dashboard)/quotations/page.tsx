"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import {
  Plus,
  Search,
  Eye,
  Send,
  CheckCircle,
  XCircle,
} from "lucide-react"

import {
  useQuotations,
  useSendQuotation,
  useAcceptQuotation,
  useRejectQuotation,
} from "@/hooks/use-quotations"
import { QUOTATION_STATUSES } from "@/lib/constants"
import { formatDate, formatINR } from "@/lib/utils"
import { PageHeader } from "@/components/common/PageHeader"
import { DataTable, type Column } from "@/components/common/DataTable"
import { StatusBadge } from "@/components/common/StatusBadge"
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

export default function QuotationsPage() {
  const router = useRouter()
  const { toast } = useToast()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState("")
  const [debouncedSearch, setDebouncedSearch] = useState("")
  const [pageSize, setPageSize] = useState("10")
  const [statusFilter, setStatusFilter] = useState("")
  const [sendId, setSendId] = useState<number | null>(null)
  const [acceptId, setAcceptId] = useState<number | null>(null)
  const [rejectId, setRejectId] = useState<number | null>(null)

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearch(search), 300)
    return () => clearTimeout(timer)
  }, [search])

  const { data, isLoading, error, refetch } = useQuotations({
    page,
    page_size: parseInt(pageSize),
    search: debouncedSearch || undefined,
    status: statusFilter || undefined,
  })

  const sendMutation = useSendQuotation()
  const acceptMutation = useAcceptQuotation()
  const rejectMutation = useRejectQuotation()

  const handleSend = async () => {
    if (!sendId) return
    try {
      await sendMutation.mutateAsync(sendId)
      toast({ title: "Quotation sent", variant: "success" })
      setSendId(null)
    } catch {
      toast({ title: "Failed to send quotation", variant: "destructive" })
    }
  }

  const handleAccept = async () => {
    if (!acceptId) return
    try {
      const result = await acceptMutation.mutateAsync(acceptId)
      const bookingId = result?.data?.booking_id
      toast({ title: "Quotation accepted", description: "Booking has been created.", variant: "success" })
      setAcceptId(null)
      if (bookingId) {
        router.push(`/bookings/${bookingId}`)
      }
    } catch {
      toast({ title: "Failed to accept quotation", variant: "destructive" })
    }
  }

  const handleReject = async () => {
    if (!rejectId) return
    try {
      await rejectMutation.mutateAsync(rejectId)
      toast({ title: "Quotation rejected", variant: "success" })
      setRejectId(null)
    } catch {
      toast({ title: "Failed to reject quotation", variant: "destructive" })
    }
  }

  const canSend = (status: string) => status === "DRAFT"
  const canAccept = (status: string) => status === "SENT"
  const canReject = (status: string) => status === "SENT"

  const columns: Column<Record<string, unknown>>[] = [
    {
      key: "id",
      header: "ID",
      cell: (item) => (
        <Link
          href={`/quotations/${item.id as number}`}
          className="font-medium text-primary hover:underline"
        >
          #{item.id as number}
        </Link>
      ),
    },
    {
      key: "customer_name",
      header: "Customer",
      cell: (item) => (
        <span>{(item.customer_name as string) || `Customer #${item.customer as number}`}</span>
      ),
    },
    {
      key: "total_amount",
      header: "Amount",
      cell: (item) => formatINR(Number(item.total_amount)),
    },
    {
      key: "status",
      header: "Status",
      cell: (item) => <StatusBadge status={item.status as string} type="generic" />,
    },
    {
      key: "valid_until",
      header: "Valid Until",
      cell: (item) => formatDate(item.valid_until as string),
    },
    {
      key: "item_count",
      header: "Items",
      cell: (item) => (
        <span className="text-muted-foreground">{item.item_count as number ?? 0}</span>
      ),
    },
    {
      key: "actions",
      header: "Actions",
      cell: (item) => (
        <div className="flex items-center gap-1">
          <Button
            variant="ghost"
            size="icon"
            aria-label="View quotation"
            className="h-8 w-8 cursor-pointer"
            onClick={(e) => {
              e.stopPropagation()
              router.push(`/quotations/${item.id as number}`)
            }}
          >
            <Eye aria-hidden="true" focusable="false" className="h-4 w-4" />
          </Button>
          {canSend(item.status as string) && (
            <Button
              variant="ghost"
              size="icon"
              aria-label="Send quotation"
              className="h-8 w-8 text-blue-600 hover:text-blue-600 cursor-pointer"
              onClick={(e) => {
                e.stopPropagation()
                setSendId(item.id as number)
              }}
              title="Send Quotation"
            >
              <Send aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
          )}
          {canAccept(item.status as string) && (
            <Button
              variant="ghost"
              size="icon"
              aria-label="Accept quotation"
              className="h-8 w-8 text-success hover:text-success cursor-pointer"
              onClick={(e) => {
                e.stopPropagation()
                setAcceptId(item.id as number)
              }}
              title="Accept Quotation"
            >
              <CheckCircle aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
          )}
          {canReject(item.status as string) && (
            <Button
              variant="ghost"
              size="icon"
              aria-label="Reject quotation"
              className="h-8 w-8 text-destructive hover:text-destructive cursor-pointer"
              onClick={(e) => {
                e.stopPropagation()
                setRejectId(item.id as number)
              }}
              title="Reject Quotation"
            >
              <XCircle aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
          )}
        </div>
      ),
    },
  ]

  const quotations = (data?.data || []) as unknown as Record<string, unknown>[]
  const pagination = data?.pagination

  return (
    <div className="space-y-6">
      <PageHeader title="Quotations" description="Manage and track customer quotations">
        <Button asChild className="cursor-pointer">
          <Link href="/quotations/new">
            <Plus className="h-4 w-4 mr-2" />
            New Quotation
          </Link>
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search by customer name..."
            className="pl-9"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setPage(1)
            }}
          />
        </div>
        <Select
          value={statusFilter}
          onValueChange={(v) => {
            setStatusFilter(v === "all" ? "" : v)
            setPage(1)
          }}
        >
          <SelectTrigger className="w-full sm:w-40 cursor-pointer">
            <SelectValue placeholder="All Statuses" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Statuses</SelectItem>
            {QUOTATION_STATUSES.map((s) => (
              <SelectItem key={s} value={s}>
                {s.replace(/_/g, " ")}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <DataTable
        columns={columns}
        data={quotations}
        loading={isLoading}
        error={error ? (error as Error).message : null}
        onRetry={() => refetch()}
        emptyMessage="No quotations found. Click 'New Quotation' to create one."
        emptyAction={{ label: "New Quotation", onClick: () => router.push("/quotations/new") }}
      />

      {pagination && pagination.total_pages > 1 && !isLoading && (
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
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
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
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
        open={sendId !== null}
        onOpenChange={(open) => !open && setSendId(null)}
        title="Send Quotation"
        description="Are you sure you want to send this quotation to the customer?"
        onConfirm={handleSend}
        confirmLabel="Send"
        loading={sendMutation.isPending}
      />

      <ConfirmDialog
        open={acceptId !== null}
        onOpenChange={(open) => !open && setAcceptId(null)}
        title="Accept Quotation"
        description="Accepting this quotation will create a booking. Continue?"
        onConfirm={handleAccept}
        confirmLabel="Accept & Create Booking"
        loading={acceptMutation.isPending}
      />

      <ConfirmDialog
        open={rejectId !== null}
        onOpenChange={(open) => !open && setRejectId(null)}
        title="Reject Quotation"
        description="Are you sure you want to reject this quotation?"
        onConfirm={handleReject}
        confirmLabel="Reject"
        variant="destructive"
        loading={rejectMutation.isPending}
      />
    </div>
  )
}
