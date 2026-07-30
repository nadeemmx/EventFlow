import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, Invoice } from "@/types/api";

export interface InvoiceFormData {
  booking_id: number;
  notes?: string;
}

export const invoicesService = {
  list: async (params?: { page?: number; page_size?: number; search?: string; date_from?: string; date_to?: string }) => {
    const res = await apiClient.get<PaginatedResponse<Invoice>>("/invoices/", { params });
    return res.data;
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<Invoice>>(`/invoices/${id}/`);
    return res.data;
  },

  update: async (id: number, data: Partial<InvoiceFormData>) => {
    const res = await apiClient.patch<ApiResponse<Invoice>>(`/invoices/${id}/`, data);
    return res.data;
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/invoices/${id}/`);
    return res.data;
  },

  generate: async (booking_id: number) => {
    const res = await apiClient.post<ApiResponse<Invoice>>("/invoices/generate/", { booking_id });
    return res.data;
  },

  downloadPdf: async (id: number) => {
    const res = await apiClient.get<Blob>(`/invoices/${id}/download/`, {
      responseType: "blob",
    });
    return res.data;
  },

  email: async (id: number) => {
    const res = await apiClient.post<ApiResponse<void>>(`/invoices/${id}/email/`);
    return res.data;
  },
};
