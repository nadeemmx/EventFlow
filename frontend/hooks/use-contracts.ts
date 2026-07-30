import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { contractsService, type ContractFormData, type SignContractData } from "@/services/contracts.service";

export function useContracts(params?: { page?: number; page_size?: number; search?: string; status?: string }) {
  return useQuery({
    queryKey: ["contracts", params],
    queryFn: () => contractsService.list(params),
  });
}

export function useContract(id: number) {
  return useQuery({
    queryKey: ["contract", id],
    queryFn: () => contractsService.get(id),
    enabled: !!id,
  });
}

export function useGenerateContract() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: ContractFormData) => contractsService.generate(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["contracts"] });
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
    },
  });
}

export function useSignContract() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: SignContractData }) => contractsService.sign(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["contracts"] });
    },
  });
}

export function useCancelContract() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => contractsService.cancel(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["contracts"] });
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
    },
  });
}
