import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { vendorsService, type VendorFormData } from "@/services/vendors.service";

export function useVendors(params?: {
  page?: number;
  page_size?: number;
  search?: string;
  status?: string;
  service_type?: string;
}) {
  return useQuery({
    queryKey: ["vendors", params],
    queryFn: () => vendorsService.list(params),
  });
}

export function useVendor(id: number) {
  return useQuery({
    queryKey: ["vendor", id],
    queryFn: () => vendorsService.get(id),
    enabled: !!id,
  });
}

export function useCreateVendor() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: VendorFormData) => vendorsService.create(data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["vendors"] }),
  });
}

export function useUpdateVendor(id: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<VendorFormData>) => vendorsService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["vendors"] });
      queryClient.invalidateQueries({ queryKey: ["vendor", id] });
    },
  });
}

export function useDeleteVendor() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => vendorsService.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["vendors"] }),
  });
}
