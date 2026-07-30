import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import SectionHeader from "@/components/marketing/SectionHeader"

export const metadata = createMetadata({
  title: "Contact",
  description: "Get in touch with EventFlow",
  path: "/contact",
})

const contactInfo = [
  {
    label: "Email",
    value: "hello@eventflow.com",
    href: "mailto:hello@eventflow.com",
  },
  {
    label: "Phone",
    value: "+91 1800-123-4567",
    href: "tel:+9118001234567",
  },
  {
    label: "Address",
    value: "91 Springboard, MG Road, Bangalore — 560001, India",
    href: null,
  },
]

const faqs = [
  {
    question: "What is the typical onboarding timeline?",
    answer: "Most venues go live within 2 weeks. Our onboarding team handles data migration, staff training, and configuration so you can hit the ground running.",
  },
  {
    question: "Do you offer custom pricing for large venues?",
    answer: "Yes. We offer custom plans for multi-venue operators and large event spaces. Contact our sales team for a tailored quote based on your specific needs.",
  },
  {
    question: "Can I migrate data from my existing system?",
    answer: "Absolutely. Our migration team will transfer your existing bookings, customer data, and invoices from any platform or spreadsheet into EventFlow with zero downtime.",
  },
  {
    question: "What kind of support do you provide?",
    answer: "All plans include email and chat support during business hours. Premium plans include a dedicated account manager, priority phone support, and 24/7 availability.",
  },
  {
    question: "Is EventFlow suitable for small venues?",
    answer: "Yes. EventFlow is designed for venues of all sizes. Our Lite plan starts at just ₹999 per month and includes everything a small venue needs to manage bookings and payments.",
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
                description="Fill out the form and we will respond within 24 hours"
              />
              <form className="space-y-5" action="#">
                <div className="grid gap-5 sm:grid-cols-2">
                  <div>
                    <label htmlFor="name" className="block text-sm font-medium text-slate-900 mb-1.5">Name</label>
                    <input
                      id="name"
                      type="text"
                      className="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-500/30 focus:border-amber-500"
                      placeholder="Your name"
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
                <div className="grid gap-5 sm:grid-cols-2">
                  <div>
                    <label htmlFor="company" className="block text-sm font-medium text-slate-900 mb-1.5">Company</label>
                    <input
                      id="company"
                      type="text"
                      className="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-500/30 focus:border-amber-500"
                      placeholder="Your venue name"
                    />
                  </div>
                  <div>
                    <label htmlFor="phone" className="block text-sm font-medium text-slate-900 mb-1.5">Phone</label>
                    <input
                      id="phone"
                      type="tel"
                      className="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-500/30 focus:border-amber-500"
                      placeholder="+91 98765 43210"
                    />
                  </div>
                </div>
                <div>
                  <label htmlFor="subject" className="block text-sm font-medium text-slate-900 mb-1.5">Subject</label>
                  <select
                    id="subject"
                    className="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-500/30 focus:border-amber-500"
                  >
                    <option value="">Select a subject</option>
                    <option value="general">General Inquiry</option>
                    <option value="sales">Sales & Pricing</option>
                    <option value="support">Technical Support</option>
                    <option value="partnership">Partnership Opportunities</option>
                    <option value="demo">Request a Demo</option>
                  </select>
                </div>
                <div>
                  <label htmlFor="message" className="block text-sm font-medium text-slate-900 mb-1.5">Message</label>
                  <textarea
                    id="message"
                    rows={5}
                    className="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-500/30 focus:border-amber-500 resize-none"
                    placeholder="Tell us how we can help you..."
                  />
                </div>
                <button
                  type="button"
                  className="w-full sm:w-auto rounded-xl bg-amber-500 px-8 py-3 text-sm font-semibold text-slate-900 hover:bg-amber-600 transition-all"
                >
                  Send Message
                </button>
              </form>
            </div>
            <div>
              <SectionHeader
                title="Contact Information"
                description="Reach out to us through any of these channels"
              />
              <div className="space-y-6">
                {contactInfo.map((info) => (
                  <div key={info.label} className="rounded-2xl border border-slate-200 bg-white p-6">
                    <h3 className="text-sm font-bold text-slate-400 uppercase tracking-wide mb-1">{info.label}</h3>
                    {info.href ? (
                      <a href={info.href} className="text-lg font-semibold text-slate-900 hover:text-amber-600 transition-colors">
                        {info.value}
                      </a>
                    ) : (
                      <p className="text-lg font-semibold text-slate-900">{info.value}</p>
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
        highlight="Start Free Trial"
        description="Join 500+ venues using EventFlow. No credit card required."
      />
    </>
  )
}
