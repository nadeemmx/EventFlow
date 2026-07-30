import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, InventoryItem } from "@/types/api";

export interface InventoryFormData {
  name: string;
  category: string;
  quantity: number;
  unit: string;
  status?: string;
}

export const inventoryService = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    search?: string;
    status?: string;
    category?: string;
  }) => {
    const res = await apiClient.get<PaginatedResponse<InventoryItem>>("/inventory/", { params });
    return res.data;
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<InventoryItem>>(`/inventory/${id}/`);
    return res.data;
  },

  create: async (data: InventoryFormData) => {
    const res = await apiClient.post<ApiResponse<InventoryItem>>("/inventory/", data);
    return res.data;
  },

  update: async (id: number, data: Partial<InventoryFormData>) => {
    const res = await apiClient.patch<ApiResponse<InventoryItem>>(`/inventory/${id}/`, data);
    return res.data;
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/inventory/${id}/`);
    return res.data;
  },
};
