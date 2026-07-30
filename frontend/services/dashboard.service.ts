import apiClient from "@/lib/api-client";
import type { ApiResponse, DashboardSummary } from "@/types/api";

export const dashboardService = {
  summary: async () => {
    const res = await apiClient.get<ApiResponse<DashboardSummary>>("/dashboard/summary/");
    return res.data;
  },
};
