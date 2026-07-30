"use client"

import { useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { ArrowLeft, Download, Mail } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { PageHeader } from "@/components/common/PageHeader"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { StatusBadge } from "@/components/common/StatusBadge"
import { useInvoice, useEmailInvoice } from "@/hooks/use-invoices"
import { useToast } from "@/components/ui/toast"
import { invoicesService } from "@/services/invoices.service"
import { Separator } from "@/components/ui/separator"
import { formatINR, formatDate, formatDateTime } from "@/lib/utils"
import type { Invoice } from "@/types/api"

export default function InvoiceDetailClient() {
  const params = useParams()
  const router = useRouter()
  const { toast } = useToast()
  const id = Number(params.id)

  const { data, isLoading, isError, error, refetch } = useInvoice(id)
  const emailMutation = useEmailInvoice()
  const invoice = data?.data

  const handleDownloadPdf = async () => {
    try {
      const blob = await invoicesService.downloadPdf(id)
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = `invoice-${invoice?.invoice_number || id}.pdf`
      a.click()
      window.URL.revokeObjectURL(url)
      toast({ title: "PDF downloaded", variant: "success" })
    } catch {
      toast({ title: "Download failed", variant: "destructive" })
    }
  }

  const handleEmailInvoice = async () => {
    try {
      await emailMutation.mutateAsync(id)
      toast({ title: "Invoice emailed successfully", variant: "success" })
      refetch()
    } catch {
      toast({ title: "Failed to email invoice", variant: "destructive" })
    }
  }

  if (isLoading) return <LoadingState type="page" />
  if (isError) return <ErrorState message={(error as Error)?.message} onRetry={() => refetch()} />
  if (!invoice) return <ErrorState message="Invoice not found" />

  const invoiceData = invoice as Invoice & {
    gst_amount?: string;
    subtotal?: string;
    tax_rate?: number;
    is_emailed?: boolean;
    email_sent_at?: string;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
        <button className="hover:text-foreground cursor-pointer" onClick={() => router.push("/invoices")}>
          Invoices
        </button>
        <span>/</span>
        <span className="text-foreground font-medium">{invoice.invoice_number}</span>
      </div>

      <PageHeader title={`Invoice ${invoice.invoice_number}`}>
        <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/invoices")}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back
        </Button>
        <Button
          variant="outline"
          className="cursor-pointer"
          onClick={handleEmailInvoice}
          disabled={emailMutation.isPending}
        >
          <Mail className="h-4 w-4 mr-2" />
          {emailMutation.isPending ? "Emailing..." : "Email Invoice"}
        </Button>
        <Button className="cursor-pointer" onClick={handleDownloadPdf}>
          <Download className="h-4 w-4 mr-2" />
          Download PDF
        </Button>
      </PageHeader>

      <Card className="print:shadow-none print:border-none">
        <CardHeader>
          <CardTitle>Invoice Details</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <DetailRow label="Invoice Number" value={invoice.invoice_number} />
          <DetailRow
            label="Booking"
            value={
              <button
                className="text-primary hover:underline cursor-pointer"
                onClick={() => router.push(`/bookings/${invoice.booking}`)}
              >
                #{invoice.booking}
              </button>
            }
          />
          <DetailRow label="Invoice Date" value={formatDate(invoice.created_at)} />
          {invoiceData.is_emailed && (
            <DetailRow
              label="Email Status"
              value={
                <div className="flex items-center gap-2">
                  <StatusBadge status="emailed" type="booking" />
                  {invoiceData.email_sent_at && (
                    <span className="text-xs text-muted-foreground">
                      {formatDateTime(invoiceData.email_sent_at)}
                    </span>
                  )}
                </div>
              }
            />
          )}
          <Separator />
          <div className="pt-2">
            <p className="text-sm font-medium text-muted-foreground mb-3">GST Breakdown</p>
            <div className="space-y-2">
              <DetailRow
                label="Subtotal"
                value={formatINR(invoiceData.subtotal ? Number(invoiceData.subtotal) : Number(invoice.total_amount))}
              />
              {invoiceData.gst_amount && (
                <DetailRow
                  label={`GST${invoiceData.tax_rate ? ` (${invoiceData.tax_rate}%)` : ""}`}
                  value={formatINR(Number(invoiceData.gst_amount))}
                />
              )}
              <Separator />
              <DetailRow
                label="Total Amount"
                value={<span className="font-bold text-lg">{formatINR(Number(invoice.total_amount))}</span>}
              />
            </div>
          </div>
          <Separator />
          <DetailRow label="Created At" value={formatDateTime(invoice.created_at)} />
        </CardContent>
      </Card>
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


