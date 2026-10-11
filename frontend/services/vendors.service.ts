import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, Vendor } from "@/types/api";

export interface VendorFormData {
  company_name: string;
  service_type: string;
  contact_person: string;
  mobile: string;
  email?: string;
  status?: string;
}

type ApiVendor = Omit<Vendor, "company_name" | "service_type" | "contact_person"> & {
  name: string;
  vendor_type: string;
};

function fromApi(raw: ApiVendor): Vendor {
  return { ...raw, company_name: raw.name, service_type: raw.vendor_type, contact_person: "" };
}

function toApi(data: Partial<VendorFormData>): Partial<VendorFormData> & Record<string, unknown> {
  const { company_name, service_type, contact_person, ...rest } = data;
  void contact_person;
  return {
    ...rest,
    ...(company_name !== undefined ? { name: company_name } : {}),
    ...(service_type !== undefined ? { vendor_type: service_type } : {}),
  };
}

export const vendorsService = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    search?: string;
    status?: string;
    service_type?: string;
  }) => {
    const { service_type, ...rest } = params ?? {};
    const query = {
      ...rest,
      ...(service_type !== undefined ? { vendor_type: service_type } : {}),
    };
    const res = await apiClient.get<PaginatedResponse<ApiVendor>>("/vendors/", { params: query });
    return { ...res.data, data: res.data.data.map(fromApi) };
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<ApiVendor>>(`/vendors/${id}/`);
    return { ...res.data, data: fromApi(res.data.data) };
  },

  create: async (data: VendorFormData) => {
    const res = await apiClient.post<ApiResponse<ApiVendor>>("/vendors/", toApi(data));
    return { ...res.data, data: fromApi(res.data.data) };
  },

  update: async (id: number, data: Partial<VendorFormData>) => {
    const res = await apiClient.patch<ApiResponse<ApiVendor>>(`/vendors/${id}/`, toApi(data));
    return { ...res.data, data: fromApi(res.data.data) };
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/vendors/${id}/`);
    return res.data;
  },
};
