export interface ApiResponse<T = unknown> {
  success: boolean;
  message: string;
  data: T;
  errors?: Record<string, string[]>;
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination: {
    page: number;
    page_size: number;
    total_records: number;
    total_pages: number;
  };
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  access_token: string;
  refresh_token: string;
  user: User;
}

export interface User {
  id: number;
  full_name: string;
  email: string;
  role: string;
  tenant_id: number | null;
}

export interface Booking {
  id: number;
  booking_number: string;
  venue: number;
  venue_name?: string;
  customer: number;
  customer_name?: string;
  event_type: string;
  event_date: string;
  guest_count: number;
  total_amount: string;
  advance_amount: string;
  status: string;
  remarks: string;
  created_at: string;
  updated_at: string;
}

export interface Customer {
  id: number;
  full_name: string;
  mobile: string;
  email: string;
  address: string;
}

export interface Lead {
  id: number;
  customer: number;
  customer_name?: string;
  lead_source: string;
  event_type: string;
  lead_status: string;
  assigned_to: number | null;
  created_at: string;
}

export interface Venue {
  id: number;
  name: string;
  venue_type: string;
  capacity: number;
  status: string;
  weekday_price: string;
  weekend_price: string;
}

export interface Payment {
  id: number;
  booking: number;
  amount: string;
  payment_method: string;
  payment_type: string;
  payment_date: string;
}

export interface Invoice {
  id: number;
  booking: number;
  invoice_number: string;
  total_amount: string;
  created_at: string;
}

export interface DashboardSummary {
  today_events: number;
  upcoming_bookings: number;
  pending_payments: number;
  active_leads: number;
  monthly_revenue: number;
}

export interface Contract {
  id: number;
  booking: number;
  booking_number?: string;
  customer_name?: string;
  venue_name?: string;
  contract_number: string;
  content: string;
  status: string;
  pdf_file: string | null;
  valid_from: string;
  valid_until: string;
  signed_date: string | null;
  signed_by_name: string;
  signed_by_designation: string;
  template_version: string;
  notes: string;
  created_at: string;
  updated_at: string;
}

export interface Quotation {
  id: number;
  lead?: number;
  customer: number;
  customer_name?: string;
  venue?: number;
  venue_name?: string;
  package?: number;
  valid_until: string;
  status: string;
  subtotal: string;
  tax_amount: string;
  total_amount: string;
  items?: QuotationItem[];
  item_count?: number;
  created_at: string;
  updated_at: string;
}

export interface QuotationItem {
  id: number;
  quotation?: number;
  item_name: string;
  quantity: number;
  unit_price: number;
  total_price: number;
}

export interface AuditLog {
  id: number;
  user: number;
  module: string;
  action: string;
  record_id: number | null;
  old_data: string;
  new_data: string;
  ip_address: string;
  created_at: string;
}

export interface BookingWithDetails extends Booking {
  payments?: Payment[];
  contract?: Contract;
  balance_due: number;
  payment_status: string;
}

export interface InventoryItem {
  id: number;
  name: string;
  category: string;
  quantity: number;
  unit: string;
  status: string;
}

export interface StaffMember {
  id: number;
  full_name: string;
  email: string;
  mobile: string;
  role: string;
  status: string;
}

export interface Task {
  id: number;
  title: string;
  description: string;
  assigned_to: number | null;
  assigned_to_name?: string;
  priority: string;
  status: string;
  due_date: string;
  created_at: string;
}

export interface Vendor {
  id: number;
  company_name: string;
  service_type: string;
  contact_person: string;
  mobile: string;
  email: string;
  status: string;
}

export interface Package {
  id: number;
  name: string;
  description: string;
  price: string;
  items_count: number;
  status: string;
}

export interface Subscription {
  id: number;
  plan_name: string;
  start_date: string;
  end_date: string;
  amount: string;
  status: string;
}

export interface Notification {
  id: number;
  title: string;
  message: string;
  type: string;
  is_read: boolean;
  created_at: string;
}
