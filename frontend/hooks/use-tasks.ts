import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { tasksService, type TaskFormData } from "@/services/tasks.service";

export function useTasks(params?: {
  page?: number;
  page_size?: number;
  search?: string;
  status?: string;
  priority?: string;
}) {
  return useQuery({
    queryKey: ["tasks", params],
    queryFn: () => tasksService.list(params),
  });
}

export function useTask(id: number) {
  return useQuery({
    queryKey: ["task", id],
    queryFn: () => tasksService.get(id),
    enabled: !!id,
  });
}

export function useCreateTask() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: TaskFormData) => tasksService.create(data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["tasks"] }),
  });
}

export function useUpdateTask(id: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<TaskFormData>) => tasksService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["tasks"] });
      queryClient.invalidateQueries({ queryKey: ["task", id] });
    },
  });
}

export function useDeleteTask() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => tasksService.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["tasks"] }),
  });
}
