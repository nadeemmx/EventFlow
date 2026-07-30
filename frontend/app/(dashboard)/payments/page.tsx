"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { Plus, Search, Eye, ArrowLeftRight, ArrowUpFromLine, Download } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { PageHeader } from "@/components/common/PageHeader"
import { DataTable } from "@/components/common/DataTable"
import type { Column } from "@/components/common/DataTable"
import { StatusBadge } from "@/components/common/StatusBadge"
import { usePayments, useRefundPayment } from "@/hooks/use-payments"
import { useToast } from "@/components/ui/toast"
import { paymentsService } from "@/services/payments.service"
import { formatINR, formatDate } from "@/lib/utils"
import { PAYMENT_METHODS } from "@/lib/constants"
import type { Payment } from "@/types/api"

export default function PaymentsPage() {
  const router = useRouter()
  const { toast } = useToast()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState("")
  const [paymentMethod, setPaymentMethod] = useState<string>("")
  const [paymentType, setPaymentType] = useState<string>("")
  const [bookingFilter, setBookingFilter] = useState("")
  const [refundingId, setRefundingId] = useState<number | null>(null)
  const [downloadingReceiptId, setDownloadingReceiptId] = useState<number | null>(null)

  const [debouncedSearch, setDebouncedSearch] = useState("")

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearch(search), 300)
    return () => clearTimeout(timer)
  }, [search])

  const params: Record<string, string | number | undefined> = {
    page,
    page_size: 10,
  }
  if (debouncedSearch) params.search = debouncedSearch
  if (paymentMethod) params.payment_method = paymentMethod
  if (paymentType) params.payment_type = paymentType
  if (bookingFilter) params.booking = Number(bookingFilter)

  const { data, isLoading, isError, error, refetch } = usePayments(params)
  const refundMutation = useRefundPayment()

  const payments = data?.data ?? []
  const pagination = data?.pagination

  const handleRefund = async (id: number) => {
    setRefundingId(id)
    try {
      await refundMutation.mutateAsync(id)
      toast({ title: "Payment refunded", variant: "success" })
    } catch {
      toast({ title: "Refund failed", variant: "destructive" })
    } finally {
      setRefundingId(null)
    }
  }

  const handleDownloadReceipt = async (id: number) => {
    setDownloadingReceiptId(id)
    try {
      const blob = await paymentsService.receipt(id)
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = `receipt-${id}.pdf`
      a.click()
      window.URL.revokeObjectURL(url)
      toast({ title: "Receipt downloaded", variant: "success" })
    } catch {
      toast({ title: "Receipt download failed", variant: "destructive" })
    } finally {
      setDownloadingReceiptId(null)
    }
  }

  const columns: Column<Payment & { booking_number?: string }>[] = [
    { key: "id", header: "ID" },
    {
      key: "booking_number",
      header: "Booking #",
      cell: (item) => (
        <button
          className="text-amber-600 hover:underline cursor-pointer"
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
      key: "amount",
      header: "Amount",
      cell: (item) => formatINR(Number(item.amount)),
    },
    {
      key: "payment_method",
      header: "Payment Method",
      cell: (item) => item.payment_method?.replace(/_/g, " "),
    },
    {
      key: "payment_type",
      header: "Type",
      cell: (item) => <StatusBadge status={item.payment_type} type="payment" />,
    },
    {
      key: "payment_date",
      header: "Date",
      cell: (item) => formatDate(item.payment_date),
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
              router.push(`/payments/${item.id}`)
            }}
          >
            <Eye className="h-4 w-4" />
          </Button>
          {item.payment_type === "PAYMENT" && (
            <Button
              variant="ghost"
              size="sm"
              className="cursor-pointer"
              disabled={downloadingReceiptId === item.id}
              onClick={(e) => {
                e.stopPropagation()
                handleDownloadReceipt(item.id)
              }}
            >
              <Download className="h-4 w-4" />
            </Button>
          )}
          {item.payment_type === "PAYMENT" && (
            <Button
              variant="ghost"
              size="sm"
              className="cursor-pointer text-destructive"
              disabled={refundingId === item.id}
              onClick={(e) => {
                e.stopPropagation()
                handleRefund(item.id)
              }}
            >
              <ArrowUpFromLine className="h-4 w-4" />
            </Button>
          )}
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Payments">
        <Button className="cursor-pointer" onClick={() => router.push("/payments/new")}>
          <Plus className="h-4 w-4 mr-2" />
          Record Payment
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-700" />
          <Input
            placeholder="Search by booking #..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setPage(1)
            }}
            className="pl-9"
          />
        </div>
        <Select value={paymentMethod} onValueChange={setPaymentMethod}>
          <SelectTrigger className="w-full sm:w-44 cursor-pointer">
            <SelectValue placeholder="Payment Method" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="ALL">All Methods</SelectItem>
            {PAYMENT_METHODS.map((m) => (
              <SelectItem key={m} value={m}>
                {m.replace(/_/g, " ")}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={paymentType} onValueChange={setPaymentType}>
          <SelectTrigger className="w-full sm:w-40 cursor-pointer">
            <SelectValue placeholder="Payment Type" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="ALL">All Types</SelectItem>
            <SelectItem value="PAYMENT">Payment</SelectItem>
            <SelectItem value="REFUND">Refund</SelectItem>
          </SelectContent>
        </Select>
        <Input
          placeholder="Booking ID"
          type="number"
          value={bookingFilter}
          onChange={(e) => setBookingFilter(e.target.value)}
          className="w-full sm:w-32"
        />
      </div>

      <DataTable
        columns={columns}
        data={payments}
        loading={isLoading}
        emptyMessage="No payments found"
        emptyAction={{ label: "Record Payment", onClick: () => router.push("/payments/new") }}
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
          <span className="text-sm text-slate-700">
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
    </div>
  )
}
