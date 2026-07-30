"use client"

import { useState } from "react"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import SectionHeader from "@/components/marketing/SectionHeader"

const plans = [
  {
    name: "Starter",
    price: 499,
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
    cta: "Start Free Trial",
    href: "/signup",
  },
  {
    name: "Growth",
    price: 1499,
    popular: true,
    description: "Built for growing venues that need advanced tools and multi-user collaboration.",
    features: [
      "Unlimited bookings",
      "Full CRM with call logging & quotes",
      "Multi-venue calendar with sync",
      "Advanced analytics & forecasting",
      "Priority chat & email support",
      "Up to 15 staff accounts",
      "WhatsApp & SMS notifications",
      "Vendor & staff management",
      "Custom invoice templates",
      "API access",
    ],
    cta: "Start Free Trial",
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
      "Dedicated account manager",
      "SLA-backed 24/7 phone support",
      "Unlimited staff accounts",
      "On-premise deployment option",
      "Custom integrations & white-label",
      "SOC 2 compliance support",
      "Quarterly business reviews",
    ],
    cta: "Contact Sales",
    href: "/contact",
  },
]

const pricingFeatures = [
  { name: "Bookings per month", starter: "100", growth: "Unlimited", enterprise: "Unlimited" },
  { name: "Staff accounts", starter: "2", growth: "15", enterprise: "Unlimited" },
  { name: "Venue spaces", starter: "1", growth: "5", enterprise: "Unlimited" },
  { name: "Lead CRM", starter: true, growth: true, enterprise: true },
  { name: "Calendar sync", starter: false, growth: true, enterprise: true },
  { name: "Payment gateway", starter: true, growth: true, enterprise: true },
  { name: "Invoicing (GST)", starter: true, growth: true, enterprise: true },
  { name: "Reports & analytics", starter: "Basic", growth: "Advanced", enterprise: "Custom" },
  { name: "Vendor management", starter: false, growth: true, enterprise: true },
  { name: "Staff scheduling", starter: false, growth: true, enterprise: true },
  { name: "WhatsApp / SMS", starter: false, growth: true, enterprise: true },
  { name: "API access", starter: false, growth: true, enterprise: true },
  { name: "Multi-tenant", starter: false, growth: false, enterprise: true },
  { name: "Role-based access", starter: false, growth: false, enterprise: true },
  { name: "Dedicated support", starter: false, growth: false, enterprise: true },
  { name: "On-premise option", starter: false, growth: false, enterprise: true },
]

const faqs = [
  {
    q: "Can I switch plans mid-cycle?",
    a: "Yes. You can upgrade or downgrade at any time. If you upgrade, we prorate the difference. If you downgrade, the new rate applies at the start of your next billing cycle.",
  },
  {
    q: "Is there a free trial available?",
    a: "Absolutely. Every plan comes with a 14-day free trial — no credit card required. You get full access to all features in your chosen plan during the trial period.",
  },
  {
    q: "Do you offer GST invoices?",
    a: "Yes. All invoices generated within EventFlow are GST-compliant and include your business details, GSTIN, and HSN/SAC codes. You can also send them directly to clients.",
  },
  {
    q: "Can I use my own payment gateway?",
    a: "EventFlow integrates with Razorpay and Stripe out of the box. On the Enterprise plan, we can connect to custom or regional payment processors as needed.",
  },
  {
    q: "What happens if I exceed my booking limit on Starter?",
    a: "You will receive a notification when you reach 80% of your cap. If you exceed the limit, you will be prompted to upgrade to Growth. No overage fees — just a seamless upgrade.",
  },
  {
    q: "Is my data secure on EventFlow?",
    a: "Yes. EventFlow is hosted on AWS with SOC 2 compliance in progress. All data is encrypted at rest (AES-256) and in transit (TLS 1.3). We run daily backups and conduct regular penetration testing.",
  },
  {
    q: "Do you offer discounts for annual billing?",
    a: "Yes. Annual billing gives you two months free — effectively a 17% discount. You save ₹1,198/year on Starter and ₹3,598/year on Growth.",
  },
  {
    q: "Can I migrate data from my current system?",
    a: "We offer free migration assistance on the Growth and Enterprise plans. Our team will work with you to import your existing bookings, leads, and customer data with zero downtime.",
  },
]

function CheckIcon() {
  return (
    <svg className="h-4 w-4 text-green-600 shrink-0" fill="none" viewBox="0 0 24 24" strokeWidth="2.5" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
    </svg>
  )
}

function DashIcon() {
  return (
    <svg className="h-4 w-4 text-slate-300 shrink-0" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M5 12h14" />
    </svg>
  )
}

function renderCell(value: boolean | string): React.ReactNode {
  if (typeof value === "boolean") {
    return value ? <CheckIcon /> : <DashIcon />
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
        description="No hidden fees, no surprise charges. Choose the plan that fits your venue — and upgrade as you grow."
      />

      <section className="pb-12">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-center gap-4 mb-12">
            <span className={`text-sm font-medium ${!annual ? "text-slate-900" : "text-slate-400"}`}>Monthly</span>
            <button
              type="button"
              role="switch"
              aria-checked={annual}
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
            <span className={`text-sm font-medium ${annual ? "text-slate-900" : "text-slate-400"}`}>
              Annual{" "}
              <span className="text-green-600 font-semibold">Save 17%</span>
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
                    Most Popular
                  </span>
                )}
                <h3 className="text-xl font-bold text-slate-900">{plan.name}</h3>
                <p className="mt-1 text-sm text-slate-600">{plan.description}</p>
                <div className="mt-6 mb-6">
                  {plan.price !== null ? (
                    <div className="flex items-baseline gap-1">
                      <span className="text-4xl font-bold text-slate-900">₹{annual ? plan.price * 10 : plan.price}</span>
                      <span className="text-sm text-slate-500">/mo</span>
                    </div>
                  ) : (
                    <div className="text-4xl font-bold text-slate-900">Custom</div>
                  )}
                  {annual && plan.price !== null && (
                    <p className="text-xs text-green-600 mt-1">₹{plan.price * 12}/yr billed annually</p>
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
              <thead>
                <tr className="border-b border-slate-200 bg-slate-50">
                  <th className="text-left py-4 px-6 font-semibold text-slate-900">Feature</th>
                  <th className="text-center py-4 px-6 font-semibold text-slate-900">Starter</th>
                  <th className="text-center py-4 px-6 font-semibold text-amber-600">Growth</th>
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
        description="Join thousands of venues already using EventFlow. Free 14-day trial, no credit card."
        buttonText="Start Free Trial"
        buttonHref="/signup"
      />
    </>
  )
}
