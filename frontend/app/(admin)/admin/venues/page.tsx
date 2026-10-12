"use client";

import { useState, useCallback } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Building2, CheckCircle, Ban, XCircle, MoreHorizontal, Loader2 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { DataTable } from "@/components/common/DataTable";
import type { Column } from "@/components/common/DataTable";
import { PageHeader } from "@/components/common/PageHeader";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Separator } from "@/components/ui/separator";
import { useToast } from "@/components/ui/toast";
import apiClient from "@/lib/api-client";
import type { ApiResponse, DRFPaginatedResponse } from "@/types/api";

interface Venue {
  id: number;
  name: string;
  venue_type: string;
  capacity: number;
  status: string;
  tenant: {
    id: number;
    business_name: string;
  };
  created_at: string;
}

async function fetchVenues(params?: { page?: number; page_size?: number; search?: string; tenant?: number }): Promise<DRFPaginatedResponse<Venue>> {
  const { data } = await apiClient.get("/admin/venues/", { params });
  return data;
}

async function changeVenueStatus(venueId: number, status: string): Promise<ApiResponse<Venue>> {
  const { data } = await apiClient.post(`/admin/venues/${venueId}/${status}/`);
  return data;
}

export default function AdminVenuesPage() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [tenantFilter, setTenantFilter] = useState<number | "">("");

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ["admin-venues", page, debouncedSearch, tenantFilter],
    queryFn: () => fetchVenues({ page, page_size: 20, search: debouncedSearch || undefined, tenant: tenantFilter || undefined }),
  });

  const changeStatusMutation = useMutation({
    mutationFn: ({ venueId, status }: { venueId: number; status: string }) => changeVenueStatus(venueId, status),
    onSuccess: (_, variables) => {
      toast({ title: "Status changed", description: `Venue status updated to ${variables.status}`, variant: "success" });
      queryClient.invalidateQueries({ queryKey: ["admin-venues"] });
    },
    onError: (error: Error) => {
      toast({ title: "Error", description: error.message, variant: "destructive" });
    },
  });

  const statusBadge = (status: string) => {
    const variants: Record<string, "default" | "success" | "destructive" | "secondary" | "outline"> = {
      ACTIVE: "success",
      INACTIVE: "destructive",
      MAINTENANCE: "secondary",
    };
    const icons: Record<string, React.ElementType> = {
      ACTIVE: CheckCircle,
      INACTIVE: XCircle,
      MAINTENANCE: Ban,
    };
    const Icon = icons[status] || Building2;
    return (
      <Badge variant={variants[status] || "default"} className="gap-1">
        <Icon className="h-3 w-3" aria-hidden="true" />
        {status}
      </Badge>
    );
  };

  const columns: Column<Venue>[] = [
    {
      key: "name",
      header: "Venue",
      cell: (venue) => (
        <div>
          <p className="font-medium">{venue.name}</p>
          <p className="text-sm text-slate-500">{venue.venue_type} · Capacity: {venue.capacity}</p>
        </div>
      ),
    },
    {
      key: "tenant",
      header: "Venue Owner",
      cell: (venue) => (
        <span className="font-medium">{venue.tenant.business_name}</span>
      ),
    },
    {
      key: "status",
      header: "Status",
      cell: (venue) => statusBadge(venue.status),
    },
    {
      key: "created_at",
      header: "Created",
      cell: (venue) => new Date(venue.created_at).toLocaleDateString(),
    },
    {
      key: "actions",
      header: "Actions",
      cell: (venue) => (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="h-8 w-8">
              <MoreHorizontal className="h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="min-w-[180px]">
            <DropdownMenuItem
              onClick={() => changeStatusMutation.mutate({ venueId: venue.id, status: "activate" })}
              disabled={venue.status === "ACTIVE" || changeStatusMutation.isPending}
              className={venue.status === "ACTIVE" ? "opacity-50" : ""}
            >
              <CheckCircle className="h-4 w-4 mr-2 text-green-600" />
              Activate
            </DropdownMenuItem>
            <DropdownMenuItem
              onClick={() => changeStatusMutation.mutate({ venueId: venue.id, status: "suspend" })}
              disabled={venue.status === "MAINTENANCE" || changeStatusMutation.isPending}
              className={venue.status === "MAINTENANCE" ? "opacity-50" : ""}
            >
              <Ban className="h-4 w-4 mr-2 text-amber-600" />
              Suspend (Maintenance)
            </DropdownMenuItem>
            <DropdownMenuItem
              onClick={() => changeStatusMutation.mutate({ venueId: venue.id, status: "disable" })}
              disabled={venue.status === "INACTIVE" || changeStatusMutation.isPending}
              className={venue.status === "INACTIVE" ? "opacity-50" : ""}
            >
              <XCircle className="h-4 w-4 mr-2 text-red-600" />
              Disable
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      ),
    },
  ];

  const venues = data?.results ?? [];
  const totalCount = data?.count ?? 0;
  const hasNext = !!data?.next;
  const hasPrev = !!data?.previous;
  const totalPages = Math.ceil(totalCount / 20);

  return (
    <div className="space-y-6">
      <PageHeader
        title="All Venues"
        description="Manage all venues across the platform"
      />

      <div className="flex flex-col sm:flex-row gap-4 mb-4">
        <Input
          placeholder="Search venues..."
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
            setTimeout(() => setDebouncedSearch(e.target.value), 300);
          }}
          className="flex-1"
        />
        <select
          value={tenantFilter}
          onChange={(e) => { setTenantFilter(e.target.value ? parseInt(e.target.value) : ""); setPage(1); }}
          className="px-4 py-2 rounded-xl border border-slate-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-amber-500/50 w-full sm:w-64"
        >
          <option value="">All Venue Owners</option>
        </select>
      </div>

      <DataTable
        columns={columns}
        data={venues}
        loading={isLoading}
        error={error ? (error as Error).message : null}
        onRetry={refetch}
        emptyMessage="No venues found"
      />

      {totalPages > 1 && !isLoading && (
        <div className="flex items-center justify-between gap-4">
          <p className="text-sm text-slate-700">
            Page {page} of {totalPages} · {totalCount} total
          </p>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={page <= 1 || !hasPrev}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
            >
              Previous
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={page >= totalPages || !hasNext}
              onClick={() => setPage((p) => p + 1)}
            >
              Next
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
