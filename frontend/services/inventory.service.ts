import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, InventoryItem } from "@/types/api";

export interface InventoryFormData {
  name: string;
  category: string;
  quantity: number;
  unit: string;
  status?: string;
}

type ApiInventoryItem = Omit<InventoryItem, "name" | "quantity" | "unit"> & {
  item_name: string;
  total_quantity: number;
  available_quantity: number;
};

function fromApi(raw: ApiInventoryItem): InventoryItem {
  return { ...raw, name: raw.item_name, quantity: raw.total_quantity, unit: "" };
}

function toApi(
  data: Partial<InventoryFormData>
): Partial<InventoryFormData> & Record<string, unknown> {
  const { name, quantity, unit, ...rest } = data;
  void unit;
  return {
    ...rest,
    ...(name !== undefined ? { item_name: name } : {}),
    ...(quantity !== undefined ? { total_quantity: quantity } : {}),
  };
}

export const inventoryService = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    search?: string;
    status?: string;
    category?: string;
  }) => {
    const res = await apiClient.get<PaginatedResponse<ApiInventoryItem>>("/inventory/", { params });
    return { ...res.data, data: res.data.data.map(fromApi) };
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<ApiInventoryItem>>(`/inventory/${id}/`);
    return { ...res.data, data: fromApi(res.data.data) };
  },

  create: async (data: InventoryFormData) => {
    const res = await apiClient.post<ApiResponse<ApiInventoryItem>>("/inventory/", toApi(data));
    return { ...res.data, data: fromApi(res.data.data) };
  },

  update: async (id: number, data: Partial<InventoryFormData>) => {
    const res = await apiClient.patch<ApiResponse<ApiInventoryItem>>(
      `/inventory/${id}/`,
      toApi(data)
    );
    return { ...res.data, data: fromApi(res.data.data) };
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/inventory/${id}/`);
    return res.data;
  },
};
