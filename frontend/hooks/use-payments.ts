import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { paymentsService, type PaymentFormData } from "@/services/payments.service";

export function usePayments(params?: {
  page?: number;
  page_size?: number;
  booking?: number;
  payment_method?: string;
  payment_type?: string;
}) {
  return useQuery({
    queryKey: ["payments", params],
    queryFn: () => paymentsService.list(params),
  });
}

export function usePayment(id: number) {
  return useQuery({
    queryKey: ["payment", id],
    queryFn: () => paymentsService.get(id),
    enabled: !!id,
  });
}

export function useCreatePayment() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: PaymentFormData) => paymentsService.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["payments"] });
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
    },
  });
}

export function useUpdatePayment(id: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<PaymentFormData>) => paymentsService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["payments"] });
      queryClient.invalidateQueries({ queryKey: ["payment", id] });
    },
  });
}

export function useDeletePayment() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => paymentsService.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["payments"] });
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
    },
  });
}

export function useRefundPayment() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => paymentsService.refund(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["payments"] });
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
    },
  });
}
