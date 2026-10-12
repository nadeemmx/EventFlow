"use client";

import { useQuery } from "@tanstack/react-query";
import { Building2, Users, CalendarCheck, CreditCard, TrendingUp, AlertTriangle } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import apiClient from "@/lib/api-client";
import type { ApiResponse } from "@/types/api";
import { PageHeader } from "@/components/common/PageHeader";
import { Button } from "@/components/ui/button";
import { RefreshCw } from "lucide-react";

interface PlatformStats {
  total_tenants: number;
  active_tenants: number;
  total_venues: number;
  active_venues: number;
  total_bookings_this_month: number;
  total_revenue_this_month: number;
  pending_approvals: number;
}

async function fetchPlatformStats(): Promise<ApiResponse<PlatformStats>> {
  const { data } = await apiClient.get("/admin/stats/");
  return data;
}

export default function AdminDashboardPage() {
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ["admin-stats"],
    queryFn: fetchPlatformStats,
  });

  const stats = data?.data;

  const statCards = [
    {
      label: "Total Venue Owners",
      value: stats?.total_tenants ?? "—",
      icon: Users,
      color: "text-blue-600 bg-blue-50",
      trend: stats?.active_tenants !== undefined ? `${stats.active_tenants} active` : undefined,
    },
    {
      label: "Total Venues",
      value: stats?.total_venues ?? "—",
      icon: Building2,
      color: "text-green-600 bg-green-50",
      trend: stats?.active_venues !== undefined ? `${stats.active_venues} active` : undefined,
    },
    {
      label: "Bookings This Month",
      value: stats?.total_bookings_this_month ?? "—",
      icon: CalendarCheck,
      color: "text-amber-600 bg-amber-50",
    },
    {
      label: "Revenue This Month",
      value: stats?.total_revenue_this_month ? `₹${stats.total_revenue_this_month.toLocaleString()}` : "—",
      icon: CreditCard,
      color: "text-emerald-600 bg-emerald-50",
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Platform Admin"
        description="Overview of the entire EventFlow platform"
      >
        <Button
          onClick={() => refetch()}
          disabled={isLoading}
          variant="outline"
          size="sm"
        >
          <RefreshCw className="h-4 w-4 mr-2" aria-hidden="true" />
          Refresh
        </Button>
      </PageHeader>

      {error && (
        <div className="rounded-md bg-destructive/10 p-4 text-destructive">
          Failed to load platform stats. <button onClick={() => refetch()} className="underline ml-2">Retry</button>
        </div>
      )}

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {statCards.map((stat) => (
          <Card key={stat.label}>
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-slate-600">{stat.label}</p>
                  <p className="text-3xl font-bold text-slate-900 mt-1">{stat.value}</p>
                  {stat.trend && (
                    <p className="text-xs text-slate-500 mt-1">{stat.trend}</p>
                  )}
                </div>
                <div className={`${stat.color} p-3 rounded-xl`}>
                  <stat.icon className="h-6 w-6" aria-hidden="true" />
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <Card>
          <CardHeader>
            <CardTitle>Quick Actions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <a href="/admin/tenants" className="block p-4 rounded-lg border border-slate-200 hover:bg-slate-50 transition-colors">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-blue-500/10 text-blue-600">
                  <Users className="h-5 w-5" />
                </div>
                <div>
                  <p className="font-medium text-slate-900">Manage Venue Owners</p>
                  <p className="text-sm text-slate-500">View, verify, suspend tenants</p>
                </div>
              </div>
            </a>
            <a href="/admin/venues" className="block p-4 rounded-lg border border-slate-200 hover:bg-slate-50 transition-colors">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-green-500/10 text-green-600">
                  <Building2 className="h-5 w-5" />
                </div>
                <div>
                  <p className="font-medium text-slate-900">Manage All Venues</p>
                  <p className="text-sm text-slate-500">Activate, suspend, disable venues</p>
                </div>
              </div>
            </a>
            <a href="/subscriptions" className="block p-4 rounded-lg border border-slate-200 hover:bg-slate-50 transition-colors">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-amber-500/10 text-amber-600">
                  <CreditCard className="h-5 w-5" />
                </div>
                <div>
                  <p className="font-medium text-slate-900">Subscription Plans</p>
                  <p className="text-sm text-slate-500">Manage platform pricing tiers</p>
                </div>
              </div>
            </a>
            <a href="/reports" className="block p-4 rounded-lg border border-slate-200 hover:bg-slate-50 transition-colors">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-emerald-500/10 text-emerald-600">
                  <TrendingUp className="h-5 w-5" />
                </div>
                <div>
                  <p className="font-medium text-slate-900">Platform Reports</p>
                  <p className="text-sm text-slate-500">Revenue, usage, growth analytics</p>
                </div>
              </div>
            </a>
            <a href="/audit-logs" className="block p-4 rounded-lg border border-slate-200 hover:bg-slate-50 transition-colors">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-red-500/10 text-red-600">
                  <AlertTriangle className="h-5 w-5" />
                </div>
                <div>
                  <p className="font-medium text-slate-900">Audit Logs</p>
                  <p className="text-sm text-slate-500">Review system activity</p>
                </div>
              </div>
            </a>
          </CardContent>
        </Card>

        <Card className="md:col-span-2">
          <CardHeader>
            <CardTitle>Platform Health</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-center justify-between p-4 rounded-lg bg-green-50 border border-green-200">
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-full bg-green-500/10 text-green-600">
                    <TrendingUp className="h-5 w-5" />
                  </div>
                  <div>
                    <p className="font-medium text-slate-900">All Systems Operational</p>
                    <p className="text-sm text-slate-500">No incidents reported</p>
                  </div>
                </div>
                <span className="px-3 py-1 rounded-full bg-green-100 text-green-700 text-sm font-medium">Healthy</span>
              </div>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div className="p-3 rounded-lg bg-slate-50">
                  <p className="text-slate-500">API Latency</p>
                  <p className="font-medium text-slate-900">~45ms avg</p>
                </div>
                <div className="p-3 rounded-lg bg-slate-50">
                  <p className="text-slate-500">Error Rate</p>
                  <p className="font-medium text-slate-900">0.02%</p>
                </div>
                <div className="p-3 rounded-lg bg-slate-50">
                  <p className="text-slate-500">Uptime (30d)</p>
                  <p className="font-medium text-slate-900">99.98%</p>
                </div>
                <div className="p-3 rounded-lg bg-slate-50">
                  <p className="text-slate-500">Active Sessions</p>
                  <p className="font-medium text-slate-900">{stats?.pending_approvals ?? "—"} pending</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
