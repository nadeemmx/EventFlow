import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import SectionHeader from "@/components/marketing/SectionHeader"

export const metadata = createMetadata({
  title: "Security",
  description: "Enterprise-grade security for your event venue data. SOC 2 compliant, encrypted at rest and in transit.",
  path: "/security",
})

const sections = [
  {
    title: "Data Encryption",
    description:
      "All data is encrypted at rest using AES-256 with regularly rotated keys. Data in transit is protected by TLS 1.3 with strong cipher suites. Customer data is segmented at the storage layer with tenant-level encryption keys available on the Enterprise plan.",
  },
  {
    title: "Infrastructure Security",
    description:
      "EventFlow runs on AWS in the ap-south-1 region with multi-AZ redundancy. All EC2 instances sit in private subnets with no direct internet exposure. We use WAF rules to block OWASP Top 10 threats, DDoS protection via AWS Shield, and automated vulnerability scanning every 24 hours.",
  },
  {
    title: "Compliance & Certifications",
    description:
      "We are SOC 2 Type II compliant with annual audits by an independent firm. Our security controls cover the Trust Services Criteria for security, availability, and confidentiality. We also comply with India's IT Act 2000 and upcoming DPDP Act requirements for handling personal data.",
  },
  {
    title: "Access Control",
    description:
      "Role-based access control with granular permissions per module. Multi-factor authentication enforced for all admin accounts. Session management with automatic timeout after 30 minutes of inactivity. Audit logs capture every action with user ID, timestamp, IP address, and the exact change made.",
  },
  {
    title: "Backup & Disaster Recovery",
    description:
      "Automated hourly backups of the database with 30-day retention. Full daily backups stored in a separate AWS region for geo-redundancy. Recovery Point Objective (RPO) of under 1 hour and Recovery Time Objective (RTO) of under 4 hours. Monthly disaster recovery drills are conducted and documented.",
  },
  {
    title: "Monitoring & Incident Response",
    description:
      "Real-time monitoring with SIEM integration for threat detection. Anomaly alerts trigger automated remediation where possible. We have a documented incident response plan with defined severity levels, escalation matrices, and SLA-backed resolution times. Post-incident reviews are conducted within 72 hours.",
  },
]

const badges = [
  { label: "SOC 2 Type II", sub: "Certified annually" },
  { label: "AES-256 Encryption", sub: "At rest & in transit" },
  { label: "ISO 27001", sub: "In progress" },
  { label: "TLS 1.3", sub: "All connections" },
  { label: "GDPR Ready", sub: "Data processing" },
  { label: "DPDP Compliant", sub: "India data law" },
]

export default function SecurityPage() {
  return (
    <>
      <PageHero
        title="Enterprise-Grade"
        highlight="Security"
        description="Your venue's data deserves the same protection as a bank. EventFlow is built with security at every layer — from encryption to access control to compliance."
      />

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="mb-16">
            <SectionHeader
              title="How We"
              highlight="Protect Your Data"
              description="Every layer of the EventFlow stack is designed with security best practices."
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
            title="Security Badges &"
            highlight="Certifications"
            description="We believe in transparency. Here are the standards we meet and the ones we are working towards."
          />
          <div className="flex flex-wrap justify-center gap-4">
            {badges.map((badge) => (
              <div
                key={badge.label}
                className="flex flex-col items-center rounded-xl border border-slate-200 bg-white px-8 py-6 text-center min-w-[160px]"
              >
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-amber-50 text-amber-600 mb-3">
                  <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
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
            title="Trusted by"
            highlight="Hundreds of Venues"
            description="EventFlow is the platform of choice for venue operators who take data security seriously."
          />
          <div className="grid gap-8 md:grid-cols-3">
            <div className="rounded-xl border border-slate-200 bg-white p-6 text-center">
              <p className="text-3xl font-bold text-amber-500">400+</p>
              <p className="text-sm text-slate-600 mt-1">Venues trust EventFlow</p>
            </div>
            <div className="rounded-xl border border-slate-200 bg-white p-6 text-center">
              <p className="text-3xl font-bold text-amber-500">99.95%</p>
              <p className="text-sm text-slate-600 mt-1">Platform uptime (12-month avg)</p>
            </div>
            <div className="rounded-xl border border-slate-200 bg-white p-6 text-center">
              <p className="text-3xl font-bold text-amber-500">&lt; 4 hrs</p>
              <p className="text-sm text-slate-600 mt-1">RTO for disaster recovery</p>
            </div>
          </div>
        </div>
      </section>

      <PageCTA
        title="Your Data Safety Matters"
        highlight="Talk to Our Security Team"
        description="Have questions about our security practices? We would love to walk you through our architecture."
        buttonText="Contact Security Team"
        buttonHref="/contact"
      />
    </>
  )
}
