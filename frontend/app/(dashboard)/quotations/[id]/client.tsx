"use client"

import { useState } from "react"
import { useParams, useRouter } from "next/navigation"
import Link from "next/link"
import {
  ArrowLeft,
  Pencil,
  Send,
  CheckCircle,
  XCircle,
  Calendar,
  Package,
  MapPin,
  User,
  FileText,
} from "lucide-react"

import {
  useQuotation,
  useSendQuotation,
  useAcceptQuotation,
  useRejectQuotation,
} from "@/hooks/use-quotations"
import { formatDate, formatINR } from "@/lib/utils"
import { PageHeader } from "@/components/common/PageHeader"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { useToast } from "@/components/ui/toast"

export default function QuotationDetailClient() {
  const params = useParams()
  const router = useRouter()
  const { toast } = useToast()
  const id = Number(params.id)
  const [sendOpen, setSendOpen] = useState(false)
  const [acceptOpen, setAcceptOpen] = useState(false)
  const [rejectOpen, setRejectOpen] = useState(false)

  const { data, isLoading, error, refetch } = useQuotation(id)
  const sendMutation = useSendQuotation()
  const acceptMutation = useAcceptQuotation()
  const rejectMutation = useRejectQuotation()

  const quotation = data?.data as
    | (Record<string, unknown> & {
        id: number
        customer: number
        customer_name?: string
        venue?: number
        venue_name?: string
        package?: number
        valid_until: string
        status: string
        subtotal: string
        tax_amount: string
        total_amount: string
        items?: Array<{
          id: number
          item_name: string
          quantity: number
          unit_price: number
          total_price: number
        }>
        item_count?: number
        created_at: string
        updated_at?: string
      })
    | undefined

  const items = quotation?.items || []

  const handleSend = async () => {
    try {
      await sendMutation.mutateAsync(id)
      toast({ title: "Quotation sent", variant: "success" })
      setSendOpen(false)
      refetch()
    } catch {
      toast({ title: "Failed to send quotation", variant: "destructive" })
    }
  }

  const handleAccept = async () => {
    try {
      const result = await acceptMutation.mutateAsync(id)
      const bookingId = result?.data?.booking_id
      toast({ title: "Quotation accepted", description: "Booking has been created.", variant: "success" })
      setAcceptOpen(false)
      if (bookingId) {
        router.push(`/bookings/${bookingId}`)
      } else {
        router.push("/bookings")
      }
    } catch {
      toast({ title: "Failed to accept quotation", variant: "destructive" })
    }
  }

  const handleReject = async () => {
    try {
      await rejectMutation.mutateAsync(id)
      toast({ title: "Quotation rejected", variant: "success" })
      setRejectOpen(false)
      refetch()
    } catch {
      toast({ title: "Failed to reject quotation", variant: "destructive" })
    }
  }

  const canSend = quotation?.status === "DRAFT"
  const canAccept = quotation?.status === "SENT"
  const canReject = quotation?.status === "SENT"

  if (isLoading) return <LoadingState type="page" />
  if (error) return <ErrorState message={(error as Error).message} onRetry={() => refetch()} />
  if (!quotation) return <ErrorState message="Quotation not found" />

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
        <Link href="/quotations" className="hover:text-foreground">
          Quotations
        </Link>
        <span>/</span>
        <span className="text-foreground font-medium truncate">
          {quotation.customer_name || `Quotation #${quotation.id}`}
        </span>
      </div>

      <PageHeader title={quotation.customer_name || `Quotation #${quotation.id}`}>
        <div className="flex gap-2">
          <Button variant="outline" asChild className="cursor-pointer">
            <Link href="/quotations">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back
            </Link>
          </Button>
          <Button variant="outline" asChild className="cursor-pointer">
            <Link href={`/quotations/${id}/edit`}>
              <Pencil className="h-4 w-4 mr-2" />
              Edit
            </Link>
          </Button>
          {canSend && (
            <Button
              variant="default"
              onClick={() => setSendOpen(true)}
              className="cursor-pointer"
            >
              <Send className="h-4 w-4 mr-2" />
              Send
            </Button>
          )}
          {canAccept && (
            <Button
              variant="default"
              className="bg-success hover:bg-success/90 cursor-pointer"
              onClick={() => setAcceptOpen(true)}
            >
              <CheckCircle className="h-4 w-4 mr-2" />
              Accept
            </Button>
          )}
          {canReject && (
            <Button
              variant="destructive"
              onClick={() => setRejectOpen(true)}
              className="cursor-pointer"
            >
              <XCircle className="h-4 w-4 mr-2" />
              Reject
            </Button>
          )}
        </div>
      </PageHeader>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Quotation Info</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-start gap-3">
              <User className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
              <div>
                <p className="text-sm font-medium">Customer</p>
                <p className="text-sm text-muted-foreground">
                  {quotation.customer_name || `ID: ${quotation.customer}`}
                </p>
              </div>
            </div>
            {quotation.venue_name && (
              <div className="flex items-start gap-3">
                <MapPin className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium">Venue</p>
                  <p className="text-sm text-muted-foreground">{quotation.venue_name}</p>
                </div>
              </div>
            )}
            {quotation.package && (
              <div className="flex items-start gap-3">
                <Package className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium">Package</p>
                  <p className="text-sm text-muted-foreground">Package #{quotation.package}</p>
                </div>
              </div>
            )}
            <div className="flex items-start gap-3">
              <Calendar className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
              <div>
                <p className="text-sm font-medium">Valid Until</p>
                <p className="text-sm text-muted-foreground">
                  {formatDate(quotation.valid_until)}
                </p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <FileText className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
              <div>
                <p className="text-sm font-medium">Status</p>
                <StatusBadge status={quotation.status} type="generic" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Items</CardTitle>
        </CardHeader>
        <CardContent>
          {items.length === 0 ? (
            <p className="text-sm text-muted-foreground text-center py-4">No items in this quotation.</p>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Item</TableHead>
                    <TableHead className="text-right">Quantity</TableHead>
                    <TableHead className="text-right">Unit Price</TableHead>
                    <TableHead className="text-right">Total</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {items.map((item, i) => (
                    <TableRow key={item.id || i}>
                      <TableCell className="font-medium">{item.item_name}</TableCell>
                      <TableCell className="text-right">{item.quantity}</TableCell>
                      <TableCell className="text-right">{formatINR(item.unit_price)}</TableCell>
                      <TableCell className="text-right">{formatINR(item.total_price)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Totals</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2 max-w-xs ml-auto">
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Subtotal</span>
              <span>{formatINR(Number(quotation.subtotal))}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Tax</span>
              <span>{formatINR(Number(quotation.tax_amount))}</span>
            </div>
            <div className="border-t pt-2 flex justify-between font-semibold text-base">
              <span>Total</span>
              <span>{formatINR(Number(quotation.total_amount))}</span>
            </div>
          </div>
        </CardContent>
      </Card>

      <ConfirmDialog
        open={sendOpen}
        onOpenChange={setSendOpen}
        title="Send Quotation"
        description="Send this quotation to the customer?"
        onConfirm={handleSend}
        confirmLabel="Send"
        loading={sendMutation.isPending}
      />

      <ConfirmDialog
        open={acceptOpen}
        onOpenChange={setAcceptOpen}
        title="Accept Quotation"
        description="Accepting will create a booking from this quotation. Continue?"
        onConfirm={handleAccept}
        confirmLabel="Accept & Create Booking"
        loading={acceptMutation.isPending}
      />

      <ConfirmDialog
        open={rejectOpen}
        onOpenChange={setRejectOpen}
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
