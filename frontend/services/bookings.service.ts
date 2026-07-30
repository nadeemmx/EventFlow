import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, Booking } from "@/types/api";

export interface BookingFormData {
  venue_id: number;
  customer_id: number;
  package_id?: number;
  event_type: string;
  event_date: string;
  guest_count: number;
  total_amount: number;
  advance_amount: number;
  status?: string;
  remarks?: string;
}

export interface TimelineEntry {
  id: number;
  booking: number;
  status: string;
  notes: string;
  created_at: string;
}

export const bookingsService = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    search?: string;
    status?: string;
    venue?: number;
    event_type?: string;
  }) => {
    const res = await apiClient.get<PaginatedResponse<Booking>>("/bookings/", { params });
    return res.data;
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<Booking>>(`/bookings/${id}/`);
    return res.data;
  },

  create: async (data: BookingFormData) => {
    const res = await apiClient.post<ApiResponse<Booking>>("/bookings/", data);
    return res.data;
  },

  update: async (id: number, data: Partial<BookingFormData>) => {
    const res = await apiClient.patch<ApiResponse<Booking>>(`/bookings/${id}/`, data);
    return res.data;
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/bookings/${id}/`);
    return res.data;
  },

  confirm: async (id: number) => {
    const res = await apiClient.post<ApiResponse<Booking>>(`/bookings/${id}/confirm/`);
    return res.data;
  },

  cancel: async (id: number, remarks?: string) => {
    const res = await apiClient.post<ApiResponse<Booking>>(`/bookings/${id}/cancel/`, { remarks });
    return res.data;
  },

  timeline: async (id: number) => {
    const res = await apiClient.get<ApiResponse<TimelineEntry[]>>(`/bookings/${id}/timeline/`);
    return res.data;
  },

  calendar: async (params: { month: number; year: number; venue?: number }) => {
    const res = await apiClient.get<ApiResponse<Booking[]>>("/bookings/calendar/", { params });
    return res.data;
  },

  markInProgress: async (id: number) => {
    const res = await apiClient.post<ApiResponse<Booking>>(`/bookings/${id}/mark_in_progress/`);
    return res.data;
  },

  markCompleted: async (id: number) => {
    const res = await apiClient.post<ApiResponse<Booking>>(`/bookings/${id}/mark_completed/`);
    return res.data;
  },

  outstanding: async (id: number) => {
    const res = await apiClient.get<ApiResponse<{ booking_id: number; total_amount: string; paid_amount: string; balance_due: string }>>(`/bookings/${id}/outstanding/`);
    return res.data;
  },
};
