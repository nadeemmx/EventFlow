import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, Subscription } from "@/types/api";

export interface SubscriptionFormData {
  plan_name: string;
  start_date?: string;
  end_date?: string;
  amount: number;
  status?: string;
}

export const subscriptionsService = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    search?: string;
    status?: string;
  }) => {
    const res = await apiClient.get<PaginatedResponse<Subscription>>("/subscriptions/", { params });
    return res.data;
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<Subscription>>(`/subscriptions/${id}/`);
    return res.data;
  },

  create: async (data: SubscriptionFormData) => {
    const res = await apiClient.post<ApiResponse<Subscription>>("/subscriptions/", data);
    return res.data;
  },

  update: async (id: number, data: Partial<SubscriptionFormData>) => {
    const res = await apiClient.patch<ApiResponse<Subscription>>(`/subscriptions/${id}/`, data);
    return res.data;
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/subscriptions/${id}/`);
    return res.data;
  },
};
