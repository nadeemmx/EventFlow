import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { staffService, type StaffFormData } from "@/services/staff.service";

export function useStaff(params?: {
  page?: number;
  page_size?: number;
  search?: string;
  status?: string;
  role?: string;
}) {
  return useQuery({
    queryKey: ["staff", params],
    queryFn: () => staffService.list(params),
  });
}

export function useStaffMember(id: number) {
  return useQuery({
    queryKey: ["staff", id],
    queryFn: () => staffService.get(id),
    enabled: !!id,
  });
}

export function useCreateStaffMember() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: StaffFormData) => staffService.create(data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["staff"] }),
  });
}

export function useUpdateStaffMember(id: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<StaffFormData>) => staffService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["staff"] });
      queryClient.invalidateQueries({ queryKey: ["staff", id] });
    },
  });
}

export function useDeleteStaffMember() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => staffService.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["staff"] }),
  });
}
