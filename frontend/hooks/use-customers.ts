import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { customersService, type CustomerFormData } from "@/services/customers.service";

export function useCustomers(params?: { page?: number; page_size?: number; search?: string }) {
  return useQuery({
    queryKey: ["customers", params],
    queryFn: () => customersService.list(params),
  });
}

export function useCustomer(id: number) {
  return useQuery({
    queryKey: ["customer", id],
    queryFn: () => customersService.get(id),
    enabled: !!id,
  });
}

export function useCreateCustomer() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CustomerFormData) => customersService.create(data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["customers"] }),
  });
}

export function useUpdateCustomer(id: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<CustomerFormData>) => customersService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["customers"] });
      queryClient.invalidateQueries({ queryKey: ["customer", id] });
    },
  });
}

export function useDeleteCustomer() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => customersService.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["customers"] }),
  });
}
