import { useQuery } from "@tanstack/react-query";
import { reportsService } from "@/services/reports.service";

export function useRevenueReport(params?: { start_date?: string; end_date?: string }) {
  return useQuery({
    queryKey: ["report", "revenue", params],
    queryFn: () => reportsService.revenue(params),
  });
}

export function useBookingReport(params?: { start_date?: string; end_date?: string }) {
  return useQuery({
    queryKey: ["report", "bookings", params],
    queryFn: () => reportsService.bookings(params),
  });
}

export function usePaymentReport(params?: { start_date?: string; end_date?: string }) {
  return useQuery({
    queryKey: ["report", "payments", params],
    queryFn: () => reportsService.payments(params),
  });
}

export function useOccupancyReport(params?: { venue?: number }) {
  return useQuery({
    queryKey: ["report", "occupancy", params],
    queryFn: () => reportsService.occupancy(params),
  });
}

export function useLeadReport(params?: { start_date?: string; end_date?: string }) {
  return useQuery({
    queryKey: ["report", "leads", params],
    queryFn: () => reportsService.leads(params),
  });
}

export function useVendorReport() {
  return useQuery({
    queryKey: ["report", "vendors"],
    queryFn: () => reportsService.vendors(),
  });
}

export function useInventoryReport() {
  return useQuery({
    queryKey: ["report", "inventory"],
    queryFn: () => reportsService.inventory(),
  });
}

export function useOutstandingPaymentsReport() {
  return useQuery({
    queryKey: ["report", "outstanding-payments"],
    queryFn: () => reportsService.outstandingPayments(),
  });
}

export function useMonthlyGrowthReport(params?: { year?: number }) {
  return useQuery({
    queryKey: ["report", "monthly-growth", params],
    queryFn: () => reportsService.monthlyGrowth(params),
  });
}
