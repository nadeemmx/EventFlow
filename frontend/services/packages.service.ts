import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, Package } from "@/types/api";

export interface PackageFormData {
  name: string;
  description?: string;
  price: number;
  items_count?: number;
  status?: string;
}

type ApiPackage = Omit<Package, "price" | "items_count"> & {
  base_price: string;
  items: unknown[];
};

function fromApi(raw: ApiPackage): Package {
  return { ...raw, price: raw.base_price, items_count: raw.items?.length ?? 0 };
}

function toApi(data: Partial<PackageFormData>): Partial<PackageFormData> & Record<string, unknown> {
  const { price, items_count, ...rest } = data;
  void items_count;
  return {
    ...rest,
    ...(price !== undefined ? { base_price: price } : {}),
  };
}

export const packagesService = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    search?: string;
    status?: string;
  }) => {
    const res = await apiClient.get<PaginatedResponse<ApiPackage>>("/packages/", { params });
    return { ...res.data, data: res.data.data.map(fromApi) };
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<ApiPackage>>(`/packages/${id}/`);
    return { ...res.data, data: fromApi(res.data.data) };
  },

  create: async (data: PackageFormData) => {
    const res = await apiClient.post<ApiResponse<ApiPackage>>("/packages/", toApi(data));
    return { ...res.data, data: fromApi(res.data.data) };
  },

  update: async (id: number, data: Partial<PackageFormData>) => {
    const res = await apiClient.patch<ApiResponse<ApiPackage>>(`/packages/${id}/`, toApi(data));
    return { ...res.data, data: fromApi(res.data.data) };
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/packages/${id}/`);
    return res.data;
  },
};
