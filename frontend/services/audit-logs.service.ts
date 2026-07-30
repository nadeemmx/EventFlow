import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, AuditLog } from "@/types/api";

export const auditLogsService = {
  list: async (params?: { page?: number; page_size?: number; module?: string; action?: string }) => {
    const res = await apiClient.get<PaginatedResponse<AuditLog>>("/audit-logs/", { params });
    return res.data;
  },
};
