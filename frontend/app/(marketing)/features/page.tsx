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
      "Manage the whole booking lifecycle from enquiry to completion. Create and edit bookings with event dates, guest counts, and amounts, move them through draft, tentative, and confirmed statuses, and keep every venue's calendar up to date.",
  },
  {
    name: "Lead CRM",
    description:
      "Capture and track leads with a built-in CRM designed for event venues. Log enquiries, send quotations, set follow-up reminders, and keep each conversation attached to the lead so nothing is lost between team members.",
  },
  {
    name: "Calendar",
    description:
      "A calendar view of your bookings across venues, colour-coded by status and filterable by venue and date, so you can see what is coming up and where the gaps are.",
  },
  {
    name: "Payments",
    description:
      "Take payments through Razorpay for UPI, cards, and net banking, or record manual payments such as cash, cheque, or bank transfer. Razorpay webhooks confirm captured payments, and every payment is matched against the booking and invoice it belongs to.",
  },
  {
    name: "Invoices",
    description:
      "Generate invoices from bookings with GST calculated from your business tax details. Record partial payments, export invoices as PDFs, and email them to customers directly from EventFlow.",
  },
  {
    name: "Staff & Tasks",
    description:
      "Keep a staff directory with contacts, designations, and joining dates, then assign tasks with priorities, due dates, and owners so the team knows what needs doing before the next event.",
  },
  {
    name: "Vendor Management",
    description:
      "Maintain a vendor directory with contacts and vendor types, assign vendors to bookings with agreed amounts, and track the status of each assignment. A vendor report shows what you have committed.",
  },
  {
    name: "Reports",
    description:
      "Reports for revenue, bookings, payments, occupancy, leads, vendors, inventory, outstanding payments, and monthly growth. Filter by date range or venue and export any report to CSV.",
  },
  {
    name: "Analytics",
    description:
      "A dashboard summary of bookings, revenue, and leads alongside occupancy and lead-conversion reports, so you can see how the business is tracking over time instead of guessing.",
  },
  {
    name: "Multi-Venue & Multi-Tenant",
    description:
      "Each organisation gets its own isolated data, users, and settings. Manage multiple venues under one account, with bookings, invoices, and reports kept separate per venue.",
  },
  {
    name: "Role-Based Access Control",
    description:
      "Module-level permissions per role — bookings, finance, leads, staff, and settings — with custom roles you can shape for managers, accountants, or front-desk staff. Audit logs record who changed what, and when.",
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
            description="Eleven modules that work together so your operations run smoothly."
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
        highlight="Start Free"
        description="No credit card required to sign up — create an account and set up your venues."
        buttonText="Create Your Account"
        buttonHref="/signup"
      />
    </>
  )
}
