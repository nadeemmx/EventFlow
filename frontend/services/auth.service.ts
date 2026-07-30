import apiClient from "@/lib/api-client";
import type { ApiResponse, LoginRequest, LoginResponse } from "@/types/api";

export const authService = {
  async login(data: LoginRequest): Promise<LoginResponse> {
    const res = await apiClient.post<ApiResponse<LoginResponse>>("/auth/login/", data);
    return res.data.data;
  },

  async logout(refreshToken: string): Promise<void> {
    await apiClient.post("/auth/logout/", { refresh_token: refreshToken });
  },

  async refresh(refreshToken: string): Promise<{ access_token: string; refresh_token: string }> {
    const res = await apiClient.post("/auth/refresh/", { refresh_token: refreshToken });
    return res.data.data;
  },

  async changePassword(current: string, newPass: string, confirm: string): Promise<void> {
    await apiClient.post("/auth/change-password/", {
      current_password: current,
      new_password: newPass,
      confirm_password: confirm,
    });
  },
};
