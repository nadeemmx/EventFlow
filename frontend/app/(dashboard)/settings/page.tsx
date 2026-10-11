"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Building2 } from "lucide-react"
import { PageHeader } from "@/components/common/PageHeader"
import { EmptyState } from "@/components/common/EmptyState"
import { useAuth } from "@/stores/auth-context"
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs"
import OrganizationTab from "./tabs/OrganizationTab"
import ProfileTab from "./tabs/ProfileTab"
import UserManagementTab from "./tabs/UserManagementTab"
import RoleManagementTab from "./tabs/RoleManagementTab"
import PaymentGatewayTab from "./tabs/PaymentGatewayTab"
import WhatsAppTab from "./tabs/WhatsAppTab"
import EmailTab from "./tabs/EmailTab"
import InvoiceTab from "./tabs/InvoiceTab"
import BookingTab from "./tabs/BookingTab"
import NotificationTab from "./tabs/NotificationTab"
import SecurityTab from "./tabs/SecurityTab"
import BrandingTab from "./tabs/BrandingTab"
import SubscriptionTab from "./tabs/SubscriptionTab"

const TABS = [
  { id: "organization", label: "Organization" },
  { id: "profile", label: "Profile" },
  { id: "users", label: "Users" },
  { id: "roles", label: "Roles" },
  { id: "payment", label: "Payment Gateway" },
  { id: "whatsapp", label: "WhatsApp" },
  { id: "email", label: "Email" },
  { id: "invoice", label: "Invoice" },
  { id: "booking", label: "Bookings" },
  { id: "notifications", label: "Notifications" },
  { id: "security", label: "Security" },
  { id: "branding", label: "Branding" },
  { id: "subscription", label: "Subscription" },
]

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState("organization")
  const { user, loading } = useAuth()
  const router = useRouter()

  if (!loading && user?.role === "SUPER_ADMIN") {
    return (
      <div className="space-y-6">
        <PageHeader title="Settings" description="Manage your account, organization, and application settings" />
        <EmptyState
          icon={Building2}
          title="Settings are scoped to a venue tenant"
          description="Organization, profile, payment, notification and branding settings belong to each venue owner account, so they are not available on a platform administrator login. Manage tenants and their venues from Venue Owners."
          action={{ label: "Go to Venue Owners", onClick: () => router.push("/admin/tenants") }}
        />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Settings" description="Manage your account, organization, and application settings" />

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <div className="overflow-x-auto pb-2">
          <TabsList className="w-max min-w-full">
            {TABS.map(tab => (
              <TabsTrigger key={tab.id} value={tab.id}>{tab.label}</TabsTrigger>
            ))}
          </TabsList>
        </div>

        <div className="mt-6">
          <TabsContent value="organization"><OrganizationTab /></TabsContent>
          <TabsContent value="profile"><ProfileTab /></TabsContent>
          <TabsContent value="users"><UserManagementTab /></TabsContent>
          <TabsContent value="roles"><RoleManagementTab /></TabsContent>
          <TabsContent value="payment"><PaymentGatewayTab /></TabsContent>
          <TabsContent value="whatsapp"><WhatsAppTab /></TabsContent>
          <TabsContent value="email"><EmailTab /></TabsContent>
          <TabsContent value="invoice"><InvoiceTab /></TabsContent>
          <TabsContent value="booking"><BookingTab /></TabsContent>
          <TabsContent value="notifications"><NotificationTab /></TabsContent>
          <TabsContent value="security"><SecurityTab /></TabsContent>
          <TabsContent value="branding"><BrandingTab /></TabsContent>
          <TabsContent value="subscription"><SubscriptionTab /></TabsContent>
        </div>
      </Tabs>
    </div>
  )
}
