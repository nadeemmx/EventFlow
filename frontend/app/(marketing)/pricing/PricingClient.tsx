"use client"

import { useState } from "react"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import SectionHeader from "@/components/marketing/SectionHeader"
import BusinessField from "@/components/legal/BusinessField"

const plans = [
  {
    name: "Starter",
    price: 1999,
    popular: false,
    description: "Perfect for single-venue operators getting started with modern event management.",
    features: [
      "Up to 100 bookings per month",
      "Lead CRM with email capture",
      "Shared calendar view",
      "Basic reports (bookings & revenue)",
      "Email support within 24 hours",
      "Up to 2 staff accounts",
      "Payment gateway integration",
      "Invoice generation",
    ],
    cta: "Start Free",
    href: "/signup",
  },
  {
    name: "Growth",
    price: 3999,
    popular: true,
    description: "Built for growing venues that need advanced tools and multi-user collaboration.",
    features: [
      "Bookings",
      "Full CRM",
      "Multi-venue calendar",
      "Analytics & reports",
      "Email support",
      "Up to 15 staff accounts",
      "WhatsApp notifications",
      "Vendor & staff management",
      "Custom invoice templates",
      "API access",
    ],
    cta: "Start Free",
    href: "/signup",
  },
  {
    name: "Enterprise",
    price: null,
    popular: false,
    description: "Tailored solutions for multi-location venue groups with complex operational needs.",
    features: [
      "Everything in Growth",
      "Multi-tenant architecture",
      "Custom role-based access control",
      "Team members",
    ],
    cta: "Contact Sales",
    href: "/contact",
  },
]

const pricingFeatures = [
  { name: "Bookings", starter: "100", growth: "Included", enterprise: "Included" },
  { name: "Team members", starter: "2", growth: "15", enterprise: "Included" },
  { name: "Venue spaces", starter: "1", growth: "5", enterprise: "Included" },
  { name: "Lead CRM", starter: true, growth: true, enterprise: true },
  { name: "Calendar sync", starter: false, growth: true, enterprise: true },
  { name: "Payment gateway", starter: true, growth: true, enterprise: true },
  { name: "Invoicing (GST)", starter: true, growth: true, enterprise: true },
  { name: "Reports & analytics", starter: "Basic", growth: "Included", enterprise: "Included" },
  { name: "Vendor management", starter: false, growth: true, enterprise: true },
  { name: "Staff scheduling", starter: false, growth: true, enterprise: true },
  { name: "WhatsApp notifications", starter: false, growth: true, enterprise: true },
  { name: "API access", starter: false, growth: true, enterprise: true },
  { name: "Multi-tenant", starter: false, growth: false, enterprise: true },
  { name: "Role-based access", starter: false, growth: false, enterprise: true },
]

const faqs = [
  {
    q: "Can I switch plans mid-cycle?",
    a: "Yes. You can upgrade or downgrade at any time. Billing changes are agreed with you before they take effect.",
  },
  {
    q: "Is there a free trial available?",
    a: (
      <>
        You can create an account and start with no credit card required. Trial and plan terms:{" "}
        <BusinessField label="Free trial terms" />.
      </>
    ),
  },
  {
    q: "Do you offer GST invoices?",
    a: "Yes. Invoices generated within EventFlow can include your business details and GST settings, and you can send them directly to clients.",
  },
  {
    q: "Can I use my own payment gateway?",
    a: "EventFlow integrates with Razorpay for online payments, and you can also record manual payments such as cash, cheque, or bank transfer. Other gateways are not supported today.",
  },
  {
    q: "What happens if I reach my booking limit on Starter?",
    a: "We will tell you before any plan change affects your bill.",
  },
  {
    q: "Is my data secure on EventFlow?",
    a: "Yes. Access uses JWT sessions, sensitive credentials such as gateway keys are encrypted at rest with AES-256-GCM, and traffic is served over HTTPS/TLS. SOC 2 compliance is in progress — we do not claim certification yet, and we have not commissioned an external penetration test.",
  },
  {
    q: "Do you offer discounts for annual billing?",
    a: "Yes. Annual billing is charged upfront for the year at 10× the monthly price — two months free, effectively a 17% discount. That is ₹3,998/year on Starter and ₹7,998/year on Growth.",
  },
  {
    q: "Can I migrate data from my current system?",
    a: "We offer free migration assistance on the Growth and Enterprise plans. Our team will work with you to import your existing bookings, leads, and customer data, and we agree the migration plan with you first.",
  },
]

function CheckIcon({ label }: { label?: string } = {}) {
  return (
    <svg
      className="h-4 w-4 text-emerald-700 shrink-0"
      fill="none"
      viewBox="0 0 24 24"
      strokeWidth="2.5"
      stroke="currentColor"
      {...(label ? { role: "img", "aria-label": label } : { "aria-hidden": true })}
      focusable="false"
    >
      <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
    </svg>
  )
}

function DashIcon({ label }: { label?: string } = {}) {
  return (
    <svg
      className="h-4 w-4 text-slate-500 shrink-0"
      fill="none"
      viewBox="0 0 24 24"
      strokeWidth="2"
      stroke="currentColor"
      {...(label ? { role: "img", "aria-label": label } : { "aria-hidden": true })}
      focusable="false"
    >
      <path strokeLinecap="round" strokeLinejoin="round" d="M5 12h14" />
    </svg>
  )
}

function renderCell(value: boolean | string): React.ReactNode {
  if (typeof value === "boolean") {
    return value ? <CheckIcon label="Included" /> : <DashIcon label="Not included" />
  }
  return <span className="text-slate-800">{value}</span>
}

export default function PricingClient() {
  const [annual, setAnnual] = useState(false)

  return (
    <>
      <PageHero
        title="Simple, Transparent"
        highlight="Pricing"
        description="Plan prices are shown in full below. Choose the plan that fits your venue — and upgrade as you grow."
      />

      <section className="pb-12">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-center gap-4 mb-12">
            <span className={`text-sm font-medium ${!annual ? "text-slate-900" : "text-slate-500"}`}>Monthly</span>
            <button
              type="button"
              role="switch"
              aria-checked={annual}
              aria-label="Billing period: monthly or annual"
              onClick={() => setAnnual(!annual)}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                annual ? "bg-amber-500" : "bg-slate-300"
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                  annual ? "translate-x-6" : "translate-x-1"
                }`}
              />
            </button>
            <span className={`text-sm font-medium ${annual ? "text-slate-900" : "text-slate-500"}`}>
              Annual{" "}
              <span className="text-emerald-700 font-semibold">Save 17%</span>
            </span>
            <span className="sr-only" role="status">
              {annual ? "Annual billing selected" : "Monthly billing selected"}
            </span>
          </div>

          <div className="grid gap-8 lg:grid-cols-3">
            {plans.map((plan) => (
              <div
                key={plan.name}
                className={`pricingCard relative flex flex-col rounded-2xl border bg-white p-8 transition-all hover:-translate-y-1 ${
                  plan.popular
                    ? "border-amber-500 shadow-xl shadow-amber-500/10 scale-105 lg:scale-110"
                    : "border-slate-200 shadow-sm hover:shadow-md"
                }`}
              >
                {plan.popular && (
                  <span className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-amber-500 px-4 py-1 text-xs font-semibold text-slate-900">
                    Recommended
                  </span>
                )}
                <h3 className="text-xl font-bold text-slate-900">{plan.name}</h3>
                <p className="mt-1 text-sm text-slate-600">{plan.description}</p>
                <div className="mt-6 mb-6">
                  {plan.price !== null ? (
                    <div className="flex items-baseline gap-1">
                      <span className="text-4xl font-bold text-slate-900">₹{plan.price}</span>
                      <span className="text-sm text-slate-500">
                        {annual ? "/mo, billed annually" : "/mo"}
                      </span>
                    </div>
                  ) : (
                    <div className="text-4xl font-bold text-slate-900">Custom</div>
                  )}
                  {annual && plan.price !== null && (
                    <p className="text-xs text-emerald-700 mt-1">₹{plan.price * 10}/yr billed annually — 2 months free</p>
                  )}
                </div>
                <ul className="space-y-3 mb-8 flex-1">
                  {plan.features.map((f) => (
                    <li key={f} className="flex items-start gap-2 text-sm text-slate-700">
                      <CheckIcon />
                      {f}
                    </li>
                  ))}
                </ul>
                <a
                  href={plan.href}
                  className={`inline-flex items-center justify-center rounded-xl px-6 py-3 text-sm font-semibold transition-all ${
                    plan.popular
                      ? "bg-amber-500 text-slate-900 hover:bg-amber-600 hover:shadow-lg hover:shadow-amber-500/30"
                      : "border border-slate-300 text-slate-900 hover:border-amber-500 hover:text-amber-600"
                  }`}
                >
                  {plan.cta}
                </a>
              </div>
            ))}
          </div>

          <div className="mt-10 rounded-xl border border-slate-200 bg-white p-6 text-sm text-slate-600 leading-relaxed">
            <h2 className="text-base font-semibold text-slate-900 mb-2">Billing notes</h2>
            <ul className="list-disc space-y-1.5 pl-5">
              <li>
                Prices are in Indian Rupees (₹) and exclude taxes where applicable — see our{" "}
                <a href="/terms-of-service/" className="underline text-slate-900">
                  Terms of Service
                </a>{" "}
                for full billing terms.
              </li>
              <li>
                Annual billing is 10× the monthly price, charged upfront for the year (2 months
                free).
              </li>
              <li>No setup fee.</li>
              <li>
                Payment processing for your bookings goes through Razorpay and its fees are
                separate from your EventFlow plan — see the{" "}
                <a href="/terms-of-service/#payments" className="underline text-slate-900">
                  payments section
                </a>{" "}
                of our Terms.
              </li>
              <li>
                See our{" "}
                <a href="/refund-policy/" className="underline text-slate-900">
                  Refund Policy
                </a>{" "}
                for how cancellations and refunds are handled.
              </li>
            </ul>
          </div>
        </div>
      </section>

      <section className="py-20 bg-slate-50/50">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Compare"
            highlight="Plans in Detail"
            description="Every feature broken down so you can pick the right plan with confidence."
          />
          <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
            <table className="w-full text-sm">
              <caption className="sr-only">Plan feature comparison across Starter, Growth and Enterprise</caption>
              <thead>
                <tr className="border-b border-slate-200 bg-slate-50">
                  <th className="text-left py-4 px-6 font-semibold text-slate-900">Feature</th>
                  <th className="text-center py-4 px-6 font-semibold text-slate-900">Starter</th>
                  <th className="text-center py-4 px-6 font-semibold text-amber-700">Growth</th>
                  <th className="text-center py-4 px-6 font-semibold text-slate-900">Enterprise</th>
                </tr>
              </thead>
              <tbody>
                {pricingFeatures.map((row, i) => (
                  <tr key={row.name} className={i < pricingFeatures.length - 1 ? "border-b border-slate-100" : ""}>
                    <td className="py-4 px-6 text-slate-800 font-medium">{row.name}</td>
                    <td className="py-4 px-6 text-center text-slate-600">{renderCell(row.starter)}</td>
                    <td className="py-4 px-6 text-center text-slate-600">{renderCell(row.growth)}</td>
                    <td className="py-4 px-6 text-center text-slate-600">{renderCell(row.enterprise)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <section className="py-20">
        <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Frequently Asked"
            highlight="Questions"
            description="Everything you need to know about pricing, billing, and switching plans."
          />
          <div className="space-y-4">
            {faqs.map((faq) => (
              <details key={faq.q} className="group rounded-xl border border-slate-200 bg-white open:border-amber-500/30">
                <summary className="flex cursor-pointer items-center justify-between px-6 py-4 text-sm font-medium text-slate-900 list-none">
                  {faq.q}
                  <svg
                    className="h-4 w-4 text-slate-500 transition-transform group-open:rotate-180"
                    fill="none"
                    viewBox="0 0 24 24"
                    strokeWidth="2"
                    stroke="currentColor"
                    aria-hidden="true"
                    focusable="false"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" />
                  </svg>
                </summary>
                <div className="px-6 pb-4 text-sm text-slate-600 leading-relaxed border-t border-slate-100 pt-3">
                  {faq.a}
                </div>
              </details>
            ))}
          </div>
        </div>
      </section>

      <PageCTA
        title="Start Growing Your Venue Business"
        highlight="Today"
        description="Create an account and set up your venue. No credit card required to sign up."
        buttonText="Create Your Account"
        buttonHref="/signup"
      />
    </>
  )
}
