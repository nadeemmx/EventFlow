import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, Venue } from "@/types/api";

export interface VenueFormData {
  name: string;
  venue_type: string;
  capacity: number;
  description?: string;
  address?: string;
  weekday_price?: number;
  weekend_price?: number;
  peak_price?: number;
  status?: string;
}

export const venuesService = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    search?: string;
    status?: string;
    venue_type?: string;
  }) => {
    const res = await apiClient.get<PaginatedResponse<Venue>>("/venues/", { params });
    return res.data;
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<Venue>>(`/venues/${id}/`);
    return res.data;
  },

  create: async (data: VenueFormData) => {
    const res = await apiClient.post<ApiResponse<Venue>>("/venues/", data);
    return res.data;
  },

  update: async (id: number, data: Partial<VenueFormData>) => {
    const res = await apiClient.patch<ApiResponse<Venue>>(`/venues/${id}/`, data);
    return res.data;
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/venues/${id}/`);
    return res.data;
  },

  uploadImage: async (id: number, file: File) => {
    const formData = new FormData();
    formData.append("image", file);
    const res = await apiClient.post<ApiResponse<Venue>>(`/venues/${id}/images/`, formData, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    return res.data;
  },
};
