"use client"

import { useState, type ReactNode } from "react"
import { ChevronUp, ChevronDown, ChevronsUpDown, Inbox } from "lucide-react"

import { cn } from "@/lib/utils"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Skeleton } from "@/components/ui/skeleton"
import { EmptyState } from "@/components/common/EmptyState"
import { ErrorState } from "@/components/common/ErrorState"

export interface Column<T = any> {
  key: string
  header: string
  cell?: (item: T) => ReactNode
  sortable?: boolean
}

interface DataTableProps<T = any> {
  columns: Column<T>[]
  data: T[]
  loading?: boolean
  emptyMessage?: string
  emptyAction?: {
    label: string
    onClick: () => void
  }
  onRowClick?: (item: T) => void
  error?: string | null
  onRetry?: () => void
}

export function DataTable<T = any>({
  columns,
  data,
  loading = false,
  emptyMessage = "No data found",
  emptyAction,
  onRowClick,
  error,
  onRetry,
}: DataTableProps<T>) {
  const [sortKey, setSortKey] = useState<string | null>(null)
  const [sortDirection, setSortDirection] = useState<"asc" | "desc">("asc")
  const [sortAnnouncement, setSortAnnouncement] = useState("")

  const handleSort = (key: string) => {
    const header = columns.find((col) => col.key === key)?.header ?? key
    let next: "asc" | "desc"
    if (sortKey === key) {
      next = sortDirection === "asc" ? "desc" : "asc"
      setSortDirection(next)
    } else {
      setSortKey(key)
      setSortDirection("asc")
      next = "asc"
    }
    setSortAnnouncement(
      `Sorted by ${header}, ${next === "asc" ? "ascending" : "descending"}`,
    )
  }

  const sortedData = [...data].sort((a, b) => {
    if (!sortKey) return 0

    const aVal = (a as Record<string, unknown>)[sortKey]
    const bVal = (b as Record<string, unknown>)[sortKey]

    if (aVal == null) return 1
    if (bVal == null) return -1

    const comparison =
      typeof aVal === "number" && typeof bVal === "number"
        ? (aVal as number) - (bVal as number)
        : String(aVal).localeCompare(String(bVal))

    return sortDirection === "asc" ? comparison : -comparison
  })

  if (error) {
    return <ErrorState message={error} onRetry={onRetry} />
  }

  if (loading) {
    return (
      <div className="rounded-md border border-amber-500/20">
        <Table>
          <TableHeader>
            <TableRow>
              {columns.map((col) => (
                <TableHead key={col.key}>{col.header}</TableHead>
              ))}
            </TableRow>
          </TableHeader>
          <TableBody>
            {Array.from({ length: 5 }).map((_, i) => (
              <TableRow key={i}>
                {columns.map((col) => (
                  <TableCell key={col.key}>
                    <Skeleton className="h-4 w-full max-w-[120px]" />
                  </TableCell>
                ))}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    )
  }

  if (data.length === 0) {
    return (
      <EmptyState
        icon={Inbox}
        title="No data"
        description={emptyMessage}
        action={emptyAction}
      />
    )
  }

  return (
    <div className="rounded-md border border-amber-500/20 overflow-x-auto">
      <div aria-live="polite" className="sr-only">
        {sortAnnouncement}
      </div>
      <Table>
        <TableHeader>
          <TableRow>
            {columns.map((col) => (
              <TableHead
                key={col.key}
                aria-sort={
                  col.sortable
                    ? sortKey === col.key
                      ? sortDirection === "asc"
                        ? "ascending"
                        : "descending"
                      : "none"
                    : undefined
                }
              >
                {col.sortable ? (
                  <button
                    type="button"
                    className="flex w-full items-center gap-1 text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                    onClick={() => handleSort(col.key)}
                  >
                    {col.header}
                    <span className="text-slate-600">
                      {sortKey === col.key ? (
                        sortDirection === "asc" ? (
                          <ChevronUp aria-hidden="true" focusable="false" className="h-3.5 w-3.5" />
                        ) : (
                          <ChevronDown aria-hidden="true" focusable="false" className="h-3.5 w-3.5" />
                        )
                      ) : (
                        <ChevronsUpDown aria-hidden="true" focusable="false" className="h-3.5 w-3.5" />
                      )}
                    </span>
                  </button>
                ) : (
                  <div className="flex items-center gap-1">{col.header}</div>
                )}
              </TableHead>
            ))}
          </TableRow>
        </TableHeader>
        <TableBody>
          {sortedData.map((item, index) => (
            <TableRow
              key={String((item as Record<string, unknown>).id ?? index)}
              className={cn(onRowClick && "cursor-pointer")}
              role={onRowClick ? "link" : undefined}
              tabIndex={onRowClick ? 0 : undefined}
              onClick={() => onRowClick?.(item)}
              onKeyDown={(e) => {
                if (!onRowClick || e.target !== e.currentTarget) return
                if (e.key === "Enter" || e.key === " ") {
                  e.preventDefault()
                  onRowClick(item)
                }
              }}
            >
              {columns.map((col) => (
                <TableCell key={col.key}>
                  {col.cell
                    ? col.cell(item)
                    : String((item as Record<string, unknown>)[col.key] ?? "")}
                </TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}
