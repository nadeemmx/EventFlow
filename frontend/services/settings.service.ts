import apiClient from "@/lib/api-client"
import type { ApiResponse } from "@/types/api"
import type {
  PaymentGatewaySettings,
  WhatsAppSettings,
  EmailSettings,
  InvoiceSettings,
  BookingSettings,
  NotificationSettings,
  SecuritySettings,
  BrandingSettings,
  OrganizationSettings,
  UserProfile,
  SettingsUser,
  RoleChoice,
  SubscriptionInfo,
} from "@/types/settings"

const BASE = "/settings"

export async function getPaymentGatewaySettings(): Promise<ApiResponse<PaymentGatewaySettings>> {
  const { data } = await apiClient.get(`${BASE}/payment_gateway/`)
  return data
}

export async function updatePaymentGatewaySettings(settings: Partial<PaymentGatewaySettings>): Promise<ApiResponse<PaymentGatewaySettings>> {
  const { data } = await apiClient.put(`${BASE}/payment_gateway/`, settings)
  return data
}

export async function getWhatsAppSettings(): Promise<ApiResponse<WhatsAppSettings>> {
  const { data } = await apiClient.get(`${BASE}/whatsapp/`)
  return data
}

export async function updateWhatsAppSettings(settings: Partial<WhatsAppSettings>): Promise<ApiResponse<WhatsAppSettings>> {
  const { data } = await apiClient.put(`${BASE}/whatsapp/`, settings)
  return data
}

export async function getEmailSettings(): Promise<ApiResponse<EmailSettings>> {
  const { data } = await apiClient.get(`${BASE}/email/`)
  return data
}

export async function updateEmailSettings(settings: Partial<EmailSettings>): Promise<ApiResponse<EmailSettings>> {
  const { data } = await apiClient.put(`${BASE}/email/`, settings)
  return data
}

export async function getInvoiceSettings(): Promise<ApiResponse<InvoiceSettings>> {
  const { data } = await apiClient.get(`${BASE}/invoice/`)
  return data
}

export async function updateInvoiceSettings(settings: Partial<InvoiceSettings>): Promise<ApiResponse<InvoiceSettings>> {
  const { data } = await apiClient.put(`${BASE}/invoice/`, settings)
  return data
}

export async function getBookingSettings(): Promise<ApiResponse<BookingSettings>> {
  const { data } = await apiClient.get(`${BASE}/booking/`)
  return data
}

export async function updateBookingSettings(settings: Partial<BookingSettings>): Promise<ApiResponse<BookingSettings>> {
  const { data } = await apiClient.put(`${BASE}/booking/`, settings)
  return data
}

export async function getNotificationSettings(): Promise<ApiResponse<NotificationSettings>> {
  const { data } = await apiClient.get(`${BASE}/notifications/`)
  return data
}

export async function updateNotificationSettings(settings: Partial<NotificationSettings>): Promise<ApiResponse<NotificationSettings>> {
  const { data } = await apiClient.put(`${BASE}/notifications/`, settings)
  return data
}

export async function getSecuritySettings(): Promise<ApiResponse<SecuritySettings>> {
  const { data } = await apiClient.get(`${BASE}/security/`)
  return data
}

export async function updateSecuritySettings(settings: Partial<SecuritySettings>): Promise<ApiResponse<SecuritySettings>> {
  const { data } = await apiClient.put(`${BASE}/security/`, settings)
  return data
}

export async function getBrandingSettings(): Promise<ApiResponse<BrandingSettings>> {
  const { data } = await apiClient.get(`${BASE}/branding/`)
  return data
}

export async function updateBrandingSettings(settings: Partial<BrandingSettings>): Promise<ApiResponse<BrandingSettings>> {
  const { data } = await apiClient.put(`${BASE}/branding/`, settings)
  return data
}

export async function getOrganizationSettings(): Promise<ApiResponse<OrganizationSettings>> {
  const { data } = await apiClient.get(`${BASE}/organization/`)
  return data
}

export async function updateOrganizationSettings(settings: Partial<OrganizationSettings>): Promise<ApiResponse<OrganizationSettings>> {
  const { data } = await apiClient.put(`${BASE}/organization/`, settings)
  return data
}

export async function getProfile(): Promise<ApiResponse<UserProfile>> {
  const { data } = await apiClient.get(`${BASE}/profile/`)
  return data
}

export async function updateProfile(profile: Partial<UserProfile>): Promise<ApiResponse<UserProfile>> {
  const { data } = await apiClient.put(`${BASE}/profile/`, profile)
  return data
}

export async function getUsers(): Promise<ApiResponse<SettingsUser[]>> {
  const { data } = await apiClient.get(`${BASE}/users/`)
  return data
}

export async function createUser(user: Partial<SettingsUser> & { password?: string }): Promise<ApiResponse<SettingsUser>> {
  const { data } = await apiClient.post(`${BASE}/users/`, user)
  return data
}

export async function updateUser(id: number, user: Partial<SettingsUser>): Promise<ApiResponse<SettingsUser>> {
  const { data } = await apiClient.put(`${BASE}/${id}/update_user/`, user)
  return data
}

export async function deleteUser(id: number): Promise<ApiResponse<void>> {
  const { data } = await apiClient.delete(`${BASE}/${id}/delete_user/`)
  return data
}

export async function activateUser(id: number): Promise<ApiResponse<SettingsUser>> {
  const { data } = await apiClient.post(`${BASE}/${id}/activate/`)
  return data
}

export async function deactivateUser(id: number): Promise<ApiResponse<SettingsUser>> {
  const { data } = await apiClient.post(`${BASE}/${id}/deactivate/`)
  return data
}

export async function getRoles(): Promise<ApiResponse<RoleChoice[]>> {
  const { data } = await apiClient.get(`${BASE}/roles/`)
  return data
}

export async function getSubscription(): Promise<ApiResponse<SubscriptionInfo>> {
  const { data } = await apiClient.get(`${BASE}/subscription/`)
  return data
}
