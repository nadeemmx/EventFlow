import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, Quotation, QuotationItem } from "@/types/api";

export interface QuotationFormData {
  lead?: number;
  customer: number;
  venue?: number;
  package?: number;
  valid_until?: string;
  status?: string;
  items: { item_name: string; quantity: number; unit_price: number }[];
}

export const quotationsService = {
  list: async (params?: { page?: number; page_size?: number; search?: string; status?: string }) => {
    const res = await apiClient.get<PaginatedResponse<Quotation>>("/quotations/", { params });
    return res.data;
  },
  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<Quotation>>(`/quotations/${id}/`);
    return res.data;
  },
  create: async (data: QuotationFormData) => {
    const res = await apiClient.post<ApiResponse<Quotation>>("/quotations/", data);
    return res.data;
  },
  update: async (id: number, data: Partial<QuotationFormData>) => {
    const res = await apiClient.patch<ApiResponse<Quotation>>(`/quotations/${id}/`, data);
    return res.data;
  },
  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/quotations/${id}/`);
    return res.data;
  },
  send: async (id: number) => {
    const res = await apiClient.post<ApiResponse<Quotation>>(`/quotations/${id}/send/`);
    return res.data;
  },
  accept: async (id: number) => {
    const res = await apiClient.post<ApiResponse<{ quotation_id: number; booking_id: number }>>(`/quotations/${id}/accept/`);
    return res.data;
  },
  reject: async (id: number) => {
    const res = await apiClient.post<ApiResponse<Quotation>>(`/quotations/${id}/reject/`);
    return res.data;
  },
};
