import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, Package } from "@/types/api";

export interface PackageFormData {
  name: string;
  description?: string;
  price: number;
  items_count?: number;
  status?: string;
}

export const packagesService = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    search?: string;
    status?: string;
  }) => {
    const res = await apiClient.get<PaginatedResponse<Package>>("/packages/", { params });
    return res.data;
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<Package>>(`/packages/${id}/`);
    return res.data;
  },

  create: async (data: PackageFormData) => {
    const res = await apiClient.post<ApiResponse<Package>>("/packages/", data);
    return res.data;
  },

  update: async (id: number, data: Partial<PackageFormData>) => {
    const res = await apiClient.patch<ApiResponse<Package>>(`/packages/${id}/`, data);
    return res.data;
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/packages/${id}/`);
    return res.data;
  },
};
