import apiClient from "@/lib/api-client";
import type { ApiResponse } from "@/types/api";

export interface RevenueReport {
  total_revenue: number;
  total_bookings: number;
  average_booking_value: number;
  period_start: string;
  period_end: string;
}

export interface BookingReport {
  total_bookings: number;
  average_booking_value: number;
  confirmed: number;
  cancelled: number;
  completed: number;
  by_status: Record<string, number>;
  by_event_type: Record<string, number>;
  period_start: string;
  period_end: string;
}

export interface PaymentReport {
  total_collected: number;
  total_refunded: number;
  net_revenue: number;
  by_method: Record<string, number>;
  period_start: string;
  period_end: string;
}

export interface OccupancyReport {
  venue_id: number;
  venue_name: string;
  total_capacity: number;
  bookings_count: number;
  occupancy_rate: number;
}

export interface LeadReport {
  total_leads: number;
  by_status: Record<string, number>;
  by_source: Record<string, number>;
  conversion_rate: number;
}

export interface VendorReport {
  total_vendors: number;
  by_category: Record<string, number>;
  active_vendors: number;
}

export interface InventoryReport {
  total_items: number;
  low_stock_items: number;
  by_category: Record<string, number>;
}

export interface OutstandingPaymentItem {
  booking_id: number;
  booking_number: string;
  customer_name: string;
  venue_name: string;
  event_date: string;
  total_amount: number;
  paid_amount: number;
  outstanding_amount: number;
  status: string;
}

export interface OutstandingPaymentsReport {
  total_outstanding: number;
  total_bookings_with_balance: number;
  payments: OutstandingPaymentItem[];
}

export interface MonthlyGrowthItem {
  month: string;
  revenue: number;
  bookings: number;
  new_leads: number;
  conversions: number;
}

export interface MonthlyGrowthReport {
  total_revenue_ytd: number;
  total_bookings: number;
  total_leads: number;
  months: MonthlyGrowthItem[];
}

export const reportsService = {
  revenue: async (params?: { start_date?: string; end_date?: string }) => {
    const res = await apiClient.get<ApiResponse<RevenueReport>>("/reports/revenue/", { params });
    return res.data;
  },

  bookings: async (params?: { start_date?: string; end_date?: string }) => {
    const res = await apiClient.get<ApiResponse<BookingReport>>("/reports/bookings/", { params });
    return res.data;
  },

  payments: async (params?: { start_date?: string; end_date?: string }) => {
    const res = await apiClient.get<ApiResponse<PaymentReport>>("/reports/payments/", { params });
    return res.data;
  },

  occupancy: async (params?: { venue?: number }) => {
    const res = await apiClient.get<ApiResponse<OccupancyReport[]>>("/reports/occupancy/", { params });
    return res.data;
  },

  leads: async (params?: { start_date?: string; end_date?: string }) => {
    const res = await apiClient.get<ApiResponse<LeadReport>>("/reports/leads/", { params });
    return res.data;
  },

  vendors: async () => {
    const res = await apiClient.get<ApiResponse<VendorReport>>("/reports/vendors/");
    return res.data;
  },

  inventory: async () => {
    const res = await apiClient.get<ApiResponse<InventoryReport>>("/reports/inventory/");
    return res.data;
  },

  outstandingPayments: async (params?: { format?: string }) => {
    const res = await apiClient.get<ApiResponse<OutstandingPaymentsReport>>("/reports/outstanding/", { params });
    return res.data;
  },

  monthlyGrowth: async (params?: { year?: number; format?: string }) => {
    const res = await apiClient.get<ApiResponse<MonthlyGrowthReport>>("/reports/monthly_growth/", { params });
    return res.data;
  },

  exportReport: async (type: string, format: string, params?: Record<string, string>) => {
    const res = await apiClient.get<Blob>("/reports/export/", {
      params: { ...params, type, format },
      responseType: "blob",
    });
    return res.data;
  },
};
