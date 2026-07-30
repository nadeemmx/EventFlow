import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import SectionHeader from "@/components/marketing/SectionHeader"

export const metadata = createMetadata({
  title: "Careers",
  description: "Join EventFlow and help transform the event venue industry",
  path: "/careers",
})

const benefits = [
  "Competitive Health Insurance covering you and your family",
  "Equity ownership — you are a part-owner of the company",
  "Remote-first culture with flexible working hours",
  "Annual learning budget of ₹1,00,000 for courses, conferences, and books",
  "Home office setup stipend of ₹75,000",
  "30 days paid annual leave plus public holidays",
  "Quarterly team retreats at amazing venues across India",
  "Annual wellness allowance for gym, yoga, or mental health support",
]

const positions = [
  {
    title: "Senior Software Engineer",
    location: "Remote — India",
    type: "Full-time",
    department: "Engineering",
    description: "Build and scale the platform that powers hundreds of venues. You will own critical backend services, design APIs, and mentor junior engineers.",
    requirements: [
      "5+ years of experience in full-stack development",
      "Strong proficiency in TypeScript, React, and Node.js",
      "Experience with PostgreSQL and cloud infrastructure (AWS/GCP)",
      "Track record of building and shipping production-grade features",
      "Excellent problem-solving and communication skills",
    ],
  },
  {
    title: "Product Manager",
    location: "Remote — India",
    type: "Full-time",
    department: "Product",
    description: "Define and execute the product roadmap for our core platform. You will work closely with customers, engineering, and design to ship features that delight venue owners.",
    requirements: [
      "4+ years of product management experience in B2B SaaS",
      "Strong analytical skills and data-driven decision making",
      "Experience conducting user research and customer interviews",
      "Excellent written and verbal communication skills",
      "Technical background or ability to understand complex systems",
    ],
  },
  {
    title: "Customer Success Manager",
    location: "Remote — India",
    type: "Full-time",
    department: "Success",
    description: "Ensure our customers achieve their goals with EventFlow. You will onboard new venues, drive adoption, and be the voice of the customer internally.",
    requirements: [
      "3+ years in customer success or account management",
      "Experience with B2B SaaS onboarding and training",
      "Strong empathy and communication skills",
      "Ability to analyse usage data and drive engagement",
      "Familiarity with CRM and support tools",
    ],
  },
  {
    title: "Sales Development Representative",
    location: "Remote — India",
    type: "Full-time",
    department: "Sales",
    description: "Drive the top of our sales funnel by engaging with venue owners, qualifying leads, and setting up demos for our sales team.",
    requirements: [
      "2+ years of sales or lead generation experience",
      "Excellent phone and email communication skills",
      "Comfortable using CRM tools and sales engagement platforms",
      "Self-starter with a track record of hitting targets",
      "Passion for the event industry is a plus",
    ],
  },
]

export default function CareersPage() {
  return (
    <>
      <PageHero
        title="Join Us in Transforming"
        highlight="Event Venues"
        description="Build the future of venue management with a passionate, remote-first team backed by strong product-market fit."
      />

      <section className="bg-slate-50/50 py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Our Culture"
            description="How we work and what we value"
          />
          <div className="mx-auto max-w-3xl grid gap-6 sm:grid-cols-3">
            <div className="rounded-2xl border border-slate-200 bg-white p-6 text-center">
              <div className="mb-3 text-3xl">🌍</div>
              <h3 className="text-lg font-bold text-slate-900 mb-2">Remote-First</h3>
              <p className="text-sm text-slate-600">Work from wherever you are most productive. We hire the best talent across India, no matter the location.</p>
            </div>
            <div className="rounded-2xl border border-slate-200 bg-white p-6 text-center">
              <div className="mb-3 text-3xl">📈</div>
              <h3 className="text-lg font-bold text-slate-900 mb-2">Growth Mindset</h3>
              <p className="text-sm text-slate-600">We invest in your professional development with learning budgets, mentorship, and challenging projects.</p>
            </div>
            <div className="rounded-2xl border border-slate-200 bg-white p-6 text-center">
              <div className="mb-3 text-3xl">💡</div>
              <h3 className="text-lg font-bold text-slate-900 mb-2">Innovation</h3>
              <p className="text-sm text-slate-600">Every team member drives impact. We ship fast, learn from feedback, and continuously improve our platform.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Benefits & Perks"
            description="We take care of our team so they can do their best work"
          />
          <div className="mx-auto max-w-3xl grid gap-4 sm:grid-cols-2">
            {benefits.map((benefit) => (
              <div key={benefit} className="flex items-start gap-3">
                <span className="mt-1 h-2 w-2 rounded-full bg-amber-500 flex-shrink-0" />
                <span className="text-sm text-slate-700">{benefit}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-slate-50/50 py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Open Positions"
            description="Join a rapidly growing team building the leading venue management platform"
          />
          <div className="space-y-6">
            {positions.map((position) => (
              <div key={position.title} className="rounded-2xl border border-slate-200 bg-white overflow-hidden">
                <div className="p-8">
                  <div className="flex flex-wrap items-start justify-between gap-4 mb-4">
                    <div>
                      <h3 className="text-xl font-bold text-slate-900">{position.title}</h3>
                      <p className="text-sm text-slate-500">{position.department} · {position.location} · {position.type}</p>
                    </div>
                    <span className="inline-block rounded-full bg-amber-500/10 px-3 py-1 text-xs font-semibold text-amber-700">
                      {position.department}
                    </span>
                  </div>
                  <p className="text-sm text-slate-600 mb-4">{position.description}</p>
                  <div>
                    <h4 className="text-sm font-bold text-slate-900 mb-2">Requirements</h4>
                    <ul className="space-y-1.5">
                      {position.requirements.map((req) => (
                        <li key={req} className="flex items-start gap-2 text-sm text-slate-600">
                          <span className="mt-1.5 h-1.5 w-1.5 rounded-full bg-amber-500 flex-shrink-0" />
                          {req}
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
        <div className="mx-auto max-w-2xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Apply Now"
            description="Send us your details and we will get back to you within 5 business days"
          />
          <form className="space-y-5" action="#">
            <div className="grid gap-5 sm:grid-cols-2">
              <div>
                <label htmlFor="name" className="block text-sm font-medium text-slate-900 mb-1.5">Full Name</label>
                <input
                  id="name"
                  type="text"
                  className="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-500/30 focus:border-amber-500"
                  placeholder="Your full name"
                />
              </div>
              <div>
                <label htmlFor="email" className="block text-sm font-medium text-slate-900 mb-1.5">Email</label>
                <input
                  id="email"
                  type="email"
                  className="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-500/30 focus:border-amber-500"
                  placeholder="you@example.com"
                />
              </div>
            </div>
            <div>
              <label htmlFor="role" className="block text-sm font-medium text-slate-900 mb-1.5">Role</label>
              <select
                id="role"
                className="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-500/30 focus:border-amber-500"
              >
                <option value="">Select a position</option>
                {positions.map((p) => (
                  <option key={p.title} value={p.title}>{p.title}</option>
                ))}
              </select>
            </div>
            <div>
              <label htmlFor="resume" className="block text-sm font-medium text-slate-900 mb-1.5">Resume / CV</label>
              <div className="rounded-xl border border-dashed border-slate-200 bg-white px-4 py-8 text-center">
                <p className="text-sm text-slate-400">Drop your resume here or click to browse</p>
                <input id="resume" type="file" className="hidden" />
              </div>
            </div>
            <button
              type="button"
              className="w-full rounded-xl bg-amber-500 px-6 py-3 text-sm font-semibold text-slate-900 hover:bg-amber-600 transition-all"
            >
              Submit Application
            </button>
          </form>
        </div>
      </section>

      <PageCTA
        title="Want to Know More?"
        highlight="Talk to Our Team"
        description="Not seeing the right role? Reach out anyway — we are always looking for great talent."
        buttonText="Get in Touch"
      />
    </>
  )
}
