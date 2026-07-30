import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, StaffMember } from "@/types/api";

export interface StaffFormData {
  full_name: string;
  email: string;
  mobile: string;
  role: string;
  status?: string;
}

export const staffService = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    search?: string;
    status?: string;
    role?: string;
  }) => {
    const res = await apiClient.get<PaginatedResponse<StaffMember>>("/staff/", { params });
    return res.data;
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<StaffMember>>(`/staff/${id}/`);
    return res.data;
  },

  create: async (data: StaffFormData) => {
    const res = await apiClient.post<ApiResponse<StaffMember>>("/staff/", data);
    return res.data;
  },

  update: async (id: number, data: Partial<StaffFormData>) => {
    const res = await apiClient.patch<ApiResponse<StaffMember>>(`/staff/${id}/`, data);
    return res.data;
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/staff/${id}/`);
    return res.data;
  },
};
