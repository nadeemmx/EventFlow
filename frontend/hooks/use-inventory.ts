import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { inventoryService, type InventoryFormData } from "@/services/inventory.service";

export function useInventory(params?: {
  page?: number;
  page_size?: number;
  search?: string;
  status?: string;
  category?: string;
}) {
  return useQuery({
    queryKey: ["inventory", params],
    queryFn: () => inventoryService.list(params),
  });
}

export function useInventoryItem(id: number) {
  return useQuery({
    queryKey: ["inventory", id],
    queryFn: () => inventoryService.get(id),
    enabled: !!id,
  });
}

export function useCreateInventoryItem() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: InventoryFormData) => inventoryService.create(data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["inventory"] }),
  });
}

export function useUpdateInventoryItem(id: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<InventoryFormData>) => inventoryService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["inventory"] });
      queryClient.invalidateQueries({ queryKey: ["inventory", id] });
    },
  });
}

export function useDeleteInventoryItem() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => inventoryService.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["inventory"] }),
  });
}
