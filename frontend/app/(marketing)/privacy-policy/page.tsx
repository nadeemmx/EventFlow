import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"

export const metadata = createMetadata({
  title: "Privacy Policy",
  description: "EventFlow Privacy Policy. Learn how we collect, use, and protect your personal data when you use our venue management platform.",
  path: "/privacy-policy",
})

const sections = [
  {
    title: "Information We Collect",
    content:
      "We collect information you provide directly when creating an account, making a booking, or contacting support. This includes your name, email address, phone number, billing address, and payment information. When you use our platform, we automatically collect certain technical data such as IP address, browser type, device information, and usage patterns through cookies and similar technologies. For venue operators, we may also collect venue details, event schedules, pricing information, and customer data you input into our system.",
  },
  {
    title: "How We Use Information",
    content:
      "We use the information we collect to operate, maintain, and improve our platform. This includes processing bookings and payments, sending transactional emails and notifications, providing customer support, analyzing platform usage to enhance features, and communicating product updates. We may also use aggregated, anonymized data for analytics and product development. We do not sell your personal information to third parties.",
  },
  {
    title: "Data Sharing",
    content:
      "We share your information only with trusted service providers who help us operate our platform, including payment processors, cloud infrastructure providers, email delivery services, and analytics providers. These third parties are contractually bound to protect your data and use it solely for the services they provide. We may disclose information if required by law, to protect our rights, or in connection with a business transaction such as a merger or acquisition.",
  },
  {
    title: "Data Security",
    content:
      "EventFlow implements industry-standard security measures to protect your data. All data transmitted between your browser and our servers is encrypted using TLS 1.3. Data at rest is encrypted using AES-256. We conduct regular security audits, penetration testing, and maintain SOC 2 compliance. Access to production systems is restricted to authorized personnel and logged for audit purposes. Despite our efforts, no method of electronic storage is 100% secure, and we cannot guarantee absolute security.",
  },
  {
    title: "Your Rights",
    content:
      "Depending on your jurisdiction, you may have the right to access, correct, delete, or port your personal data. You may also have the right to restrict or object to certain processing activities. To exercise these rights, please contact our Data Protection Officer at dpo@eventflow.com. We will respond to your request within 30 days. You also have the right to lodge a complaint with your local data protection authority.",
  },
  {
    title: "Cookies",
    content:
      "We use cookies and similar tracking technologies to enhance your experience, analyze platform usage, and deliver relevant communications. Essential cookies are required for the platform to function. Analytics cookies help us understand how you interact with our platform. Marketing cookies are used to deliver personalized advertisements. You can manage your cookie preferences at any time through your account settings or browser controls. For more details, see our Cookie Policy.",
  },
  {
    title: "Contact",
    content:
      "If you have questions about this Privacy Policy or our data practices, please contact us at privacy@eventflow.com. You may also write to us at: EventFlow Inc., 100 Innovation Drive, Suite 300, San Francisco, CA 94105, United States. Our Data Protection Officer can be reached at dpo@eventflow.com.",
  },
]

export default function PrivacyPolicyPage() {
  return (
    <>
      <PageHero
        title="Privacy Policy"
        highlight=""
        description="Last updated: June 15, 2026. This policy describes how EventFlow handles your personal information."
      />

      <section className="py-16 bg-slate-50/50">
        <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
          <p className="text-slate-600 leading-relaxed mb-8">
            At EventFlow, we take your privacy seriously. This Privacy Policy explains how we collect,
            use, disclose, and safeguard your information when you use our platform. Please read this
            policy carefully. By using EventFlow, you consent to the practices described in this policy.
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
        title="Have questions about"
        highlight="your data?"
        description="Our Data Protection Officer is here to help. Reach out anytime."
        buttonText="Contact DPO"
        buttonHref="mailto:dpo@eventflow.com"
      />
    </>
  )
}
