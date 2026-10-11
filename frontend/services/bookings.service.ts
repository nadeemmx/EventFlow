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

type ApiTimelineEntry = Omit<TimelineEntry, "status" | "notes"> & {
  old_status: string;
  new_status: string;
  remarks: string;
};

interface ApiOutstanding {
  booking_id: number;
  booking_number: string;
  total_amount: number | string;
  total_paid: number | string;
  total_refunded: number | string;
  outstanding: number | string;
  payment_status: string;
}

export interface OutstandingInfo extends ApiOutstanding {
  paid_amount: number | string;
  balance_due: number | string;
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
    const { venue_id, customer_id, package_id, ...rest } = data;
    const res = await apiClient.post<ApiResponse<Booking>>("/bookings/", {
      ...rest,
      venue: venue_id,
      customer: customer_id,
      ...(package_id !== undefined ? { package: package_id } : {}),
    });
    return res.data;
  },

  update: async (id: number, data: Partial<BookingFormData>) => {
    const { venue_id, customer_id, package_id, ...rest } = data;
    const payload: Record<string, unknown> = { ...rest };
    if (venue_id !== undefined) payload.venue = venue_id;
    if (customer_id !== undefined) payload.customer = customer_id;
    if (package_id !== undefined) payload.package = package_id;
    const res = await apiClient.patch<ApiResponse<Booking>>(`/bookings/${id}/`, payload);
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
    const res = await apiClient.get<ApiResponse<ApiTimelineEntry[]>>(`/bookings/${id}/timeline/`);
    const entries = res.data.data ?? [];
    return {
      ...res.data,
      data: entries.map((entry) => ({
        ...entry,
        status: entry.new_status,
        notes: entry.remarks,
      })),
    };
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

  outstanding: async (id: number): Promise<ApiResponse<OutstandingInfo>> => {
    const res = await apiClient.get<ApiResponse<ApiOutstanding>>(`/bookings/${id}/outstanding/`);
    const raw = res.data.data;
    const data = raw
      ? ({ ...raw, paid_amount: raw.total_paid, balance_due: raw.outstanding } as OutstandingInfo)
      : (raw as unknown as OutstandingInfo);
    return { ...res.data, data };
  },
};
