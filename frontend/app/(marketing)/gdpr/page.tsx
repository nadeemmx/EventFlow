import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import { Shield } from "lucide-react"

export const metadata = createMetadata({
  title: "GDPR Compliance",
  description: "EventFlow GDPR Compliance. Learn how we comply with the General Data Protection Regulation and protect your data rights.",
  path: "/gdpr",
})

const sections = [
  {
    title: "Data Controller",
    content:
      "EventFlow Inc. acts as the data controller for personal data collected through our platform. For data that our users (venue operators) input into the platform about their customers, EventFlow acts as a data processor. As a processor, we process personal data only on documented instructions from our users. Our registered address is 100 Innovation Drive, Suite 300, San Francisco, CA 94105, United States. Our representative in the European Union can be contacted at eu-rep@eventflow.com.",
  },
  {
    title: "Data We Process",
    content:
      "As a controller, we process account information (name, email, billing details), usage data (IP address, browser, pages visited), and communication data (support tickets, email correspondence). As a processor on behalf of our users, we process booking data including customer names, contact details, event preferences, payment information, and any other data our users choose to store in the platform. We process only the data necessary to provide our services and never use it for purposes unrelated to our platform.",
  },
  {
    title: "Legal Basis for Processing",
    content:
      "We process personal data under several legal bases as defined by Article 6 of the GDPR. Contractual necessity: processing required to provide our platform services and fulfill our agreement with users. Legitimate interests: processing for analytics, security, and product improvement where our interests do not override your fundamental rights. Consent: processing for marketing cookies and direct marketing communications, which you can withdraw at any time. Legal obligation: processing necessary to comply with applicable laws and regulations.",
  },
  {
    title: "Data Subject Rights",
    content:
      "Under the GDPR, you have the following rights: Right of access to your personal data (Article 15), right to rectification of inaccurate data (Article 16), right to erasure or to be forgotten (Article 17), right to restriction of processing (Article 18), right to data portability (Article 20), and right to object to processing (Article 21). To exercise any of these rights, please contact our DPO at dpo@eventflow.com. We will respond within 30 days. You also have the right to lodge a complaint with your local supervisory authority.",
  },
  {
    title: "International Data Transfers",
    content:
      "EventFlow primarily stores data on servers located in the United States and the European Union. When we transfer personal data from the EEA to the US, we rely on Standard Contractual Clauses (SCCs) adopted by the European Commission, supplemented by additional safeguards as required. We also maintain Data Processing Agreements (DPAs) with all sub-processors. For transfers to other third countries, we ensure appropriate safeguards are in place, including binding corporate rules or adequacy decisions where applicable.",
  },
  {
    title: "Data Breach Notification",
    content:
      "In the event of a personal data breach, EventFlow will notify affected data subjects and relevant supervisory authorities in accordance with Articles 33 and 34 of the GDPR. We will provide notice within 72 hours of becoming aware of the breach, including the nature of the breach, categories and approximate number of data subjects affected, likely consequences, and measures taken to address the breach. We maintain a comprehensive incident response plan and conduct regular security drills to ensure readiness.",
  },
  {
    title: "Data Protection Officer",
    content:
      "EventFlow has appointed a Data Protection Officer (DPO) to oversee our compliance with data protection laws. Our DPO can be reached at dpo@eventflow.com or by mail at EventFlow Inc., Attn: DPO, 100 Innovation Drive, Suite 300, San Francisco, CA 94105, United States. The DPO is responsible for monitoring our compliance, advising on data protection impact assessments, and acting as a point of contact for supervisory authorities and data subjects.",
  },
]

export default function GdprPage() {
  return (
    <>
      <PageHero
        title="GDPR Compliance"
        highlight=""
        description="EventFlow is committed to full compliance with the General Data Protection Regulation (GDPR). Learn how we protect your data."
      />

      <section className="py-16 bg-slate-50/50">
        <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
          <div className="flex items-center gap-3 mb-8 p-4 bg-amber-50 border border-amber-200 rounded-xl">
            <Shield className="w-6 h-6 text-amber-600 shrink-0" />
            <p className="text-sm text-amber-800">
              EventFlow is GDPR-compliant and committed to protecting the privacy and data rights of all individuals in the European Economic Area.
            </p>
          </div>

          <p className="text-slate-600 leading-relaxed mb-8">
            This page outlines how EventFlow complies with the General Data Protection Regulation
            and explains your rights regarding personal data we process. For more detailed information,
            please review our Privacy Policy.
          </p>

          <div className="space-y-10">
            {sections.map((section) => (
              <div key={section.title}>
                <h2 className="text-xl font-semibold text-slate-900 mb-3">{section.title}</h2>
                <p className="text-slate-600 leading-relaxed">{section.content}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <PageCTA
        title="Need to exercise your"
        highlight="GDPR rights?"
        description="Contact our Data Protection Officer for any requests regarding your personal data."
        buttonText="Contact DPO"
        buttonHref="mailto:dpo@eventflow.com"
      />
    </>
  )
}
