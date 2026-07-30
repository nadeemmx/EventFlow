export interface PaymentGatewaySettings {
  id: number
  gateway: string
  api_key: string
  api_secret: string
  webhook_secret: string
  is_active: boolean
  environment: "test" | "live"
}

export interface WhatsAppSettings {
  id: number
  provider: string
  api_key: string
  phone_number_id: string
  business_account_id: string
  webhook_verify_token: string
  is_active: boolean
  send_notifications: boolean
}

export interface EmailSettings {
  id: number
  smtp_host: string
  smtp_port: number
  smtp_username: string
  smtp_password: string
  from_email: string
  from_name: string
  use_tls: boolean
  use_ssl: boolean
  is_active: boolean
}

export interface InvoiceSettings {
  id: number
  prefix: string
  next_number: number
  footer_text: string
  payment_terms: string
  gst_enabled: boolean
  gst_rate: number
  show_gst: boolean
  template: string
  due_days: number
  late_payment_penalty: number
  currency: string
}

export interface BookingSettings {
  id: number
  tentative_validity_hours: number
  auto_confirm: boolean
  buffer_days: number
  max_advance_days: number
  max_refund_days: number
  allow_partial_payment: boolean
  deposit_percentage: number
  cancellation_policy: string
  require_full_payment_days: number
}

export interface NotificationSettings {
  id: number
  notify_on_booking: boolean
  notify_on_payment: boolean
  notify_on_cancellation: boolean
  notify_on_checkin: boolean
  notify_on_lead: boolean
  email_enabled: boolean
  whatsapp_enabled: boolean
  sms_enabled: boolean
  notify_admin_only: boolean
  daily_digest: boolean
  reminder_hours: number
}

export interface SecuritySettings {
  id: number
  two_factor_enabled: boolean
  session_timeout_minutes: number
  password_min_length: number
  require_special_char: boolean
  require_number: boolean
  require_uppercase: boolean
  max_login_attempts: number
  ip_whitelist_enabled: boolean
  allowed_ips: string
  allowed_domains: string
}

export interface BrandingSettings {
  id: number
  primary_color: string
  secondary_color: string
  accent_color: string
  custom_domain: string
  custom_css: string
  custom_js: string
}

export interface OrganizationSettings {
  business_name: string
  owner_name: string
  email: string
  mobile: string
  address: string
  gst_number: string
}

export interface UserProfile {
  id: number
  full_name: string
  email: string
  mobile: string
  role: string
}

export interface SettingsUser {
  id: number
  full_name: string
  email: string
  mobile: string
  role: string
  is_active: boolean
  last_login: string | null
}

export interface RoleChoice {
  value: string
  label: string
}

export interface SubscriptionInfo {
  plan_name: string
  status: string
  start_date: string
  end_date: string
  features: string[]
}
