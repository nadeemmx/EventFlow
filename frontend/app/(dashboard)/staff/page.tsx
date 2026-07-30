"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Plus, Search, Users, Eye, Edit, Trash2 } from "lucide-react"
import { useStaff, useDeleteStaffMember } from "@/hooks/use-staff"
import { PageHeader } from "@/components/common/PageHeader"
import { DataTable } from "@/components/common/DataTable"
import { StatusBadge } from "@/components/common/StatusBadge"
import { ConfirmDialog } from "@/components/common/ConfirmDialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { toast } from "@/components/ui/toast"
import { cn } from "@/lib/utils"
import { STAFF_ROLES } from "@/lib/constants"
import type { StaffMember } from "@/types/api"

const statusFilters = ["All", "ACTIVE", "INACTIVE"] as const

export default function StaffPage() {
  const router = useRouter()
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState("All")
  const [roleFilter, setRoleFilter] = useState("All")
  const [page, setPage] = useState(1)
  const [deleteId, setDeleteId] = useState<number | null>(null)

  const status = statusFilter === "All" ? undefined : statusFilter
  const role = roleFilter === "All" ? undefined : roleFilter

  const { data, isLoading, error, refetch } = useStaff({
    page,
    page_size: 10,
    search: search || undefined,
    status,
    role,
  })

  const deleteMember = useDeleteStaffMember()

  const staff = data?.data ?? []
  const pagination = data?.pagination

  const handleDelete = async () => {
    if (!deleteId) return
    try {
      await deleteMember.mutateAsync(deleteId)
      toast({ title: "Staff member deleted", variant: "success" })
      setDeleteId(null)
    } catch {
      toast({ title: "Failed to delete staff member", variant: "destructive" })
    }
  }

  const columns: import("@/components/common/DataTable").Column<Record<string, unknown>>[] = [
    {
      key: "full_name",
      header: "Name",
      cell: (item) => {
        const member = item as unknown as StaffMember
        return (
          <div className="flex items-center gap-2">
            <Users className="h-4 w-4 text-slate-700 shrink-0" />
            <span className="font-medium">{member.full_name}</span>
          </div>
        )
      },
    },
    {
      key: "email",
      header: "Email",
      cell: (item) => {
        const member = item as unknown as StaffMember
        return <span className="text-sm text-slate-700">{member.email}</span>
      },
    },
    {
      key: "mobile",
      header: "Mobile",
      cell: (item) => {
        const member = item as unknown as StaffMember
        return <span className="font-mono text-sm">{member.mobile}</span>
      },
    },
    {
      key: "role",
      header: "Role",
      cell: (item) => {
        const member = item as unknown as StaffMember
        return <span className="text-sm">{member.role.replace(/_/g, " ")}</span>
      },
    },
    {
      key: "status",
      header: "Status",
      cell: (item) => {
        const member = item as unknown as StaffMember
        return <StatusBadge status={member.status} type="generic" />
      },
    },
    {
      key: "actions",
      header: "Actions",
      cell: (item) => {
        const member = item as unknown as StaffMember
        return (
          <div className="flex items-center gap-1">
            <Button variant="ghost" size="icon" className="cursor-pointer" onClick={(e) => { e.stopPropagation(); router.push(`/staff/${member.id}`) }}>
              <Eye className="h-4 w-4" />
            </Button>
            <Button variant="ghost" size="icon" className="cursor-pointer" onClick={(e) => { e.stopPropagation(); router.push(`/staff/${member.id}`) }}>
              <Edit className="h-4 w-4" />
            </Button>
            <Button variant="ghost" size="icon" className="cursor-pointer text-destructive hover:text-destructive" onClick={(e) => { e.stopPropagation(); setDeleteId(member.id) }}>
              <Trash2 className="h-4 w-4" />
            </Button>
          </div>
        )
      },
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Staff" description="Manage your event staff members">
        <Button className="cursor-pointer" onClick={() => router.push("/staff/new")}>
          <Plus className="mr-2 h-4 w-4" />
          Add Staff
        </Button>
      </PageHeader>

      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-700" />
          <Input
            placeholder="Search staff..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            className="pl-9"
          />
        </div>
        <Select value={roleFilter} onValueChange={(v) => { setRoleFilter(v); setPage(1) }}>
          <SelectTrigger className="w-full sm:w-[180px] cursor-pointer">
            <SelectValue placeholder="All Roles" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="All">All Roles</SelectItem>
            {STAFF_ROLES.map((r) => (
              <SelectItem key={r} value={r}>{r.replace(/_/g, " ")}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="flex gap-2 flex-wrap">
        {statusFilters.map((s) => (
          <button
            key={s}
            onClick={() => { setStatusFilter(s); setPage(1) }}
            className={cn(
              "px-3 py-1.5 text-sm rounded-full border transition-colors cursor-pointer",
              statusFilter === s
                ? "bg-amber-600 text-white border-amber-600"
                : "bg-white text-slate-700 border-input hover:bg-slate-100"
            )}
          >
            {s === "All" ? "All" : s.replace(/_/g, " ")}
          </button>
        ))}
      </div>

      <DataTable
        columns={columns}
        data={staff as unknown as Record<string, unknown>[]}
        loading={isLoading}
        error={error ? (error as Error).message : null}
        onRetry={() => refetch()}
        emptyMessage="No staff members found. Add your first staff member to get started."
        emptyAction={{ label: "Add Staff", onClick: () => router.push("/staff/new") }}
        onRowClick={(item) => router.push(`/staff/${(item as unknown as StaffMember).id}`)}
      />

      {pagination && pagination.total_pages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-slate-700">
            Page {pagination.page} of {pagination.total_pages} ({pagination.total_records} total)
          </p>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => setPage((p) => Math.max(1, p - 1))} className="cursor-pointer">Previous</Button>
            <Button variant="outline" size="sm" disabled={page >= pagination.total_pages} onClick={() => setPage((p) => p + 1)} className="cursor-pointer">Next</Button>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={!!deleteId}
        onOpenChange={(open) => !open && setDeleteId(null)}
        title="Delete Staff Member"
        description="Are you sure you want to delete this staff member? This action cannot be undone."
        onConfirm={handleDelete}
        confirmLabel="Delete"
        variant="destructive"
        loading={deleteMember.isPending}
      />
    </div>
  )
}
