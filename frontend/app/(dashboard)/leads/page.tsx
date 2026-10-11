"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import {
  Plus,
  Search,
  Eye,
  Trash2,
  ArrowRight,
} from "lucide-react"

import { useLeads, useDeleteLead, useConvertLead } from "@/hooks/use-leads"
import { LEAD_STATUSES } from "@/lib/constants"
import { formatDate } from "@/lib/utils"
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

const LEAD_SOURCE_OPTIONS = [
  "WEBSITE",
  "GOOGLE",
  "FACEBOOK",
  "INSTAGRAM",
  "WHATSAPP",
  "WALK_IN",
  "REFERRAL",
] as const

export default function LeadsPage() {
  const router = useRouter()
  const { toast } = useToast()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState("")
  const [debouncedSearch, setDebouncedSearch] = useState("")
  const [pageSize, setPageSize] = useState("10")
  const [statusFilter, setStatusFilter] = useState("")
  const [sourceFilter, setSourceFilter] = useState("")
  const [deleteId, setDeleteId] = useState<number | null>(null)
  const [convertId, setConvertId] = useState<number | null>(null)

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearch(search), 300)
    return () => clearTimeout(timer)
  }, [search])

  const { data, isLoading, error, refetch } = useLeads({
    page,
    page_size: parseInt(pageSize),
    search: debouncedSearch || undefined,
    lead_status: statusFilter || undefined,
    lead_source: sourceFilter || undefined,
  })

  const deleteMutation = useDeleteLead()
  const convertMutation = useConvertLead()

  const handleDelete = async () => {
    if (!deleteId) return
    try {
      await deleteMutation.mutateAsync(deleteId)
      toast({ title: "Lead deleted", variant: "success" })
      setDeleteId(null)
    } catch {
      toast({ title: "Failed to delete lead", variant: "destructive" })
    }
  }

  const handleConvert = async () => {
    if (!convertId) return
    try {
      await convertMutation.mutateAsync(convertId)
      toast({ title: "Lead converted", description: "Lead has been converted to a booking.", variant: "success" })
      setConvertId(null)
    } catch {
      toast({ title: "Failed to convert lead", variant: "destructive" })
    }
  }

  const canConvert = (status: string) =>
    !["CONVERTED", "LOST"].includes(status)

  const columns: Column<Record<string, unknown>>[] = [
    {
      key: "customer_name",
      header: "Customer",
      cell: (item) => (
        <Link
          href={`/leads/${item.id as number}`}
          className="font-medium text-primary hover:underline"
        >
          {(item.customer_name as string) || `Customer #${item.customer as number}`}
        </Link>
      ),
    },
    {
      key: "event_type",
      header: "Event Type",
      cell: (item) => (
        <span>{(item.event_type as string)?.replace(/_/g, " ") || "—"}</span>
      ),
    },
    {
      key: "lead_source",
      header: "Source",
      cell: (item) => (
        <span className="capitalize">
          {(item.lead_source as string)?.replace(/_/g, " ").toLowerCase() || "—"}
        </span>
      ),
    },
    {
      key: "lead_status",
      header: "Status",
      cell: (item) => <StatusBadge status={item.lead_status as string} type="lead" />,
    },
    {
      key: "assigned_to",
      header: "Assigned To",
      cell: (item) => (
        <span className="text-muted-foreground">
          {(item.assigned_to_name as string) || "Unassigned"}
        </span>
      ),
    },
    {
      key: "created_at",
      header: "Created",
      cell: (item) => formatDate(item.created_at as string),
    },
    {
      key: "actions",
      header: "Actions",
      cell: (item) => (
        <div className="flex items-center gap-1">
          <Button
            variant="ghost"
            size="icon"
            aria-label="View lead"
            className="h-8 w-8 cursor-pointer"
            onClick={(e) => {
              e.stopPropagation()
              router.push(`/leads/${item.id as number}`)
            }}
          >
            <Eye aria-hidden="true" focusable="false" className="h-4 w-4" />
          </Button>
          {canConvert(item.lead_status as string) && (
            <Button
              variant="ghost"
              size="icon"
              aria-label="Convert lead to booking"
              className="h-8 w-8 text-success hover:text-success cursor-pointer"
              onClick={(e) => {
                e.stopPropagation()
                setConvertId(item.id as number)
              }}
              title="Convert to Booking"
            >
              <ArrowRight aria-hidden="true" focusable="false" className="h-4 w-4" />
            </Button>
          )}
          <Button
            variant="ghost"
            size="icon"
            aria-label="Delete lead"
            className="h-8 w-8 text-destructive hover:text-destructive cursor-pointer"
            onClick={(e) => {
              e.stopPropagation()
              setDeleteId(item.id as number)
            }}
          >
            <Trash2 aria-hidden="true" focusable="false" className="h-4 w-4" />
          </Button>
        </div>
      ),
    },
  ]

  const leads = (data?.data || []) as unknown as Record<string, unknown>[]
  const pagination = data?.pagination

  return (
    <div className="space-y-6">
      <PageHeader title="Leads" description="Track and manage your sales leads">
        <Button asChild className="cursor-pointer">
          <Link href="/leads/new">
            <Plus className="h-4 w-4 mr-2" />
            Add Lead
          </Link>
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search leads..."
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
            {LEAD_STATUSES.map((s) => (
              <SelectItem key={s} value={s}>
                {s.replace(/_/g, " ")}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select
          value={sourceFilter}
          onValueChange={(v) => {
            setSourceFilter(v === "all" ? "" : v)
            setPage(1)
          }}
        >
          <SelectTrigger className="w-full sm:w-40 cursor-pointer">
            <SelectValue placeholder="All Sources" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Sources</SelectItem>
            {LEAD_SOURCE_OPTIONS.map((s) => (
              <SelectItem key={s} value={s}>
                {s.replace(/_/g, " ")}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <DataTable
        columns={columns}
        data={leads}
        loading={isLoading}
        error={error ? (error as Error).message : null}
        onRetry={() => refetch()}
        emptyMessage="No leads found. Click 'Add Lead' to create one."
        emptyAction={{ label: "Add Lead", onClick: () => router.push("/leads/new") }}
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
        open={deleteId !== null}
        onOpenChange={(open) => !open && setDeleteId(null)}
        title="Delete Lead"
        description="Are you sure you want to delete this lead? This action cannot be undone."
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteMutation.isPending}
      />

      <ConfirmDialog
        open={convertId !== null}
        onOpenChange={(open) => !open && setConvertId(null)}
        title="Convert Lead"
        description="Are you sure you want to convert this lead to a booking?"
        onConfirm={handleConvert}
        confirmLabel="Convert to Booking"
        loading={convertMutation.isPending}
      />
    </div>
  )
}
