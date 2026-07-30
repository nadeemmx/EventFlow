import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import SectionHeader from "@/components/marketing/SectionHeader"

export const metadata = createMetadata({
  title: "Features",
  description: "Everything you need to run your event venue business",
  path: "/features",
})

const features = [
  {
    name: "Booking Management",
    description:
      "Manage the entire booking lifecycle from enquiry to check-out. Accept instant bookings, send confirmation emails, manage deposits, and track booking statuses in real time. Bulk import events and sync across multiple venue spaces simultaneously.",
  },
  {
    name: "Lead CRM",
    description:
      "Capture, track, and nurture leads with a built-in CRM designed for event venues. Log calls, send quotes, set follow-up reminders, and score leads by intent. Every interaction is stored so your sales team never misses an opportunity.",
  },
  {
    name: "Calendar",
    description:
      "A drag-and-drop calendar that shows availability across all your venues at a glance. Colour-coded by event type, filterable by space, and shareable as an embed on your website. Syncs with Google Calendar and Outlook.",
  },
  {
    name: "Payments",
    description:
      "Accept payments via Razorpay, Stripe, or bank transfers directly within EventFlow. Collect deposits, schedule instalments, issue refunds, and automatically reconcile payments against invoices. Real-time payment status with webhook notifications.",
  },
  {
    name: "Invoices",
    description:
      "Generate professional GST-compliant invoices with a single click. Support for partial payments, credit notes, bulk invoicing, and recurring billing. Send invoices via email or WhatsApp and track when they are viewed or paid.",
  },
  {
    name: "Staff Management",
    description:
      "Assign staff to events, track hours, manage shift schedules, and log attendance. Define roles like event manager, coordinator, or security guard. Payroll-ready export with overtime calculations and staff cost allocation per event.",
  },
  {
    name: "Vendor Management",
    description:
      "Maintain a vendor directory with contacts, contracts, rates, and performance ratings. Send bulk RFQs, compare quotes, and auto-assign vendors to events. Track payments and generate vendor performance reports for future events.",
  },
  {
    name: "Reports",
    description:
      "Pre-built reports for bookings, revenue, occupancy, lead conversion, vendor spend, and staff utilisation. Filter by date range, venue, or event type. Export to PDF or CSV with a single click for stakeholder presentations.",
  },
  {
    name: "Analytics",
    description:
      "Real-time dashboards with KPIs like revenue per available square foot, booking velocity, lead-to-booking conversion rate, and average event value. Trend graphs and forecasting models help you make data-driven pricing decisions.",
  },
  {
    name: "Multi-Tenant Architecture",
    description:
      "A single EventFlow instance can serve multiple venues or venues with sub-brands. Each tenant gets isolated data, custom branding, and its own user roles. Centralised billing and cross-venue reporting for multi-location operators.",
  },
  {
    name: "Role-Based Access Control",
    description:
      "Granular permissions per module — bookings, finance, leads, staff. Define custom roles (e.g., venue manager, accountant, front-desk) with module-level read/write access. Audit logs track every change made by every user.",
  },
]

export default function FeaturesPage() {
  return (
    <>
      <PageHero
        title="Everything You Need to Run Your"
        highlight="Event Venue Business"
        description="From the first lead to the final invoice, EventFlow gives you a complete toolkit purpose-built for event venue operators. No duct tape, no spreadsheets."
      />

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Explore"
            highlight="Every Feature"
            description="Eleven integrated modules that work together so your operations run smoothly."
          />
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {features.map((feature) => (
              <div
                key={feature.name}
                className="group rounded-xl border border-slate-200 bg-white p-6 transition-all hover:-translate-y-1 hover:shadow-lg hover:shadow-amber-500/10"
              >
                <h3 className="text-lg font-semibold text-slate-900 group-hover:text-amber-600 transition-colors">
                  {feature.name}
                </h3>
                <p className="mt-2 text-sm text-slate-600 leading-relaxed">
                  {feature.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <PageCTA
        title="Ready to Streamline Your Venue?"
        highlight="Start Your Free Trial"
        description="No credit card required. Set up in under 10 minutes."
        buttonText="Start Free Trial"
        buttonHref="/signup"
      />
    </>
  )
}
