"use client"

import { useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { ArrowLeft, ArrowUpFromLine, Download } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { PageHeader } from "@/components/common/PageHeader"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { usePayment, useRefundPayment } from "@/hooks/use-payments"
import { useBookingOutstanding } from "@/hooks/use-bookings"
import { useToast } from "@/components/ui/toast"
import { paymentsService } from "@/services/payments.service"
import { formatINR, formatDate, formatDateTime } from "@/lib/utils"

export default function PaymentDetailClient() {
  const params = useParams()
  const router = useRouter()
  const { toast } = useToast()
  const id = Number(params.id)
  const [showRefundDialog, setShowRefundDialog] = useState(false)

  const { data, isLoading, isError, error, refetch } = usePayment(id)
  const refundMutation = useRefundPayment()

  const payment = data?.data
  const { data: outstandingRes } = useBookingOutstanding(payment?.booking ?? 0)

  const outstanding = outstandingRes?.data

  const handleRefund = async () => {
    try {
      await refundMutation.mutateAsync(id)
      toast({ title: "Payment refunded successfully", variant: "success" })
      setShowRefundDialog(false)
      refetch()
    } catch {
      toast({ title: "Refund failed", variant: "destructive" })
      setShowRefundDialog(false)
    }
  }

  const handleDownloadReceipt = async () => {
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
    }
  }

  if (isLoading) return <LoadingState type="page" />
  if (isError) return <ErrorState message={(error as Error)?.message} onRetry={() => refetch()} />
  if (!payment) return <ErrorState message="Payment not found" />

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
        <button className="hover:text-foreground cursor-pointer" onClick={() => router.push("/payments")}>
          Payments
        </button>
        <span>/</span>
        <span className="text-foreground font-medium">Payment #{payment.id}</span>
      </div>

      <PageHeader title={`Payment #${payment.id}`}>
        <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/payments")}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back
        </Button>
        {payment.payment_type === "PAYMENT" && (
          <Button variant="outline" className="cursor-pointer" onClick={handleDownloadReceipt}>
            <Download className="h-4 w-4 mr-2" />
            Download Receipt
          </Button>
        )}
        {payment.payment_type === "PAYMENT" && (
          <Button
            variant="destructive"
            className="cursor-pointer"
            onClick={() => setShowRefundDialog(true)}
            disabled={refundMutation.isPending}
          >
            <ArrowUpFromLine className="h-4 w-4 mr-2" />
            {refundMutation.isPending ? "Refunding..." : "Refund"}
          </Button>
        )}
      </PageHeader>

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Payment Details</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <DetailRow label="Amount" value={formatINR(Number(payment.amount))} />
            <DetailRow label="Payment Method" value={payment.payment_method?.replace(/_/g, " ")} />
            <DetailRow
              label="Payment Type"
              value={<StatusBadge status={payment.payment_type} type="payment" />}
            />
            {(payment as any).transaction_reference && (
              <DetailRow label="Transaction Reference" value={(payment as any).transaction_reference} />
            )}
            <DetailRow label="Payment Date" value={formatDate(payment.payment_date)} />
            {(payment as any).notes && (
              <DetailRow label="Notes" value={(payment as any).notes} />
            )}
            <DetailRow
              label="Booking"
              value={
                <button
                  className="text-primary hover:underline cursor-pointer"
                  onClick={() => router.push(`/bookings/${payment.booking}`)}
                >
                  #{payment.booking}
                </button>
              }
            />
            <DetailRow label="Created At" value={formatDateTime(payment.payment_date)} />
          </CardContent>
        </Card>

        {outstanding && (
          <Card>
            <CardHeader>
              <CardTitle>Booking Financial Summary</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <DetailRow label="Booking Total" value={formatINR(Number(outstanding.total_amount))} />
              <DetailRow label="Total Paid" value={formatINR(Number(outstanding.paid_amount))} />
              <DetailRow
                label="Outstanding Balance"
                value={
                  <span className={Number(outstanding.balance_due) <= 0 ? "text-green-600 font-semibold" : "text-destructive font-semibold"}>
                    {formatINR(Number(outstanding.balance_due))}
                  </span>
                }
              />
            </CardContent>
          </Card>
        )}
      </div>

      <ConfirmDialog
        open={showRefundDialog}
        onOpenChange={setShowRefundDialog}
        title="Confirm Refund"
        description={`Are you sure you want to refund ${formatINR(Number(payment.amount))}? This action cannot be undone.`}
        onConfirm={handleRefund}
        confirmLabel="Process Refund"
        variant="destructive"
        loading={refundMutation.isPending}
      />
    </div>
  )
}

function DetailRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-4">
      <span className="text-sm font-medium text-muted-foreground min-w-[160px]">{label}</span>
      <span className="text-sm">{value}</span>
    </div>
  )
}
