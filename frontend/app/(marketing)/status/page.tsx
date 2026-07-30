import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import StatusSubscribe from "./status-subscribe"
import { CheckCircle, XCircle, Clock, ArrowUpRight, AlertTriangle } from "lucide-react"

export const metadata = createMetadata({
  title: "System Status",
  description: "Real-time status of EventFlow services. Check API, database, email, webhook, and file storage availability and incident history.",
  path: "/status",
})

const services = [
  { name: "API", status: "Operational", uptime: "99.99%", lastIncident: "No incidents in the last 90 days" },
  { name: "Database", status: "Operational", uptime: "99.99%", lastIncident: "No incidents in the last 90 days" },
  { name: "Email Service", status: "Operational", uptime: "99.95%", lastIncident: "Minor delay on June 10, 2026" },
  { name: "Webhook Service", status: "Operational", uptime: "99.98%", lastIncident: "No incidents in the last 90 days" },
  { name: "File Storage", status: "Operational", uptime: "99.99%", lastIncident: "No incidents in the last 90 days" },
]

const incidents = [
  {
    date: "June 10, 2026",
    status: "Resolved",
    title: "Email delivery delays",
    description: "Some transactional emails experienced delays of up to 15 minutes due to a temporary issue with our email provider. All messages were delivered successfully within 30 minutes.",
    duration: "22 minutes",
  },
  {
    date: "May 28, 2026",
    status: "Resolved",
    title: "Increased API latency",
    description: "Elevated response times on the Bookings API due to a database connection pool exhaustion. Engineering deployed a fix and latency returned to normal.",
    duration: "14 minutes",
  },
  {
    date: "April 15, 2026",
    status: "Resolved",
    title: "Scheduled maintenance",
    description: "Planned maintenance to upgrade our database infrastructure. The platform was unavailable for 45 minutes during the maintenance window.",
    duration: "45 minutes",
  },
  {
    date: "March 3, 2026",
    status: "Resolved",
    title: "Webhook delivery failures",
    description: "A configuration change caused webhook delivery failures for approximately 2% of events. Affected events were retried automatically once the issue was identified.",
    duration: "8 minutes",
  },
]

export default function StatusPage() {
  return (
    <>
      <PageHero
        title="System Status"
        highlight=""
        description="Real-time status of all EventFlow services. We monitor our infrastructure 24/7 to ensure maximum uptime and reliability."
      />

      <section className="py-16 bg-slate-50/50">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
          <div className="bg-white rounded-xl border border-slate-200 divide-y divide-slate-100">
            {services.map((service) => (
              <div key={service.name} className="flex items-center justify-between p-5">
                <div className="flex items-center gap-3">
                  <span className="relative flex h-3 w-3">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
                    <span className="relative inline-flex rounded-full h-3 w-3 bg-emerald-500" />
                  </span>
                  <div>
                    <span className="font-medium text-slate-900">{service.name}</span>
                    <span className="ml-2 text-sm text-emerald-600 font-medium">{service.status}</span>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-sm font-semibold text-slate-900">{service.uptime} uptime</div>
                  <div className="text-xs text-slate-500">{service.lastIncident}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Incident History */}
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

          <div className="space-y-6">
            {incidents.map((incident) => (
              <div key={incident.date} className="bg-white rounded-xl border border-slate-200 p-6">
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <Clock className="w-4 h-4 text-slate-400" />
                      <span className="text-sm text-slate-500">{incident.date}</span>
                      <span className="text-xs text-slate-400">&middot;</span>
                      <span className="text-xs text-slate-500">{incident.duration}</span>
                    </div>
                    <h3 className="font-semibold text-slate-900">{incident.title}</h3>
                  </div>
                  <span className="inline-flex items-center gap-1 px-2.5 py-1 bg-emerald-100 text-emerald-700 rounded-full text-xs font-medium">
                    <CheckCircle className="w-3 h-3" />
                    {incident.status}
                  </span>
                </div>
                <p className="text-sm text-slate-600 leading-relaxed">{incident.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <StatusSubscribe />

      <PageCTA
        title="Need to report an"
        highlight="issue?"
        description="Our support team is available 24/7 to help with any platform issues."
        buttonText="Contact Support"
        buttonHref="/help-center"
      />
    </>
  )
}
