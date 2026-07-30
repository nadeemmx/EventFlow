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
    description: "We continuously push the boundaries of what's possible in venue management, leveraging cutting-edge technology to solve real-world problems for our customers.",
  },
  {
    title: "Reliability",
    description: "Our platform delivers 99.9% uptime and processes thousands of events daily. Venue owners trust us to keep their operations running smoothly without interruption.",
  },
  {
    title: "Customer Success",
    description: "Every feature we build is driven by customer feedback. Our dedicated success team works side by side with venue owners to ensure they get maximum value from EventFlow.",
  },
  {
    title: "Security",
    description: "We handle sensitive payment and customer data with the highest security standards. SOC 2 compliant with end-to-end encryption and regular third-party audits.",
  },
]

const team = [
  { name: "Arjun Mehta", role: "CEO & Co-Founder" },
  { name: "Priya Sharma", role: "CTO & Co-Founder" },
  { name: "Rahul Verma", role: "VP of Product" },
  { name: "Ananya Patel", role: "VP of Customer Success" },
  { name: "Vikram Joshi", role: "Head of Engineering" },
  { name: "Neha Kapoor", role: "Head of Marketing" },
]

export default function AboutPage() {
  return (
    <>
      <PageHero
        title="Our Mission to Transform"
        highlight="Event Venues"
        description="EventFlow was founded with a simple belief: venue owners deserve modern tools to manage, grow, and scale their business."
      />

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Our Story"
            description="From a garage startup to India's leading venue management platform"
          />
          <div className="mx-auto max-w-3xl space-y-6 text-slate-600 leading-relaxed">
            <p>
              EventFlow was founded in 2022 by Arjun Mehta and Priya Sharma, who experienced firsthand the chaos of managing event venues with spreadsheets and disconnected tools. After running a boutique venue in Bangalore, they realized the industry was starved for purpose-built technology.
            </p>
            <p>
              What started as a simple booking calendar quickly evolved into a full-stack platform covering lead management, invoicing, payment processing, CRM, and analytics. Today, EventFlow is headquartered in India with a team of 60+ employees serving over 500 venues across the country.
            </p>
            <p>
              Our platform has powered more than 50,000 events and processed over ₹100 crore in revenue for our customers. From wedding venues and banquet halls to corporate event spaces, EventFlow helps venue owners reclaim their time and grow their business.
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
                To empower every event venue owner with enterprise-grade technology that is simple to use, affordable to adopt, and powerful enough to transform their business operations.
              </p>
            </div>
            <div className="rounded-2xl border border-slate-200 bg-white p-8">
              <h3 className="text-xl font-bold text-slate-900 mb-3">Our Vision</h3>
              <p className="text-slate-600 leading-relaxed">
                A world where every event venue operates with complete confidence — where booking management, payments, and customer relationships are fully automated, leaving owners free to focus on creating unforgettable experiences.
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
            title="Meet the Team"
            description="The people building the future of venue management"
          />
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {team.map((member) => (
              <div
                key={member.name}
                className="rounded-2xl border border-slate-200 bg-white p-6 text-center"
              >
                <div className="mx-auto mb-4 h-16 w-16 rounded-full bg-gradient-to-br from-amber-400 to-amber-600 flex items-center justify-center text-white font-bold text-xl">
                  {member.name.split(" ").map((n) => n[0]).join("")}
                </div>
                <h3 className="text-lg font-bold text-slate-900">{member.name}</h3>
                <p className="text-sm text-slate-500">{member.role}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <PageCTA
        title="Ready to Transform Your Venue?"
        highlight="Start Free Trial"
        description="Join 500+ venues already using EventFlow to streamline operations and grow revenue."
      />
    </>
  )
}
