import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, Payment } from "@/types/api";

export interface PaymentFormData {
  booking_id: number;
  amount: number;
  payment_method: string;
  payment_type?: string;
  transaction_reference?: string;
  payment_date: string;
  notes?: string;
}

export const paymentsService = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    booking?: number;
    payment_method?: string;
    payment_type?: string;
  }) => {
    const res = await apiClient.get<PaginatedResponse<Payment>>("/payments/", { params });
    return res.data;
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<Payment>>(`/payments/${id}/`);
    return res.data;
  },

  create: async (data: PaymentFormData) => {
    const res = await apiClient.post<ApiResponse<Payment>>("/payments/", data);
    return res.data;
  },

  update: async (id: number, data: Partial<PaymentFormData>) => {
    const res = await apiClient.patch<ApiResponse<Payment>>(`/payments/${id}/`, data);
    return res.data;
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/payments/${id}/`);
    return res.data;
  },

  refund: async (id: number) => {
    const res = await apiClient.post<ApiResponse<Payment>>(`/payments/${id}/refund/`);
    return res.data;
  },

  receipt: async (id: number) => {
    const res = await apiClient.get<Blob>(`/payments/${id}/receipt_pdf/`, {
      responseType: "blob",
    });
    return res.data;
  },
};
