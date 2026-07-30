import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import SectionHeader from "@/components/marketing/SectionHeader"

export const metadata = createMetadata({
  title: "Customers",
  description: "See why 500+ venues trust EventFlow",
  path: "/case-studies",
})

const metrics = [
  { value: "500+", label: "Venues" },
  { value: "50,000+", label: "Events Managed" },
  { value: "99.9%", label: "Uptime" },
  { value: "₹100Cr+", label: "Revenue Processed" },
]

const caseStudies = [
  {
    venue: "The Grand Ballroom, Mumbai",
    owner: "Rajesh Khanna",
    quote: "EventFlow transformed our booking process entirely. We went from managing 15 events a month to over 40, without adding any additional staff.",
    challenges: "Manual booking system led to double-bookings and lost revenue. Spreadsheet-based invoicing caused payment delays of 45+ days. No centralized customer database made follow-ups nearly impossible.",
    results: ["3x increase in monthly events", "92% reduction in booking conflicts", "Payment collection time reduced from 45 to 7 days", "₹2.5Cr additional annual revenue"],
  },
  {
    venue: "Green Meadows Estate, Bangalore",
    owner: "Sunita Reddy",
    quote: "The automation features alone saved us 20 hours per week. We've finally stopped living in spreadsheets and started focusing on our guests.",
    challenges: "Spent 25+ hours weekly on manual scheduling and email follow-ups. Lead response time averaged 48 hours, losing potential bookings to competitors. No real-time visibility into venue availability.",
    results: ["20 hours saved per week on admin", "Lead response time under 5 minutes", "35% increase in lead-to-booking conversion", "98% occupancy rate during peak season"],
  },
  {
    venue: "Crystal Convention Centre, Delhi",
    owner: "Amit Gupta",
    quote: "The payment integration was a game-changer. We used to chase payments for weeks. Now 85% of our clients pay online before the event.",
    challenges: "Chasing payments consumed 40% of admin time. No online payment option led to last-minute cancellations. Manual invoicing created accounting errors monthly.",
    results: ["85% online payment adoption", "Zero accounting discrepancies", "60% reduction in no-shows", "₹1.8Cr additional processed revenue"],
  },
]

const testimonials = [
  {
    name: "Meera Iyer",
    role: "Owner, Serenity Banquets, Pune",
    content: "We evaluated six platforms before choosing EventFlow. Two years later, it remains the best decision we made for our business.",
  },
  {
    name: "Vivek Singh",
    role: "Manager, Royal Palace, Jaipur",
    content: "The CRM module alone pays for the subscription. We can finally track every lead and follow up at the right time.",
  },
  {
    name: "Deepa Nair",
    role: "Director, Seaside Events, Goa",
    content: "EventFlow's reporting gives us insights we never had before. We now make data-driven decisions about pricing and staffing.",
  },
  {
    name: "Karan Mehta",
    role: "CEO, Urban Spaces, Hyderabad",
    content: "Implementation was smooth and the support team was with us every step of the way. Truly a partnership, not just a vendor.",
  },
  {
    name: "Lakshmi Rajan",
    role: "Owner, Lotus Garden, Chennai",
    content: "My team was resistant to change, but EventFlow was so intuitive they were productive within a week. The onboarding is exceptional.",
  },
  {
    name: "Siddharth Chopra",
    role: "Partner, Platinum Halls, Chandigarh",
    content: "We scaled from one venue to three using EventFlow. The multi-venue management feature made expansion seamless.",
  },
]

const logos = [
  "The Grand Ballroom", "Green Meadows", "Crystal Convention", "Serenity Banquets",
  "Royal Palace", "Seaside Events", "Urban Spaces", "Lotus Garden",
  "Platinum Halls", "Silver Oak Resort", "Golden Tulip Gardens", "Emerald Bay Venues",
]

export default function CustomersPage() {
  return (
    <>
      <PageHero
        title="Trusted by 500+"
        highlight="Event Venues"
        description="See why venue owners across India rely on EventFlow to manage bookings, payments, and customer relationships."
      />

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 gap-8 sm:grid-cols-4">
            {metrics.map((metric) => (
              <div key={metric.label} className="text-center">
                <div className="text-4xl sm:text-5xl font-bold text-amber-500 mb-2">{metric.value}</div>
                <div className="text-sm text-slate-600 font-medium">{metric.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-slate-50/50 py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Customer Success Stories"
            description="Real venues, real results"
          />
          <div className="space-y-8">
            {caseStudies.map((cs) => (
              <div key={cs.venue} className="rounded-2xl border border-slate-200 bg-white overflow-hidden">
                <div className="p-8 sm:p-10">
                  <h3 className="text-xl font-bold text-slate-900 mb-1">{cs.venue}</h3>
                  <p className="text-sm text-slate-500 mb-6">— {cs.owner}</p>
                  <blockquote className="border-l-4 border-amber-500 pl-4 italic text-slate-600 mb-6">
                    &ldquo;{cs.quote}&rdquo;
                  </blockquote>
                  <div className="mb-6">
                    <h4 className="text-sm font-bold text-slate-900 uppercase tracking-wide mb-2">The Challenge</h4>
                    <p className="text-sm text-slate-600">{cs.challenges}</p>
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-slate-900 uppercase tracking-wide mb-3">Results</h4>
                    <ul className="space-y-2">
                      {cs.results.map((result) => (
                        <li key={result} className="flex items-center gap-2 text-sm text-slate-600">
                          <span className="h-1.5 w-1.5 rounded-full bg-amber-500 flex-shrink-0" />
                          {result}
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="What Our Customers Say"
            description="Hear directly from venue owners across India"
          />
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {testimonials.map((t) => (
              <div key={t.name} className="rounded-2xl border border-slate-200 bg-white p-6 flex flex-col">
                <p className="text-sm text-slate-600 leading-relaxed mb-6 flex-1">&ldquo;{t.content}&rdquo;</p>
                <div>
                  <div className="font-bold text-sm text-slate-900">{t.name}</div>
                  <div className="text-xs text-slate-500">{t.role}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-slate-50/50 py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Trusted by Leading Venues"
            description="Join the growing network of venues that power their business with EventFlow"
          />
          <div className="flex flex-wrap justify-center gap-x-12 gap-y-8">
            {logos.map((logo) => (
              <div
                key={logo}
                className="text-sm font-semibold text-slate-400 hover:text-slate-600 transition-colors tracking-wide"
              >
                {logo}
              </div>
            ))}
          </div>
        </div>
      </section>

      <PageCTA
        title="Join 500+ Venues Already Onboard"
        highlight="Get Started Today"
        description="Start your free trial — no credit card required. See why venue owners trust EventFlow."
      />
    </>
  )
}
