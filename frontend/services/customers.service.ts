import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, Customer } from "@/types/api";

export interface CustomerFormData {
  full_name: string;
  mobile: string;
  email?: string;
  address?: string;
  remarks?: string;
}

export const customersService = {
  list: async (params?: { page?: number; page_size?: number; search?: string }) => {
    const res = await apiClient.get<PaginatedResponse<Customer>>("/customers/", { params });
    return res.data;
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<Customer>>(`/customers/${id}/`);
    return res.data;
  },

  create: async (data: CustomerFormData) => {
    const res = await apiClient.post<ApiResponse<Customer>>("/customers/", data);
    return res.data;
  },

  update: async (id: number, data: Partial<CustomerFormData>) => {
    const res = await apiClient.patch<ApiResponse<Customer>>(`/customers/${id}/`, data);
    return res.data;
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/customers/${id}/`);
    return res.data;
  },
};
