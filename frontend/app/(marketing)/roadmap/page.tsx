import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import { Lightbulb, Sparkles, Globe, CreditCard, Smartphone, BarChart3, Building2, ShoppingBag, PanelRightOpen } from "lucide-react"

export const metadata = createMetadata({
  title: "Product Roadmap",
  description: "Explore the EventFlow product roadmap. See what we are building now, next, and in the future to power event venues worldwide.",
  path: "/roadmap",
})

const phases = [
  {
    title: "Now",
    subtitle: "Current Quarter",
    color: "bg-amber-500",
    textColor: "text-amber-500",
    description: "What we are actively building and shipping right now.",
    items: [
      {
        icon: Smartphone,
        title: "Mobile App",
        desc: "Native iOS and Android apps for venue managers to accept bookings, manage calendars, and process payments on the go.",
        status: "In Progress",
        statusColor: "bg-amber-100 text-amber-700",
      },
      {
        icon: BarChart3,
        title: "SMS Notifications",
        desc: "Automated SMS reminders, confirmations, and updates for both venue staff and customers. Includes two-way messaging.",
        status: "In Progress",
        statusColor: "bg-amber-100 text-amber-700",
      },
      {
        icon: PanelRightOpen,
        title: "Advanced Reporting",
        desc: "Customizable dashboards with revenue analytics, booking trends, occupancy rates, and exportable PDF/CSV reports.",
        status: "In Progress",
        statusColor: "bg-amber-100 text-amber-700",
      },
    ],
  },
  {
    title: "Next",
    subtitle: "Next Quarter",
    color: "bg-blue-500",
    textColor: "text-blue-500",
    description: "What we are designing and will begin building soon.",
    items: [
      {
        icon: Sparkles,
        title: "AI-Powered Insights",
        desc: "Predictive analytics for optimal pricing, demand forecasting, and personalized venue recommendations powered by machine learning.",
        status: "Planned",
        statusColor: "bg-blue-100 text-blue-700",
      },
      {
        icon: Globe,
        title: "Multi-Language Support",
        desc: "Localized interface and customer-facing booking pages in 12+ languages including Spanish, French, German, Japanese, and Portuguese.",
        status: "Planned",
        statusColor: "bg-blue-100 text-blue-700",
      },
      {
        icon: CreditCard,
        title: "Payment Gateway Expansion",
        desc: "Additional payment gateway integrations including Stripe, Square, PayPal, and regional providers like Mercado Pago and Alipay.",
        status: "Planned",
        statusColor: "bg-blue-100 text-blue-700",
      },
    ],
  },
  {
    title: "Future",
    subtitle: "Under Exploration",
    color: "bg-purple-500",
    textColor: "text-purple-500",
    description: "Long-term ideas we are researching and may build in the future.",
    items: [
      {
        icon: Building2,
        title: "Virtual Venue Tours",
        desc: "Immersive 360-degree virtual tours embedded in venue listings, allowing customers to explore spaces remotely before booking.",
        status: "Under Consideration",
        statusColor: "bg-purple-100 text-purple-700",
      },
      {
        icon: ShoppingBag,
        title: "Marketplace",
        desc: "A public marketplace where event planners can discover and book venues directly, with integrated reviews and ratings.",
        status: "Under Consideration",
        statusColor: "bg-purple-100 text-purple-700",
      },
      {
        icon: Globe,
        title: "White-Label Solution",
        desc: "Fully customizable white-label platform for large venue groups to rebrand EventFlow as their own booking system.",
        status: "Under Consideration",
        statusColor: "bg-purple-100 text-purple-700",
      },
    ],
  },
]

export default function RoadmapPage() {
  return (
    <>
      <PageHero
        title="Product Roadmap"
        highlight=""
        description="See what we are building, what is coming next, and what is on the horizon for EventFlow."
      />

      {/* Timeline visual */}
      <section className="py-16 bg-slate-50/50">
        <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
          <div className="relative flex items-center justify-between mb-12">
            <div className="absolute left-0 right-0 top-1/2 h-0.5 bg-slate-200 -translate-y-1/2" />
            {["Now", "Next", "Future"].map((label, i) => (
              <div key={label} className="relative flex flex-col items-center">
                <div className={`w-6 h-6 rounded-full ${phases[i].color} flex items-center justify-center mb-2`}>
                  <div className="w-2 h-2 rounded-full bg-white" />
                </div>
                <span className="text-sm font-semibold text-slate-900">{label}</span>
                <span className="text-xs text-slate-500">{phases[i].subtitle}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Phase sections */}
      {phases.map((phase) => (
        <section key={phase.title} className="py-16 even:bg-slate-50/50">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="text-center mb-12">
              <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold ${phase.color} text-white mb-3`}>
                {phase.subtitle}
              </span>
              <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
                {phase.title}
              </h2>
              <p className="mt-3 text-slate-600 max-w-xl mx-auto">{phase.description}</p>
            </div>

            <div className="grid md:grid-cols-3 gap-6">
              {phase.items.map((item) => (
                <div key={item.title} className="bg-white rounded-xl border border-slate-200 p-6 hover:border-amber-500/40 hover:shadow-lg transition-all">
                  <item.icon className={`w-8 h-8 ${phase.textColor} mb-3`} />
                  <div className="flex items-start justify-between gap-2 mb-2">
                    <h3 className="font-semibold text-slate-900">{item.title}</h3>
                    <span className={`shrink-0 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${item.statusColor}`}>
                      {item.status}
                    </span>
                  </div>
                  <p className="text-sm text-slate-600 leading-relaxed">{item.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>
      ))}

      {/* Feature request CTA */}
      <section className="py-20">
        <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 text-center">
          <Lightbulb className="w-12 h-12 text-amber-500 mx-auto mb-4" />
          <h2 className="text-3xl font-bold text-slate-900 mb-2">Have an idea?</h2>
          <p className="text-slate-600 mb-8 max-w-lg mx-auto">
            We love hearing from our users. Share your feature requests and help shape the future of EventFlow.
          </p>
          <a
            href="#"
            className="inline-flex items-center gap-2 rounded-xl bg-amber-500 px-7 py-3.5 text-base font-semibold text-slate-900 hover:bg-amber-600 transition-all"
          >
            Submit a Feature Request
          </a>
        </div>
      </section>

      <PageCTA
        title="Start using what we"
        highlight="built today."
        description="Get early access to new features and help us prioritize what comes next."
        buttonText="Start Free Trial"
        buttonHref="/login"
      />
    </>
  )
}
