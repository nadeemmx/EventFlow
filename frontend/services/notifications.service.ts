import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, Notification } from "@/types/api";

export const notificationsService = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    search?: string;
    type?: string;
    is_read?: boolean;
  }) => {
    const res = await apiClient.get<PaginatedResponse<Notification>>("/notifications/", { params });
    return res.data;
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<Notification>>(`/notifications/${id}/`);
    return res.data;
  },

  markAsRead: async (id: number) => {
    const res = await apiClient.patch<ApiResponse<Notification>>(`/notifications/${id}/`, { is_read: true });
    return res.data;
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/notifications/${id}/`);
    return res.data;
  },
};
