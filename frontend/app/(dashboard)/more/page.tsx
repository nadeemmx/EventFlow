"use client"

import { useRouter } from "next/navigation"
import { Target, Building2, FileText, BarChart3, Settings, ChevronRight } from "lucide-react"
import { PageHeader } from "@/components/common/PageHeader"

const moreItems = [
  {
    label: "Leads",
    description: "Track and manage potential customers",
    href: "/leads",
    icon: Target,
  },
  {
    label: "Venues",
    description: "Manage event venues and halls",
    href: "/venues",
    icon: Building2,
  },
  {
    label: "Invoices",
    description: "Generate and manage invoices",
    href: "/invoices",
    icon: FileText,
  },
  {
    label: "Reports",
    description: "Analytics and business insights",
    href: "/reports",
    icon: BarChart3,
  },
  {
    label: "Settings",
    description: "Account and application settings",
    href: "/settings",
    icon: Settings,
  },
]

export default function MorePage() {
  const router = useRouter()

  return (
    <div className="space-y-6">
      <PageHeader title="More" description="Additional features and settings" />

      <div className="space-y-2">
        {moreItems.map((item) => {
          const Icon = item.icon
          return (
            <button
              key={item.href}
              className="flex items-center gap-4 w-full rounded-lg border p-4 text-left transition-colors hover:bg-muted/50 cursor-pointer"
              onClick={() => router.push(item.href)}
            >
              <div className="flex items-center justify-center w-10 h-10 rounded-lg bg-primary/10 text-primary shrink-0">
                <Icon className="h-5 w-5" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium">{item.label}</p>
                <p className="text-xs text-muted-foreground">{item.description}</p>
              </div>
              <ChevronRight className="h-4 w-4 text-muted-foreground shrink-0" />
            </button>
          )
        })}
      </div>
    </div>
  )
}
