import apiClient from "@/lib/api-client";
import type { ApiResponse, PaginatedResponse, StaffMember } from "@/types/api";

export interface StaffFormData {
  full_name: string;
  email: string;
  mobile: string;
  role: string;
  status?: string;
}

type ApiStaff = Omit<StaffMember, "full_name" | "role"> & {
  name: string;
  designation: string;
};

function fromApi(raw: ApiStaff): StaffMember {
  return { ...raw, full_name: raw.name, role: raw.designation };
}

function toApi(data: Partial<StaffFormData>): Partial<StaffFormData> & Record<string, unknown> {
  const { full_name, role, ...rest } = data;
  return {
    ...rest,
    ...(full_name !== undefined ? { name: full_name } : {}),
    ...(role !== undefined ? { designation: role } : {}),
  };
}

export const staffService = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    search?: string;
    status?: string;
    role?: string;
  }) => {
    const { role, ...rest } = params ?? {};
    const query = {
      ...rest,
      ...(role !== undefined ? { designation: role } : {}),
    };
    const res = await apiClient.get<PaginatedResponse<ApiStaff>>("/staff/", { params: query });
    return { ...res.data, data: res.data.data.map(fromApi) };
  },

  get: async (id: number) => {
    const res = await apiClient.get<ApiResponse<ApiStaff>>(`/staff/${id}/`);
    return { ...res.data, data: fromApi(res.data.data) };
  },

  create: async (data: StaffFormData) => {
    const res = await apiClient.post<ApiResponse<ApiStaff>>("/staff/", toApi(data));
    return { ...res.data, data: fromApi(res.data.data) };
  },

  update: async (id: number, data: Partial<StaffFormData>) => {
    const res = await apiClient.patch<ApiResponse<ApiStaff>>(`/staff/${id}/`, toApi(data));
    return { ...res.data, data: fromApi(res.data.data) };
  },

  delete: async (id: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/staff/${id}/`);
    return res.data;
  },
};
