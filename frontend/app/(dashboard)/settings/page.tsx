"use client"

import { useState } from "react"
import { PageHeader } from "@/components/common/PageHeader"
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
