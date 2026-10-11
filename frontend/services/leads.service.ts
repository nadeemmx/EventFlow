import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, Lead } from "@/types/api";

export interface LeadFormData {
  customer_id: number;
  lead_source: string;
  event_type: string;
  expected_event_date: string;
  expected_guest_count: number;
  lead_status: string;
  assigned_to?: number | null;
}

export interface FollowupData {
  followup_date: string;
  notes: string;
  next_action?: string;
}

export interface Followup {
  id: number;
  lead: number;
  followup_date: string;
  notes: string;
  next_action: string;
  created_at: string;
}

export const leadsService = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    search?: string;
    lead_status?: string;
    lead_source?: string;
    assigned_to?: number;
  }) => {
    const res = await apiClient.get<PaginatedResponse<Lead>>("/leads/", { params });
    return res.data;
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<Lead>>(`/leads/${id}/`);
    return res.data;
  },

  create: async (data: LeadFormData) => {
    const { customer_id, ...rest } = data;
    const res = await apiClient.post<ApiResponse<Lead>>("/leads/", { ...rest, customer: customer_id });
    return res.data;
  },

  update: async (id: number, data: Partial<LeadFormData>) => {
    const { customer_id, ...rest } = data;
    const payload = customer_id !== undefined ? { ...rest, customer: customer_id } : rest;
    const res = await apiClient.patch<ApiResponse<Lead>>(`/leads/${id}/`, payload);
    return res.data;
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/leads/${id}/`);
    return res.data;
  },

  convert: async (id: number) => {
    const res = await apiClient.post<ApiResponse<{ lead_id: number; booking_id: number }>>(`/leads/${id}/convert/`);
    return res.data;
  },

  listFollowups: async (id: number) => {
    const res = await apiClient.get<ApiResponse<Followup[]>>(`/leads/${id}/followups/`);
    return res.data;
  },

  addFollowup: async (id: number, data: FollowupData) => {
    const res = await apiClient.post<ApiResponse<Followup>>(`/leads/${id}/add_followup/`, data);
    return res.data;
  },
};
