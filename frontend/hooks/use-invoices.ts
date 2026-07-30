import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { invoicesService, type InvoiceFormData } from "@/services/invoices.service";

export function useInvoices(params?: { page?: number; page_size?: number; search?: string; date_from?: string; date_to?: string }) {
  return useQuery({
    queryKey: ["invoices", params],
    queryFn: () => invoicesService.list(params),
  });
}

export function useInvoice(id: number) {
  return useQuery({
    queryKey: ["invoice", id],
    queryFn: () => invoicesService.get(id),
    enabled: !!id,
  });
}

export function useGenerateInvoice() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (booking_id: number) => invoicesService.generate(booking_id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["invoices"] });
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
    },
  });
}

export function useUpdateInvoice(id: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<InvoiceFormData>) => invoicesService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["invoices"] });
      queryClient.invalidateQueries({ queryKey: ["invoice", id] });
    },
  });
}

export function useDeleteInvoice() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => invoicesService.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["invoices"] }),
  });
}

export function useEmailInvoice() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => invoicesService.email(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["invoices"] });
    },
  });
}
