import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, Task } from "@/types/api";

export interface TaskFormData {
  title: string;
  description?: string;
  assigned_to?: number | null;
  priority: string;
  status: string;
  due_date?: string;
}

export const tasksService = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    search?: string;
    status?: string;
    priority?: string;
  }) => {
    const res = await apiClient.get<PaginatedResponse<Task>>("/tasks/", { params });
    return res.data;
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<Task>>(`/tasks/${id}/`);
    return res.data;
  },

  create: async (data: TaskFormData) => {
    const res = await apiClient.post<ApiResponse<Task>>("/tasks/", data);
    return res.data;
  },

  update: async (id: number, data: Partial<TaskFormData>) => {
    const res = await apiClient.patch<ApiResponse<Task>>(`/tasks/${id}/`, data);
    return res.data;
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/tasks/${id}/`);
    return res.data;
  },
};
