import { useQuery } from "@tanstack/react-query";
import { auditLogsService } from "@/services/audit-logs.service";

export function useAuditLogs(params?: { page?: number; page_size?: number; module?: string; action?: string }) {
  return useQuery({
    queryKey: ["audit-logs", params],
    queryFn: () => auditLogsService.list(params),
  });
}
