import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { packagesService, type PackageFormData } from "@/services/packages.service";

export function usePackages(params?: {
  page?: number;
  page_size?: number;
  search?: string;
  status?: string;
}) {
  return useQuery({
    queryKey: ["packages", params],
    queryFn: () => packagesService.list(params),
  });
}

export function usePackage(id: number) {
  return useQuery({
    queryKey: ["package", id],
    queryFn: () => packagesService.get(id),
    enabled: !!id,
  });
}

export function useCreatePackage() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: PackageFormData) => packagesService.create(data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["packages"] }),
  });
}

export function useUpdatePackage(id: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<PackageFormData>) => packagesService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["packages"] });
      queryClient.invalidateQueries({ queryKey: ["package", id] });
    },
  });
}

export function useDeletePackage() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => packagesService.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["packages"] }),
  });
}
