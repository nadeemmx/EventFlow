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
  Copy,
} from "lucide-react"

export const metadata = createMetadata({
  title: "Documentation",
  description: "Comprehensive documentation for the EventFlow API and platform. Get started with quick guides, integration tutorials, and API references.",
  path: "/docs",
})

const sidebarItems = [
  { category: "Getting Started", items: ["Quick Start", "Authentication", "API Basics"] },
  { category: "Authentication", items: ["API Keys", "OAuth 2.0", "SSO Setup"] },
  { category: "Bookings API", items: ["Create Booking", "Manage Bookings", "Availability"] },
  { category: "Payments API", items: ["Process Payment", "Refunds", "Invoicing"] },
  { category: "Webhooks", items: ["Overview", "Events", "Best Practices"] },
  { category: "Examples", items: ["React Integration", "Node.js SDK", "Python SDK"] },
]

const docCards = [
  {
    icon: BookOpen,
    title: "Authentication",
    desc: "Learn how to authenticate API requests using API keys or OAuth 2.0.",
    color: "text-amber-500",
  },
  {
    icon: CreditCard,
    title: "Payments API",
    desc: "Accept payments, process refunds, and manage invoices programmatically.",
    color: "text-emerald-500",
  },
  {
    icon: Webhook,
    title: "Webhooks",
    desc: "Receive real-time notifications for events like bookings, payments, and cancellations.",
    color: "text-blue-500",
  },
  {
    icon: Terminal,
    title: "SDK & Libraries",
    desc: "Official client libraries for Node.js, Python, Ruby, and more.",
    color: "text-purple-500",
  },
  {
    icon: Shield,
    title: "Security",
    desc: "Best practices for securing your EventFlow integration and protecting customer data.",
    color: "text-red-500",
  },
  {
    icon: BookOpen,
    title: "Migration Guide",
    desc: "Migrate from legacy systems to EventFlow with minimal downtime.",
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
              <nav className="sticky top-24 space-y-6">
                {sidebarItems.map((group) => (
                  <div key={group.category}>
                    <h4 className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">
                      {group.category}
                    </h4>
                    <ul className="space-y-1">
                      {group.items.map((item) => (
                        <li key={item}>
                          <a
                            href="#"
                            className="flex items-center gap-1 text-sm text-slate-600 hover:text-amber-600 transition-colors py-1"
                          >
                            <ChevronRight className="w-3 h-3 text-slate-400" />
                            {item}
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
                  Get up and running with EventFlow in minutes. This guide walks you through
                  creating your first booking programmatically.
                </p>

                <div className="space-y-6">
                  <div className="bg-white rounded-xl border border-slate-200 p-6">
                    <div className="flex items-center gap-3 mb-3">
                      <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-amber-500 text-white text-sm font-bold">1</span>
                      <h3 className="font-semibold text-slate-900">Get Your API Key</h3>
                    </div>
                    <p className="text-slate-600 text-sm mb-3">
                      Sign in to your EventFlow dashboard and navigate to Settings &rarr; API Keys.
                      Click &quot;Generate Key&quot; and copy your secret key. Store it securely.
                    </p>
                    <pre className="bg-slate-900 text-slate-100 rounded-lg p-4 text-sm overflow-x-auto">
                      <code>{`export EVENTFLOW_API_KEY="sk_live_your_secret_key_here"`}</code>
                    </pre>
                  </div>

                  <div className="bg-white rounded-xl border border-slate-200 p-6">
                    <div className="flex items-center gap-3 mb-3">
                      <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-amber-500 text-white text-sm font-bold">2</span>
                      <h3 className="font-semibold text-slate-900">Make Your First API Call</h3>
                    </div>
                    <p className="text-slate-600 text-sm mb-3">
                      Verify your integration by fetching available venues. You can use curl or any HTTP client.
                    </p>
                    <pre className="bg-slate-900 text-slate-100 rounded-lg p-4 text-sm overflow-x-auto">
                      <code>{`curl https://api.eventflow.com/v1/venues \\
  -H "Authorization: Bearer $EVENTFLOW_API_KEY" \\
  -H "Content-Type: application/json"`}</code>
                    </pre>
                  </div>

                  <div className="bg-white rounded-xl border border-slate-200 p-6">
                    <div className="flex items-center gap-3 mb-3">
                      <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-amber-500 text-white text-sm font-bold">3</span>
                      <h3 className="font-semibold text-slate-900">Create a Booking</h3>
                    </div>
                    <p className="text-slate-600 text-sm mb-3">
                      Submit a booking request with event details, date, and customer information.
                    </p>
                    <pre className="bg-slate-900 text-slate-100 rounded-lg p-4 text-sm overflow-x-auto">
                      <code>{`curl -X POST https://api.eventflow.com/v1/bookings \\
  -H "Authorization: Bearer $EVENTFLOW_API_KEY" \\
  -H "Content-Type: application/json" \\
  -d '{
  "venue_id": "v_abc123",
  "event_name": "Annual Gala",
  "date": "2026-12-15",
  "start_time": "18:00",
  "end_time": "23:00",
  "guest_count": 250,
  "customer": {
    "name": "Jane Smith",
    "email": "jane@example.com",
    "phone": "+1-555-123-4567"
  }
}'`}</code>
                    </pre>
                  </div>
                </div>
              </section>

              <section id="authentication" className="mt-12">
                <h2 className="text-2xl font-bold text-slate-900 mb-6">Authentication</h2>
                <p className="text-slate-600 mb-6 leading-relaxed">
                  EventFlow uses API keys for authentication. Include your secret key in the
                  <code className="mx-1 px-2 py-0.5 bg-slate-100 text-slate-800 rounded text-sm">Authorization</code>
                  header of every request. All API requests must be made over HTTPS.
                </p>

                <div className="bg-white rounded-xl border border-slate-200 p-6">
                  <h3 className="font-semibold text-slate-900 mb-3">Using API Keys</h3>
                  <pre className="bg-slate-900 text-slate-100 rounded-lg p-4 text-sm overflow-x-auto">
                    <code>{`// Node.js example
const eventflow = require('@eventflow/sdk');

const client = new eventflow.Client({
  apiKey: process.env.EVENTFLOW_API_KEY,
});

async function createBooking() {
  const booking = await client.bookings.create({
    venueId: 'v_abc123',
    eventName: 'Corporate Summit',
    date: '2026-12-15',
  });
  console.log(booking);
}`}</code>
                  </pre>
                </div>
              </section>

              {/* Doc cards grid */}
              <section className="mt-16">
                <h2 className="text-2xl font-bold text-slate-900 mb-6">Explore More</h2>
                <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
                  {docCards.map((card) => (
                    <a
                      key={card.title}
                      href="#"
                      className="bg-white rounded-xl border border-slate-200 p-6 hover:border-amber-500/40 hover:shadow-lg transition-all group"
                    >
                      <card.icon className={`w-8 h-8 ${card.color} mb-3`} />
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
        description="Get your API keys and join thousands of venues already using EventFlow."
        buttonText="Get API Keys"
        buttonHref="/login"
      />
    </>
  )
}
