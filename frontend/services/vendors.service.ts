import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, Vendor } from "@/types/api";

export interface VendorFormData {
  company_name: string;
  service_type: string;
  contact_person: string;
  mobile: string;
  email?: string;
  status?: string;
}

export const vendorsService = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    search?: string;
    status?: string;
    service_type?: string;
  }) => {
    const res = await apiClient.get<PaginatedResponse<Vendor>>("/vendors/", { params });
    return res.data;
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<Vendor>>(`/vendors/${id}/`);
    return res.data;
  },

  create: async (data: VendorFormData) => {
    const res = await apiClient.post<ApiResponse<Vendor>>("/vendors/", data);
    return res.data;
  },

  update: async (id: number, data: Partial<VendorFormData>) => {
    const res = await apiClient.patch<ApiResponse<Vendor>>(`/vendors/${id}/`, data);
    return res.data;
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/vendors/${id}/`);
    return res.data;
  },
};
