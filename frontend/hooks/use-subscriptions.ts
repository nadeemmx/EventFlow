import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { subscriptionsService, type SubscriptionFormData } from "@/services/subscriptions.service";

export function useSubscriptions(params?: {
  page?: number;
  page_size?: number;
  search?: string;
  status?: string;
}) {
  return useQuery({
    queryKey: ["subscriptions", params],
    queryFn: () => subscriptionsService.list(params),
  });
}

export function useSubscription(id: number) {
  return useQuery({
    queryKey: ["subscription", id],
    queryFn: () => subscriptionsService.get(id),
    enabled: !!id,
  });
}

export function useCreateSubscription() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: SubscriptionFormData) => subscriptionsService.create(data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["subscriptions"] }),
  });
}

export function useUpdateSubscription(id: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<SubscriptionFormData>) => subscriptionsService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["subscriptions"] });
      queryClient.invalidateQueries({ queryKey: ["subscription", id] });
    },
  });
}

export function useDeleteSubscription() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => subscriptionsService.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["subscriptions"] }),
  });
}
