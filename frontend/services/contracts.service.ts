import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, Contract } from "@/types/api";

export interface ContractFormData {
  booking_id: number;
  valid_from?: string;
  valid_until?: string;
  notes?: string;
}

export interface SignContractData {
  signed_by_name: string;
  signed_by_designation: string;
}

export const contractsService = {
  list: async (params?: { page?: number; page_size?: number; search?: string; status?: string }) => {
    const res = await apiClient.get<PaginatedResponse<Contract>>("/contracts/", { params });
    return res.data;
  },
  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<Contract>>(`/contracts/${id}/`);
    return res.data;
  },
  generate: async (data: ContractFormData) => {
    const res = await apiClient.post<ApiResponse<Contract>>("/contracts/generate/", data);
    return res.data;
  },
  sign: async (id: number, data: SignContractData) => {
    const res = await apiClient.post<ApiResponse<Contract>>(`/contracts/${id}/sign/`, data);
    return res.data;
  },
  cancel: async (id: number) => {
    const res = await apiClient.post<ApiResponse<Contract>>(`/contracts/${id}/cancel/`);
    return res.data;
  },
  downloadPdf: async (id: number) => {
    const res = await apiClient.get<Blob>(`/contracts/${id}/pdf/`, { responseType: "blob" });
    return res.data;
  },
};
