import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { quotationsService, type QuotationFormData } from "@/services/quotations.service";

export function useQuotations(params?: { page?: number; page_size?: number; search?: string; status?: string }) {
  return useQuery({
    queryKey: ["quotations", params],
    queryFn: () => quotationsService.list(params),
  });
}

export function useQuotation(id: number) {
  return useQuery({
    queryKey: ["quotation", id],
    queryFn: () => quotationsService.get(id),
    enabled: !!id,
  });
}

export function useCreateQuotation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: QuotationFormData) => quotationsService.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["quotations"] });
    },
  });
}

export function useUpdateQuotation(id: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<QuotationFormData>) => quotationsService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["quotations"] });
      queryClient.invalidateQueries({ queryKey: ["quotation", id] });
    },
  });
}

export function useDeleteQuotation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => quotationsService.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["quotations"] }),
  });
}

export function useSendQuotation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => quotationsService.send(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["quotations"] });
    },
  });
}

export function useAcceptQuotation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => quotationsService.accept(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["quotations"] });
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
    },
  });
}

export function useRejectQuotation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => quotationsService.reject(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["quotations"] });
    },
  });
}
