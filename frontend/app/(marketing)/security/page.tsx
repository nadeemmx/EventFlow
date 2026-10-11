import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import SectionHeader from "@/components/marketing/SectionHeader"

export const metadata = createMetadata({
  title: "Security",
  description: "How EventFlow protects your venue data — encryption, access control, and our current certification status.",
  path: "/security",
})

const sections = [
  {
    title: "Data Encryption",
    description:
      "Sensitive credentials — payment gateway keys, webhook secrets, SMTP passwords, and WhatsApp API keys — are encrypted at rest with AES-256-GCM using a key supplied through the environment. Traffic between your browser and EventFlow is served over HTTPS/TLS.",
  },
  {
    title: "Authentication & Sessions",
    description:
      "Sign-in uses JSON Web Tokens: a short-lived access token plus a refresh token that can be revoked on logout. Passwords are stored hashed, and login, password reset, and token refresh endpoints are rate limited.",
  },
  {
    title: "Access Control",
    description:
      "Role-based access control restricts each module — bookings, finance, leads, staff, settings — to the roles that need it. Audit logs record the user, module, action, previous and new values, IP address, and timestamp for changes made in the app.",
  },
  {
    title: "API Protection",
    description:
      "API requests are throttled (authenticated users are limited to 1,000 requests per hour, and sign-in attempts to 5 per minute) to slow down abuse and credential stuffing. Requests must be authenticated to reach tenant data.",
  },
  {
    title: "Compliance Status",
    description:
      "SOC 2 certification is in progress and has not been obtained yet — we do not claim SOC 2 compliance today. We also do not hold ISO 27001 or any other third-party certification at this time.",
  },
  {
    title: "Independent Testing",
    description:
      "No third-party penetration test has been commissioned or completed yet. We review our own code and dependencies, and we will publish the results here if and when an external assessment is carried out.",
  },
]

const badges = [
  { label: "AES-256-GCM", sub: "Credential encryption" },
  { label: "JWT Sessions", sub: "Access & refresh tokens" },
  { label: "HTTPS/TLS", sub: "Data in transit" },
  { label: "Role-Based Access", sub: "Module permissions" },
  { label: "Audit Logs", sub: "User activity records" },
  { label: "SOC 2 Type II", sub: "In progress — not certified" },
]

const standing = [
  {
    label: "SOC 2 Type II",
    value: "In progress",
    note: "Certification has not been obtained.",
  },
  {
    label: "Penetration Testing",
    value: "Not yet done",
    note: "No external pen test has been completed.",
  },
  {
    label: "Public Uptime Stats",
    value: "Not published",
    note: "We do not report uptime or customer counts.",
  },
]

export default function SecurityPage() {
  return (
    <>
      <PageHero
        title="Security at"
        highlight="EventFlow"
        description="Your venue's data deserves careful handling. Here is exactly what we have in place — and what we have not done yet."
      />

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="mb-16">
            <SectionHeader
              title="How We"
              highlight="Protect Your Data"
              description="Every layer of the EventFlow stack, described as it actually is today."
            />
          </div>
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {sections.map((section) => (
              <div
                key={section.title}
                className="rounded-xl border border-slate-200 bg-white p-6 transition-all hover:-translate-y-1 hover:shadow-lg hover:shadow-amber-500/10"
              >
                <h3 className="text-base font-semibold text-slate-900 mb-2">{section.title}</h3>
                <p className="text-sm text-slate-600 leading-relaxed">{section.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="py-20 bg-slate-50/50">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Security Controls &"
            highlight="Certification Status"
            description="We believe in transparency. Here are the controls we run and the certification we are still working towards."
          />
          <div className="flex flex-wrap justify-center gap-4">
            {badges.map((badge) => (
              <div
                key={badge.label}
                className="flex flex-col items-center rounded-xl border border-slate-200 bg-white px-8 py-6 text-center min-w-[160px]"
              >
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-amber-50 text-amber-600 mb-3">
                  <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor" aria-hidden="true" focusable="false">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
                  </svg>
                </div>
                <span className="text-sm font-semibold text-slate-900">{badge.label}</span>
                <span className="text-xs text-slate-500 mt-0.5">{badge.sub}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Where We"
            highlight="Actually Stand"
            description="No certifications, test results, or statistics that we cannot show you."
          />
          <div className="grid gap-8 md:grid-cols-3">
            {standing.map((item) => (
              <div key={item.label} className="rounded-xl border border-slate-200 bg-white p-6 text-center">
                <p className="text-sm font-semibold text-slate-900">{item.label}</p>
                <p className="text-2xl font-bold text-amber-700 mt-2">{item.value}</p>
                <p className="text-sm text-slate-600 mt-2">{item.note}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <PageCTA
        title="Your Data Safety Matters"
        highlight="Talk to Us About Security"
        description="Have questions about our security practices? We will walk you through what is in place today."
        buttonText="Contact Us"
        buttonHref="/contact"
      />
    </>
  )
}
