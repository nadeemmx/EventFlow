"use client";

import { useState, useCallback } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Building2, Building, Ban, MoreHorizontal, CheckCircle, XCircle, AlertCircle } from "lucide-react";
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

interface Tenant {
  id: number;
  business_name: string;
  owner_name: string;
  email: string;
  mobile: string;
  subscription_plan: number | null;
  subscription_status: string;
  status: string;
  created_at: string;
}

async function fetchTenants(params?: { page?: number; page_size?: number; search?: string }): Promise<DRFPaginatedResponse<Tenant>> {
  const { data } = await apiClient.get("/tenants/", { params });
  return data;
}

async function changeTenantStatus(tenantId: number, status: string): Promise<ApiResponse<Tenant>> {
  const { data } = await apiClient.post(`/tenants/${tenantId}/${status}/`);
  return data;
}

export default function AdminTenantsPage() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ["admin-tenants", page, debouncedSearch],
    queryFn: () => fetchTenants({ page, page_size: 20, search: debouncedSearch || undefined }),
  });

  const changeStatusMutation = useMutation({
    mutationFn: ({ tenantId, status }: { tenantId: number; status: string }) => changeTenantStatus(tenantId, status),
    onSuccess: (_, variables) => {
      toast({ title: "Status changed", description: `Tenant status updated to ${variables.status}`, variant: "success" });
      queryClient.invalidateQueries({ queryKey: ["admin-tenants"] });
    },
    onError: (error: Error) => {
      toast({ title: "Error", description: error.message, variant: "destructive" });
    },
  });

  const statusBadge = (status: string) => {
    const variants: Record<string, "default" | "success" | "destructive" | "secondary" | "outline"> = {
      ACTIVE: "success",
      INACTIVE: "destructive",
      SUSPENDED: "destructive",
      TRIAL: "secondary",
      EXPIRED: "outline",
    };
    const icons: Record<string, React.ElementType> = {
      ACTIVE: CheckCircle,
      INACTIVE: XCircle,
      SUSPENDED: Ban,
      TRIAL: AlertCircle,
      EXPIRED: XCircle,
    };
    const Icon = icons[status] || Building;
    return (
      <Badge variant={variants[status] || "default"} className="gap-1">
        <Icon className="h-3 w-3" aria-hidden="true" />
        {status}
      </Badge>
    );
  };

  const columns: Column<Tenant>[] = [
    {
      key: "business_name",
      header: "Venue Owner",
      cell: (tenant) => (
        <div>
          <p className="font-medium">{tenant.business_name}</p>
          <p className="text-sm text-slate-500">{tenant.owner_name} · {tenant.email}</p>
        </div>
      ),
    },
    {
      key: "subscription_plan",
      header: "Plan",
      cell: (tenant) => tenant.subscription_plan ? `Plan #${tenant.subscription_plan}` : "—",
    },
    {
      key: "subscription_status",
      header: "Subscription",
      cell: (tenant) => <Badge variant="secondary">{tenant.subscription_status}</Badge>,
    },
    {
      key: "status",
      header: "Status",
      cell: (tenant) => statusBadge(tenant.status),
    },
    {
      key: "created_at",
      header: "Joined",
      cell: (tenant) => new Date(tenant.created_at).toLocaleDateString(),
    },
    {
      key: "actions",
      header: "Actions",
      cell: (tenant) => (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="h-8 w-8">
              <MoreHorizontal className="h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="min-w-[180px]">
            <DropdownMenuItem
              onClick={() => changeStatusMutation.mutate({ tenantId: tenant.id, status: "activate" })}
              disabled={tenant.status === "ACTIVE" || changeStatusMutation.isPending}
              className={tenant.status === "ACTIVE" ? "opacity-50" : ""}
            >
              <CheckCircle className="h-4 w-4 mr-2 text-green-600" />
              Activate
            </DropdownMenuItem>
            <DropdownMenuItem
              onClick={() => changeStatusMutation.mutate({ tenantId: tenant.id, status: "suspend" })}
              disabled={tenant.status === "SUSPENDED" || changeStatusMutation.isPending}
              className={tenant.status === "SUSPENDED" ? "opacity-50" : ""}
            >
              <Ban className="h-4 w-4 mr-2 text-amber-600" />
              Suspend
            </DropdownMenuItem>
            <DropdownMenuItem
              onClick={() => changeStatusMutation.mutate({ tenantId: tenant.id, status: "disable" })}
              disabled={tenant.status === "INACTIVE" || changeStatusMutation.isPending}
              className={tenant.status === "INACTIVE" ? "opacity-50" : ""}
            >
              <XCircle className="h-4 w-4 mr-2 text-red-600" />
              Disable
            </DropdownMenuItem>
            <Separator />
            <DropdownMenuItem className="text-red-600 focus:text-red-600" disabled>
              View Details
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      ),
    },
  ];

  const tenants = data?.results ?? [];
  const totalCount = data?.count ?? 0;
  const hasNext = !!data?.next;
  const hasPrev = !!data?.previous;
  const totalPages = Math.ceil(totalCount / 20);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Venue Owners"
        description="Manage all venue owners on the platform"
      />

      <DataTable
        columns={columns}
        data={tenants}
        loading={isLoading}
        error={error ? (error as Error).message : null}
        onRetry={refetch}
        emptyMessage="No venue owners found"
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
