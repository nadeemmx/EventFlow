import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import SectionHeader from "@/components/marketing/SectionHeader"

export const metadata = createMetadata({
  title: "Integrations",
  description: "Connect EventFlow with the tools you already use — payments, calendars, communication, and more.",
  path: "/integrations",
})

const categories = [
  {
    name: "Payment Gateways",
    description: "Accept payments seamlessly with India's leading payment processors.",
    integrations: [
      {
        name: "Razorpay",
        description: "Collect deposits, full payments, and instalments via UPI, cards, net banking, and wallets. Automatic reconciliation with invoices.",
      },
      {
        name: "Stripe",
        description: "Global payment processing with support for 135+ currencies. Ideal for venues serving international clientele.",
      },
    ],
  },
  {
    name: "Calendar Sync",
    description: "Keep your venue availability in sync across all your calendars.",
    integrations: [
      {
        name: "Google Calendar",
        description: "Two-way sync of events, blocked dates, and venue setup times. Changes in EventFlow reflect in Google Calendar instantly.",
      },
      {
        name: "Outlook Calendar",
        description: "Sync with Microsoft 365 calendars. Supports shared mailboxes and resource calendars for enterprise setups.",
      },
    ],
  },
  {
    name: "Communication",
    description: "Reach your clients where they are — email, SMS, and WhatsApp.",
    integrations: [
      {
        name: "Email (SMTP)",
        description: "Send booking confirmations, invoices, and marketing emails via your own SMTP server or services like SendGrid and SES.",
      },
      {
        name: "SMS Gateway",
        description: "Automated SMS notifications for booking reminders, payment confirmations, and last-minute schedule changes.",
      },
      {
        name: "WhatsApp Business",
        description: "Send quotes, invoices, and event updates via WhatsApp. Two-way chat with template message approvals built in.",
      },
    ],
  },
  {
    name: "Accounting",
    description: "Push financial data to your accounting software automatically.",
    integrations: [
      {
        name: "Zoho Books",
        description: "Sync invoices, payments, and expenses to Zoho Books. Map your chart of accounts once and automate the rest.",
      },
      {
        name: "QuickBooks",
        description: "Automatic sync of invoices, credit notes, and payment receipts to QuickBooks Online. Supports GST-ready journal entries.",
      },
    ],
  },
  {
    name: "CRM Platforms",
    description: "Connect your lead data with the CRM your sales team already uses.",
    integrations: [
      {
        name: "Salesforce",
        description: "Bidirectional sync of leads, contacts, and opportunities. Map custom fields and trigger workflows from EventFlow events.",
      },
      {
        name: "HubSpot",
        description: "Sync contacts, deal stages, and communication history. Use HubSpot workflows to automate follow-ups based on booking status.",
      },
    ],
  },
]

export default function IntegrationsPage() {
  return (
    <>
      <PageHero
        title="Connect With the Tools"
        highlight="You Already Use"
        description="EventFlow plugs into your existing tech stack — payments, calendars, communication, accounting, and CRM — so you never have to re-enter data."
      />

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="space-y-16">
            {categories.map((category) => (
              <div key={category.name}>
                <SectionHeader
                  title={category.name}
                  description={category.description}
                />
                <div className="grid gap-6 sm:grid-cols-2">
                  {category.integrations.map((integration) => (
                    <div
                      key={integration.name}
                      className="rounded-xl border border-slate-200 bg-white p-6 transition-all hover:-translate-y-1 hover:shadow-lg hover:shadow-amber-500/10"
                    >
                      <div className="flex items-center gap-3 mb-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-50 text-amber-600 font-bold text-sm border border-amber-200">
                          {integration.name.charAt(0)}
                        </div>
                        <h3 className="text-lg font-semibold text-slate-900">{integration.name}</h3>
                      </div>
                      <p className="text-sm text-slate-600 leading-relaxed">
                        {integration.description}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="py-20 bg-slate-50/50">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid gap-12 lg:grid-cols-2 items-center">
            <div>
              <SectionHeader
                title="REST API &"
                highlight="Webhooks"
                description="Build custom integrations on top of EventFlow using our developer-friendly REST API."
              />
              <div className="space-y-4">
                <div className="rounded-xl border border-slate-200 bg-white p-5">
                  <h4 className="text-sm font-semibold text-slate-900 mb-1">RESTful API</h4>
                  <p className="text-sm text-slate-600">
                    Full CRUD access to bookings, leads, invoices, venues, and staff records. API keys with scoped permissions. Rate limit of 1,000 requests per minute. JSON responses with consistent error formatting.
                  </p>
                </div>
                <div className="rounded-xl border border-slate-200 bg-white p-5">
                  <h4 className="text-sm font-semibold text-slate-900 mb-1">Webhooks</h4>
                  <p className="text-sm text-slate-600">
                    Subscribe to events like booking.created, payment.received, or invoice.overdue. We will POST a JSON payload to your endpoint in real time. Retry with exponential backoff for reliability.
                  </p>
                </div>
                <div className="rounded-xl border border-slate-200 bg-white p-5">
                  <h4 className="text-sm font-semibold text-slate-900 mb-1">API Documentation</h4>
                  <p className="text-sm text-slate-600">
                    Interactive OpenAPI 3.0 docs with Try It endpoints. SDKs available for Node.js, Python, and PHP. Sample Postman collections included.
                  </p>
                </div>
              </div>
            </div>
            <div className="rounded-2xl border border-slate-200 bg-white p-8">
              <div className="text-xs font-mono text-slate-500 space-y-2">
                <p className="text-slate-400">{"// Example: Create a booking via API"}</p>
                <p><span className="text-amber-600">POST</span> <span className="text-slate-800">/api/v1/bookings</span></p>
                <p className="text-slate-600">{`{`}</p>
                <p className="pl-4">&quot;venue_id&quot;: <span className="text-green-600">&quot;v_abc123&quot;</span>,</p>
                <p className="pl-4">&quot;customer_name&quot;: <span className="text-green-600">&quot;Priya Mehta&quot;</span>,</p>
                <p className="pl-4">&quot;event_date&quot;: <span className="text-green-600">&quot;2026-08-15&quot;</span>,</p>
                <p className="pl-4">&quot;event_type&quot;: <span className="text-green-600">&quot;wedding&quot;</span>,</p>
                <p className="pl-4">&quot;guest_count&quot;: <span className="text-green-600">250</span>,</p>
                <p className="pl-4">&quot;total_amount&quot;: <span className="text-green-600">450000</span></p>
                <p className="text-slate-600">{`}`}</p>
                <p className="mt-4 text-slate-400">{"// Response: 201 Created"}</p>
                <p className="text-slate-600">{`{`}</p>
                <p className="pl-4">&quot;id&quot;: <span className="text-green-600">&quot;bk_xyz789&quot;</span>,</p>
                <p className="pl-4">&quot;status&quot;: <span className="text-green-600">&quot;confirmed&quot;</span>,</p>
                <p className="pl-4">&quot;created_at&quot;: <span className="text-green-600">&quot;2026-06-23T10:30:00Z&quot;</span></p>
                <p className="text-slate-600">{`}`}</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <PageCTA
        title="Integrate EventFlow With Your Stack"
        highlight="Get Started"
        description="Our integrations team can help you set up connections in under an hour."
        buttonText="View Documentation"
        buttonHref="/docs"
      />
    </>
  )
}
