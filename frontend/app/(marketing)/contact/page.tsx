import { createMetadata } from "@/lib/seo"
import { business } from "@/lib/business"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import SectionHeader from "@/components/marketing/SectionHeader"
import ContactForm from "@/components/marketing/ContactForm"
import BusinessField from "@/components/legal/BusinessField"

export const metadata = createMetadata({
  title: "Contact",
  description: "Get in touch with EventFlow",
  path: "/contact",
})

const contactInfo = [
  {
    label: "Email",
    value: business.generalEmail,
    href: `mailto:${business.generalEmail}`,
  },
  {
    label: "Phone",
    value: business.phone,
    href: business.phone ? `tel:${business.phone.replace(/[^+\d]/g, "")}` : null,
  },
  {
    label: "Address",
    value: business.address,
    href: null,
  },
]

const faqs = [
  {
    question: "How long does onboarding take?",
    answer: "It depends on your venue\u2019s setup and how much data you are moving. Once we understand your requirements, we confirm a realistic go-live plan with you.",
  },
  {
    question: "Do you offer custom pricing for large venues?",
    answer: "We tailor quotes for multi-venue operators and large event spaces. Tell us what you need and our sales team will come back with pricing for your use case.",
  },
  {
    question: "Can I migrate data from my existing system?",
    answer: "We can import bookings, customers and invoices from spreadsheets or most systems. We agree the migration plan with you first, including scope, timing and how any disruption is handled.",
  },
  {
    question: "What kind of support do you provide?",
    answer: "Support channels and response commitments vary by plan. We will confirm exactly what is included before you sign up.",
  },
  {
    question: "Is EventFlow suitable for small venues?",
    answer: "EventFlow is designed for venues of all sizes. See the pricing page for current plan details \u2014 the Starter plan is listed there for single venues.",
  },
]

export default function ContactPage() {
  return (
    <>
      <PageHero
        title="We Would Love to"
        highlight="Hear from You"
        description="Have a question about EventFlow? Our team is ready to help you get started."
      />

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid gap-12 lg:grid-cols-2">
            <div>
              <SectionHeader
                title="Send Us a Message"
                description="Fill out the form and we will reply by email"
              />
              <ContactForm />
            </div>
            <div>
              <SectionHeader
                title="Contact Information"
                description="Reach out to us through any of these channels"
              />
              <div className="space-y-6">
                {contactInfo.map((info) => (
                  <div key={info.label} className="rounded-2xl border border-slate-200 bg-white p-6">
                    <h3 className="text-sm font-bold text-slate-500 uppercase tracking-wide mb-1">{info.label}</h3>
                    {info.href ? (
                      <a href={info.href} className="text-lg font-semibold text-slate-900 hover:text-amber-600 transition-colors">
                        <BusinessField value={info.value} label={info.label} />
                      </a>
                    ) : (
                      <p className="text-lg font-semibold text-slate-900">
                        <BusinessField value={info.value} label={info.label} />
                      </p>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="bg-slate-50/50 py-20">
        <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Frequently Asked Questions"
            description="Quick answers to common questions"
          />
          <div className="space-y-4">
            {faqs.map((faq) => (
              <details key={faq.question} className="group rounded-2xl border border-slate-200 bg-white overflow-hidden">
                <summary className="flex items-center justify-between px-6 py-4 cursor-pointer text-sm font-semibold text-slate-900 hover:bg-slate-50 transition-colors [&::-webkit-details-marker]:hidden">
                  {faq.question}
                  <span className="text-amber-500 text-lg group-open:rotate-180 transition-transform">▾</span>
                </summary>
                <div className="px-6 pb-4">
                  <p className="text-sm text-slate-600 leading-relaxed">{faq.answer}</p>
                </div>
              </details>
            ))}
          </div>
        </div>
      </section>

      <PageCTA
        title="Ready to Streamline Your Venue?"
        highlight="Start Free"
        description="Create an account and explore EventFlow for your venue. No credit card required to sign up."
      />
    </>
  )
}
