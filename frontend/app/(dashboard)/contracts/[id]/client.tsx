"use client"

import { useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { ArrowLeft, Download, XCircle, Edit, CalendarDays, FileText, User } from "lucide-react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { useContract, useSignContract, useCancelContract } from "@/hooks/use-contracts"
import { contractsService } from "@/services/contracts.service"
import { PageHeader } from "@/components/common/PageHeader"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog"
import { toast } from "@/components/ui/toast"
import { formatDate } from "@/lib/utils"
import type { Contract } from "@/types/api"

const signSchema = z.object({
  signed_by_name: z.string().min(1, "Name is required"),
  signed_by_designation: z.string().min(1, "Designation is required"),
})

type SignFormValues = z.infer<typeof signSchema>

export default function ContractDetailClient() {
  const params = useParams()
  const router = useRouter()
  const id = Number(params.id)
  const [showSignDialog, setShowSignDialog] = useState(false)
  const [showCancelDialog, setShowCancelDialog] = useState(false)

  const { data: contractRes, isLoading, error, refetch } = useContract(id)
  const signContract = useSignContract()
  const cancelContract = useCancelContract()

  const contract = contractRes?.data as Contract | undefined

  const signForm = useForm<SignFormValues>({
    resolver: zodResolver(signSchema),
    defaultValues: {
      signed_by_name: "",
      signed_by_designation: "",
    },
  })

  const handleSign = async (values: SignFormValues) => {
    try {
      await signContract.mutateAsync({ id, data: values })
      toast({ title: "Contract signed", variant: "success" })
      setShowSignDialog(false)
      refetch()
    } catch {
      toast({ title: "Failed to sign contract", variant: "destructive" })
    }
  }

  const handleCancel = async () => {
    try {
      await cancelContract.mutateAsync(id)
      toast({ title: "Contract cancelled", variant: "warning" })
      setShowCancelDialog(false)
    } catch {
      toast({ title: "Failed to cancel contract", variant: "destructive" })
    }
  }

  const handleDownloadPdf = async () => {
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

  if (isLoading) return <LoadingState type="page" />
  if (error) return <ErrorState message={(error as Error).message} onRetry={() => refetch()} />
  if (!contract) return <ErrorState message="Contract not found" />

  const canCancel = !["SIGNED", "CANCELLED", "EXPIRED"].includes(contract.status)
  const canSign = contract.status === "DRAFT" || contract.status === "SENT"

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
        <button onClick={() => router.push("/contracts")} className="hover:text-foreground cursor-pointer">
          Contracts
        </button>
        <span>/</span>
        <span className="text-foreground font-mono font-medium">{contract.contract_number}</span>
      </div>

      <PageHeader title={contract.contract_number}>
        <StatusBadge status={contract.status} type="contract" />
        <Button variant="outline" className="cursor-pointer" onClick={() => router.back()}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back
        </Button>
        {canSign && (
          <Button
            variant="default"
            className="cursor-pointer"
            onClick={() => setShowSignDialog(true)}
          >
            <Edit className="mr-2 h-4 w-4" />
            Sign
          </Button>
        )}
        <Button variant="outline" className="cursor-pointer" onClick={handleDownloadPdf}>
          <Download className="mr-2 h-4 w-4" />
          Download PDF
        </Button>
        {canCancel && (
          <Button
            variant="outline"
            className="cursor-pointer text-destructive border-destructive hover:bg-destructive/10"
            onClick={() => setShowCancelDialog(true)}
          >
            <XCircle className="mr-2 h-4 w-4" />
            Cancel
          </Button>
        )}
      </PageHeader>

      <div className="grid gap-6 md:grid-cols-2">
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center gap-2">
                <FileText className="h-5 w-5 text-primary" />
                Contract Info
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-muted-foreground">Booking #</p>
                  <p className="font-medium">{contract.booking_number || `#${contract.booking}`}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Customer</p>
                  <p className="font-medium">{contract.customer_name || "-"}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Venue</p>
                  <p className="font-medium">{contract.venue_name || "-"}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Status</p>
                  <StatusBadge status={contract.status} type="contract" />
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center gap-2">
                <CalendarDays className="h-5 w-5 text-primary" />
                Validity
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-muted-foreground">Valid From</p>
                  <p className="font-medium">{formatDate(contract.valid_from)}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Valid Until</p>
                  <p className="font-medium">{formatDate(contract.valid_until)}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {contract.notes && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <FileText className="h-5 w-5 text-primary" />
                  Notes
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm whitespace-pre-wrap">{contract.notes}</p>
              </CardContent>
            </Card>
          )}
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center gap-2">
                <FileText className="h-5 w-5 text-primary" />
                Content
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm whitespace-pre-wrap">{contract.content}</p>
            </CardContent>
          </Card>

          {(contract.signed_by_name || contract.signed_date) && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <User className="h-5 w-5 text-primary" />
                  Signing Details
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground">Signed By</p>
                    <p className="font-medium">{contract.signed_by_name || "-"}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Designation</p>
                    <p className="font-medium">{contract.signed_by_designation || "-"}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Signed Date</p>
                    <p className="font-medium">{contract.signed_date ? formatDate(contract.signed_date) : "-"}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      <Dialog open={showSignDialog} onOpenChange={setShowSignDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Sign Contract</DialogTitle>
            <DialogDescription>
              Enter the signatory details to sign {contract.contract_number}.
            </DialogDescription>
          </DialogHeader>
          <Form {...signForm}>
            <form onSubmit={signForm.handleSubmit(handleSign)} className="space-y-4">
              <FormField
                control={signForm.control}
                name="signed_by_name"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Full Name *</FormLabel>
                    <FormControl>
                      <Input placeholder="Enter full name" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={signForm.control}
                name="signed_by_designation"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Designation *</FormLabel>
                    <FormControl>
                      <Input placeholder="e.g. Manager, Director" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <DialogFooter>
                <Button
                  type="button"
                  variant="outline"
                  className="cursor-pointer"
                  onClick={() => setShowSignDialog(false)}
                  disabled={signContract.isPending}
                >
                  Cancel
                </Button>
                <Button type="submit" className="cursor-pointer" disabled={signContract.isPending}>
                  {signContract.isPending ? "Signing..." : "Sign Contract"}
                </Button>
              </DialogFooter>
            </form>
          </Form>
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={showCancelDialog}
        onOpenChange={setShowCancelDialog}
        title="Cancel Contract"
        description={`Are you sure you want to cancel ${contract.contract_number}? This action cannot be undone.`}
        onConfirm={handleCancel}
        confirmLabel="Cancel Contract"
        variant="destructive"
        loading={cancelContract.isPending}
      />
    </div>
  )
}
