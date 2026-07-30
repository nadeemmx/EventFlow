import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { notificationsService } from "@/services/notifications.service";

export function useNotifications(params?: {
  page?: number;
  page_size?: number;
  search?: string;
  type?: string;
  is_read?: boolean;
}) {
  return useQuery({
    queryKey: ["notifications", params],
    queryFn: () => notificationsService.list(params),
  });
}

export function useNotification(id: number) {
  return useQuery({
    queryKey: ["notification", id],
    queryFn: () => notificationsService.get(id),
    enabled: !!id,
  });
}

export function useMarkNotificationAsRead() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => notificationsService.markAsRead(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["notifications"] }),
  });
}

export function useDeleteNotification() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => notificationsService.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["notifications"] }),
  });
}
