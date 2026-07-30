"use client"

import { useState, useCallback } from "react"
import { useRouter } from "next/navigation"
import { ArrowLeft, Clock } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Card, CardContent } from "@/components/ui/card"
import { PageHeader } from "@/components/common/PageHeader"
import { EmptyState } from "@/components/common/EmptyState"
import { ErrorState } from "@/components/common/ErrorState"
import { DataTable } from "@/components/common/DataTable"
import { useAuditLogs } from "@/hooks/use-audit-logs"
import { formatDateTime } from "@/lib/utils"
import type { AuditLog } from "@/types/api"

const MODULES = ["", "Bookings", "Payments", "Leads", "Venues", "Customers", "Inventory", "Vendors", "Reports", "Users", "Settings", "Contracts", "Quotations"]
const ACTIONS = ["", "CREATE", "UPDATE", "DELETE"]

export default function AuditLogsPage() {
  const router = useRouter()
  const [page, setPage] = useState(1)
  const [module, setModule] = useState("all")
  const [action, setAction] = useState("all")
  const pageSize = 20

  const { data, isLoading, isError, error, refetch } = useAuditLogs({
    page,
    page_size: pageSize,
    module: module !== "all" ? module : undefined,
    action: action !== "all" ? action : undefined,
  })

  const handleModuleChange = useCallback((value: string) => {
    setModule(value || "all")
    setPage(1)
  }, [])

  const handleActionChange = useCallback((value: string) => {
    setAction(value || "all")
    setPage(1)
  }, [])

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader title="Audit Logs">
          <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/dashboard")}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Button>
        </PageHeader>
        <ErrorState message={(error as Error)?.message} onRetry={() => refetch()} />
      </div>
    )
  }

  const logs = data?.data ?? []
  const pagination = data?.pagination

  const columns = [
    { key: "id", header: "ID", sortable: true },
    {
      key: "user",
      header: "User",
      sortable: true,
      cell: (item: AuditLog) => `User #${item.user}`,
    },
    { key: "module", header: "Module", sortable: true },
    { key: "action", header: "Action", sortable: true },
    {
      key: "record_id",
      header: "Record ID",
      cell: (item: AuditLog) => item.record_id ?? "—",
    },
    {
      key: "created_at",
      header: "Created",
      sortable: true,
      cell: (item: AuditLog) => formatDateTime(item.created_at),
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Audit Logs" description="Track all changes made across the system">
        <Button variant="outline" className="cursor-pointer" onClick={() => router.push("/dashboard")}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-3 items-start sm:items-end">
        <div className="space-y-1">
          <label className="text-xs text-muted-foreground">Module</label>
          <Select value={module} onValueChange={handleModuleChange}>
            <SelectTrigger className="w-44 cursor-pointer">
              <SelectValue placeholder="All Modules" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Modules</SelectItem>
              {MODULES.filter(Boolean).map((m) => (
                <SelectItem key={m} value={m}>{m}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-1">
          <label className="text-xs text-muted-foreground">Action</label>
          <Select value={action} onValueChange={handleActionChange}>
            <SelectTrigger className="w-44 cursor-pointer">
              <SelectValue placeholder="All Actions" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Actions</SelectItem>
              {ACTIONS.filter(Boolean).map((a) => (
                <SelectItem key={a} value={a}>{a}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>

      {logs.length === 0 && !isLoading ? (
        <Card>
          <CardContent>
            <EmptyState
              icon={Clock}
              title="No audit logs found"
              description={module !== "all" || action !== "all" ? "Try clearing your filters" : "No activity has been recorded yet"}
            />
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent className="p-0">
            <DataTable
              columns={columns}
              data={logs}
              loading={isLoading}
              emptyMessage="No audit logs found"
              error={null}
            />
          </CardContent>
        </Card>
      )}

      {pagination && pagination.total_pages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-muted-foreground">
            Page {pagination.page} of {pagination.total_pages} ({pagination.total_records} records)
          </p>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              className="cursor-pointer"
              disabled={page <= 1}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
            >
              Previous
            </Button>
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
        </div>
      )}
    </div>
  )
}
