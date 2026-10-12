import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import {
  BookOpen,
  Shield,
  CreditCard,
  Webhook,
  Terminal,
  ChevronRight,
} from "lucide-react"

export const metadata = createMetadata({
  title: "Documentation",
  description: "Documentation for the EventFlow API and platform. Get started with quick guides, authentication, and API references.",
  path: "/docs",
})

const sidebarItems = [
  {
    category: "Getting Started",
    items: [
      { label: "Quick Start", href: "#quick-start" },
      { label: "Authentication", href: "#authentication" },
      { label: "Explore More", href: "#explore" },
    ],
  },
  {
    category: "Reference",
    items: [
      { label: "API Reference", href: "/api-reference" },
      { label: "Integrations", href: "/integrations" },
      { label: "Security", href: "/security" },
    ],
  },
  {
    category: "Support",
    items: [
      { label: "Help Center", href: "/help-center" },
      { label: "Contact", href: "/contact" },
      { label: "Status", href: "/status" },
    ],
  },
]

const docCards = [
  {
    icon: BookOpen,
    title: "Authentication",
    desc: "Authenticate API requests with a bearer access token issued at sign-in.",
    href: "#authentication",
    color: "text-amber-700",
  },
  {
    icon: CreditCard,
    title: "Payments",
    desc: "Accept payments through Razorpay and record them against bookings and invoices.",
    href: "/integrations",
    color: "text-emerald-500",
  },
  {
    icon: Webhook,
    title: "Payment Webhooks",
    desc: "Razorpay payment events are sent to our endpoint, verified by signature, and recorded.",
    href: "/integrations",
    color: "text-blue-500",
  },
  {
    icon: Terminal,
    title: "API Reference",
    desc: "Endpoint-by-endpoint reference with request and response examples.",
    href: "/api-reference",
    color: "text-purple-500",
  },
  {
    icon: Shield,
    title: "Security",
    desc: "How we protect your integration and the data your venue stores with us.",
    href: "/security",
    color: "text-red-500",
  },
  {
    icon: BookOpen,
    title: "Help Center",
    desc: "Answers to common questions, or contact us if something is unclear.",
    href: "/help-center",
    color: "text-cyan-500",
  },
]

export default function DocsPage() {
  return (
    <>
      <PageHero
        title="Documentation"
        highlight=""
        description="Everything you need to integrate EventFlow into your venue management workflow."
      />

      <section className="py-16 bg-slate-50/50">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col lg:flex-row gap-8">
            {/* Sidebar */}
            <aside className="lg:w-64 shrink-0">
              <nav className="sticky top-24 space-y-6" aria-label="Documentation sections">
                {sidebarItems.map((group) => (
                  <div key={group.category}>
                    <h2 className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">
                      {group.category}
                    </h2>
                    <ul className="space-y-1">
                      {group.items.map((item) => (
                        <li key={item.label}>
                          <a
                            href={item.href}
                            className="flex items-center gap-1 text-sm text-slate-600 hover:text-amber-600 transition-colors py-1"
                          >
                            <ChevronRight className="w-3 h-3 text-slate-500" aria-hidden="true" focusable="false" />
                            {item.label}
                          </a>
                        </li>
                      ))}
                    </ul>
                  </div>
                ))}
              </nav>
            </aside>

            {/* Main content */}
            <div className="flex-1 min-w-0">
              <section id="quick-start">
                <h2 className="text-2xl font-bold text-slate-900 mb-6">Quick Start Guide</h2>
                <p className="text-slate-600 mb-8 leading-relaxed">
                  Get up and running with the EventFlow API. This guide walks you through signing
                  in and making your first authenticated request.
                </p>

                <div className="space-y-6">
                  <div className="bg-white rounded-xl border border-slate-200 p-6">
                    <div className="flex items-center gap-3 mb-3">
                      <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-amber-700 text-white text-sm font-bold">1</span>
                      <h3 className="font-semibold text-slate-900">Sign In for an Access Token</h3>
                    </div>
                    <p className="text-slate-600 text-sm mb-3">
                      The API authenticates with JSON Web Tokens. Post your account credentials to
                      the sign-in endpoint and keep the{" "}
                      <code className="px-1.5 py-0.5 bg-slate-100 text-slate-800 rounded text-xs">data.access_token</code>{" "}
                      value it returns. Store your password securely — never commit it.
                    </p>
                    <pre className="bg-slate-900 text-slate-100 rounded-lg p-4 text-sm overflow-x-auto">
                      <code>{`export EVENTFLOW_API_URL="https://api.eventflow.com/api/v1"

curl -X POST "$EVENTFLOW_API_URL/auth/login/" \\
  -H "Content-Type: application/json" \\
  -d '{"email": "you@yourvenue.com", "password": "your-password"}'`}</code>
                    </pre>
                  </div>

                  <div className="bg-white rounded-xl border border-slate-200 p-6">
                    <div className="flex items-center gap-3 mb-3">
                      <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-amber-700 text-white text-sm font-bold">2</span>
                      <h3 className="font-semibold text-slate-900">Make Your First API Call</h3>
                    </div>
                    <p className="text-slate-600 text-sm mb-3">
                      Send the token as a bearer token. You can use curl or any HTTP client.
                    </p>
                    <pre className="bg-slate-900 text-slate-100 rounded-lg p-4 text-sm overflow-x-auto">
                      <code>{`curl "$EVENTFLOW_API_URL/venues/" \\
  -H "Authorization: Bearer $EVENTFLOW_ACCESS_TOKEN" \\
  -H "Content-Type: application/json"`}</code>
                    </pre>
                  </div>

                  <div className="bg-white rounded-xl border border-slate-200 p-6">
                    <div className="flex items-center gap-3 mb-3">
                      <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-amber-700 text-white text-sm font-bold">3</span>
                      <h3 className="font-semibold text-slate-900">Create a Booking</h3>
                    </div>
                    <p className="text-slate-600 text-sm mb-3">
                      Submit a booking with the venue, customer, event date, and guest count. Your
                      venue, customer, and package records must already exist in your account.
                    </p>
                    <pre className="bg-slate-900 text-slate-100 rounded-lg p-4 text-sm overflow-x-auto">
                      <code>{`curl -X POST "$EVENTFLOW_API_URL/bookings/" \\
  -H "Authorization: Bearer $EVENTFLOW_ACCESS_TOKEN" \\
  -H "Content-Type: application/json" \\
  -d '{
  "venue": 1,
  "customer": 1,
  "event_type": "wedding",
  "event_date": "2026-12-15",
  "guest_count": 250,
  "total_amount": 450000,
  "advance_amount": 50000
}'`}</code>
                    </pre>
                  </div>
                </div>
              </section>

              <section id="authentication" className="mt-12">
                <h2 className="text-2xl font-bold text-slate-900 mb-6">Authentication</h2>
                <p className="text-slate-600 mb-6 leading-relaxed">
                  EventFlow uses JWT access tokens for authentication. Include your token in the
                  <code className="mx-1 px-2 py-0.5 bg-slate-100 text-slate-800 rounded text-sm">Authorization</code>
                  header of every request, and use the refresh token to obtain a new access token
                  when it expires. All API requests must be made over HTTPS.
                </p>

                <div className="bg-white rounded-xl border border-slate-200 p-6">
                  <h3 className="font-semibold text-slate-900 mb-3">Calling the API from JavaScript</h3>
                  <p className="text-slate-600 text-sm mb-3">
                    There are no official client libraries — call the REST API directly with fetch
                    or any HTTP client you already use.
                  </p>
                  <pre className="bg-slate-900 text-slate-100 rounded-lg p-4 text-sm overflow-x-auto">
                    <code>{`const res = await fetch(process.env.EVENTFLOW_API_URL + "/venues/", {
  headers: {
    Authorization: "Bearer " + process.env.EVENTFLOW_ACCESS_TOKEN,
    "Content-Type": "application/json",
  },
});

const data = await res.json();`}</code>
                  </pre>
                </div>
              </section>

              {/* Doc cards grid */}
              <section id="explore" className="mt-16">
                <h2 className="text-2xl font-bold text-slate-900 mb-6">Explore More</h2>
                <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
                  {docCards.map((card) => (
                    <a
                      key={card.title}
                      href={card.href}
                      className="bg-white rounded-xl border border-slate-200 p-6 hover:border-amber-500/40 hover:shadow-lg transition-all group"
                    >
                      <card.icon className={`w-8 h-8 ${card.color} mb-3`} aria-hidden="true" focusable="false" />
                      <h3 className="font-semibold text-slate-900 mb-1 group-hover:text-amber-600 transition-colors">
                        {card.title}
                      </h3>
                      <p className="text-sm text-slate-600">{card.desc}</p>
                    </a>
                  ))}
                </div>
              </section>
            </div>
          </div>
        </div>
      </section>

      <PageCTA
        title="Ready to build?"
        highlight="Start integrating today."
        description="Sign in to get your access token and start calling the EventFlow API."
        buttonText="Go to the API Reference"
        buttonHref="/api-reference"
      />
    </>
  )
}
