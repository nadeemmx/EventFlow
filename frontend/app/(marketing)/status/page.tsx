import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import StatusSubscribe from "./status-subscribe"

export const metadata = createMetadata({
  title: "System Status",
  description: "Status information for EventFlow services and a record of any incidents we have logged.",
  path: "/status",
})

const services = [
  { name: "API" },
  { name: "Database" },
  { name: "Email Service" },
  { name: "WhatsApp Notifications" },
  { name: "Payment Webhooks (Razorpay)" },
  { name: "File Storage" },
]

export default function StatusPage() {
  return (
    <>
      <PageHero
        title="System Status"
        highlight=""
        description="The services EventFlow depends on, and an honest record of anything that has gone wrong."
      />

      <section className="py-16 bg-slate-50/50">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
          <div className="bg-white rounded-xl border border-slate-200 divide-y divide-slate-100">
            {services.map((service) => (
              <div key={service.name} className="flex items-center justify-between p-5">
                <div className="flex items-center gap-3">
                  <span className="h-3 w-3 rounded-full bg-slate-300" />
                  <span className="font-medium text-slate-900">{service.name}</span>
                </div>
                <span className="text-xs text-slate-500">Live status not published yet</span>
              </div>
            ))}
          </div>
          <p className="mt-4 text-sm text-slate-600 text-center max-w-xl mx-auto">
            We do not have automated public uptime monitoring wired up yet, so we do not show
            percentages we cannot verify.
          </p>
        </div>
      </section>

      <section className="py-16">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
              Incident <span className="text-gradient">History</span>
            </h2>
            <p className="mt-3 text-slate-600 max-w-xl mx-auto">
              A record of past incidents and their resolution status.
            </p>
          </div>

          <div className="bg-white rounded-xl border border-slate-200 p-8 text-center">
            <h3 className="font-semibold text-slate-900 mb-2">No incidents recorded</h3>
            <p className="text-sm text-slate-600 leading-relaxed max-w-lg mx-auto">
              We have not logged any incidents in our public history. If you are experiencing a
              problem with EventFlow, please report it through the{" "}
              <a
                href="/help-center"
                className="font-medium text-amber-700 hover:text-amber-800 transition-colors"
              >
                help center
              </a>{" "}
              so we can track it here.
            </p>
          </div>
        </div>
      </section>

      <StatusSubscribe />

      <PageCTA
        title="Need to report an"
        highlight="issue?"
        description="If something looks wrong, let us know and we will look into it."
        buttonText="Contact Support"
        buttonHref="/help-center"
      />
    </>
  )
}
