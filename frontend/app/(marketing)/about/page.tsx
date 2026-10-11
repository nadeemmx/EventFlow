import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import SectionHeader from "@/components/marketing/SectionHeader"

export const metadata = createMetadata({
  title: "About Us",
  description: "Learn about EventFlow's mission to transform event venue management",
  path: "/about",
})

const values = [
  {
    title: "Innovation",
    description: "We keep improving the platform for the day-to-day realities of venue management, and we solve the problems our customers actually report.",
  },
  {
    title: "Reliability",
    description: "Venue operations cannot wait for a fix. We build for steady, predictable performance and we publish incidents on our status page as they happen.",
  },
  {
    title: "Customer Success",
    description: "Every feature we build is driven by customer feedback. We work alongside venue owners to make sure the product fits how they actually run their business.",
  },
  {
    title: "Security",
    description: "We handle sensitive payment and customer data carefully: gateway credentials are encrypted at rest, sessions are token-based, and access is role-scoped. Our SOC 2 certification is in progress — we do not claim to hold it yet.",
  },
]

const teamAreas = [
  {
    title: "Product & Engineering",
    description: "Build and maintain the booking, invoicing, payment, and reporting modules that venue teams use every day.",
  },
  {
    title: "Customer & Support",
    description: "Onboard venue teams, answer questions, and feed real customer problems back into the roadmap.",
  },
  {
    title: "Operations & Growth",
    description: "Keep the business running — billing, partnerships, and the day-to-day work behind the product.",
  },
]

export default function AboutPage() {
  return (
    <>
      <PageHero
        title="Our Mission to Transform"
        highlight="Event Venues"
        description="EventFlow was built on a simple belief: venue owners deserve modern tools to manage, grow, and scale their business."
      />

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Our Story"
            description="Why we build EventFlow"
          />
          <div className="mx-auto max-w-3xl space-y-6 text-slate-600 leading-relaxed">
            <p>
              EventFlow started because managing an event venue with spreadsheets and disconnected
              tools does not work. Bookings, leads, invoices, payments, staff, and vendors live in
              different places, and venue teams end up doing the same work twice.
            </p>
            <p>
              What began as a booking calendar grew into a full platform covering lead management,
              invoicing, payment processing, CRM, and analytics — designed specifically for event
              venues rather than adapted from generic software.
            </p>
            <p>
              Today EventFlow helps venue businesses of every size run bookings, take payments
              through Razorpay, send invoices by email and WhatsApp, and keep their customer records
              in one place. We are a small team, and we would rather tell you exactly what the
              product does than make claims we cannot back up.
            </p>
          </div>
        </div>
      </section>

      <section className="bg-slate-50/50 py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Mission & Vision"
            description="What drives us every day"
          />
          <div className="mx-auto max-w-3xl space-y-8">
            <div className="rounded-2xl border border-slate-200 bg-white p-8">
              <h3 className="text-xl font-bold text-slate-900 mb-3">Our Mission</h3>
              <p className="text-slate-600 leading-relaxed">
                To empower every event venue owner with technology that is simple to use, affordable
                to adopt, and powerful enough to transform their business operations.
              </p>
            </div>
            <div className="rounded-2xl border border-slate-200 bg-white p-8">
              <h3 className="text-xl font-bold text-slate-900 mb-3">Our Vision</h3>
              <p className="text-slate-600 leading-relaxed">
                A world where every event venue operates with confidence — where booking management,
                payments, and customer relationships are handled in one place, leaving owners free to
                focus on creating unforgettable experiences.
              </p>
            </div>
          </div>
        </div>
      </section>

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Our Values"
            description="The principles that guide every decision we make"
          />
          <div className="grid gap-6 sm:grid-cols-2">
            {values.map((value) => (
              <div
                key={value.title}
                className="rounded-2xl border border-slate-200 bg-white p-8"
              >
                <div className="mb-3 h-10 w-10 rounded-lg bg-amber-500/10 flex items-center justify-center text-amber-600 font-bold text-lg">
                  {value.title[0]}
                </div>
                <h3 className="text-lg font-bold text-slate-900 mb-2">{value.title}</h3>
                <p className="text-sm text-slate-600 leading-relaxed">{value.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-slate-50/50 py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="How We Work"
            description="The areas that keep EventFlow running"
          />
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {teamAreas.map((area) => (
              <div
                key={area.title}
                className="rounded-2xl border border-slate-200 bg-white p-6"
              >
                <div className="mb-4 h-12 w-12 rounded-full bg-gradient-to-br from-amber-500 to-amber-700 flex items-center justify-center text-white font-bold text-lg">
                  EF
                </div>
                <h3 className="text-lg font-bold text-slate-900">{area.title}</h3>
                <p className="text-sm text-slate-500 leading-relaxed mt-1">{area.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <PageCTA
        title="Ready to Transform Your Venue?"
        highlight="Start Free"
        description="Create an account, put bookings, invoices, and payments in one place, and see how EventFlow fits your venue."
      />
    </>
  )
}
