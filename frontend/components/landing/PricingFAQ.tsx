"use client"

import { useState, useEffect, useRef } from "react"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"
import { Check, ChevronDown } from "lucide-react"
import BusinessField from "@/components/legal/BusinessField"

gsap.registerPlugin(ScrollTrigger)

const plans = [
  {
    name: "Starter",
    price: "1,999",
    description: "For single-venue operators getting started",
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
    popular: false,
  },
  {
    name: "Growth",
    price: "3,999",
    description: "For growing venues with multiple teams",
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
    popular: true,
  },
  {
    name: "Enterprise",
    price: null,
    description: "For large venues and venue chains",
    features: [
      "Everything in Growth",
      "Multi-tenant architecture",
      "Custom role-based access control",
      "Team members",
    ],
    cta: "Contact Sales",
    href: "/contact",
    popular: false,
  },
]

const faqs = [
  {
    q: "How does signing up work?",
    a: (
      <>
        Create an account and start setting up your venue — no credit card required to sign up.
        Trial and plan terms: <BusinessField label="Free trial terms" />.
      </>
    ),
  },
  {
    q: "Can I manage multiple venues?",
    a: "Yes. Our Enterprise plan supports multi-venue management with unified dashboards, cross-venue reporting, and centralized customer management.",
  },
  {
    q: "What payment methods do you support?",
    a: "Online payments are collected through Razorpay — UPI, credit and debit cards, and net banking. You can also record manual payments such as cash, cheque, or bank transfer.",
  },
  {
    q: "How long does onboarding take?",
    a: "You can sign up, add your venues, and start taking bookings yourself. If you would like a hand migrating existing data, contact us and we will help you through it.",
  },
  {
    q: "Can I customize invoices?",
    a: "Yes. You can set an invoice number prefix, upload your logo, add footer text and payment terms, choose GST details, pick a template, and set the currency.",
  },
  {
    q: "Is my data secure?",
    a: "Access uses JWT sessions, sensitive credentials are encrypted at rest with AES-256-GCM, and traffic is served over HTTPS/TLS. SOC 2 compliance is in progress — we do not claim to hold the certification yet.",
  },
]

export default function PricingFAQ() {
  const [billing, setBilling] = useState<"monthly" | "annual">("monthly")
  const [openFaq, setOpenFaq] = useState<number | null>(null)
  const pricingRef = useRef<HTMLDivElement>(null)
  const faqRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const cards = pricingRef.current?.querySelectorAll(".pricing-card")
    if (!cards || cards.length === 0) return
    const ctx = gsap.context(() => {
      gsap.set(cards, { opacity: 1, y: 0 })
      gsap.from(cards, {
        y: 30,
        opacity: 0,
        duration: 0.5,
        stagger: 0.08,
        ease: "power3.out",
        scrollTrigger: {
          trigger: pricingRef.current,
          start: "top 85%",
        },
        onComplete: () => {
          gsap.set(cards, { clearProps: "opacity" })
        },
      })
    }, pricingRef)
    return () => ctx.revert()
  }, [])

  const toggleFaq = (index: number) => {
    setOpenFaq(openFaq === index ? null : index)
  }

  return (
    <>
      <section id="pricing" className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
              Simple,{" "}
              <span className="text-gradient">Transparent</span> Pricing
            </h2>
            <p className="mt-3 text-slate-600 max-w-xl mx-auto">
              Plan prices are shown in full below. Scale your plan as you grow.
            </p>

            <div className="inline-flex items-center gap-2 mt-6 p-1 rounded-lg bg-slate-100" role="group" aria-label="Billing period">
              <button
                type="button"
                aria-pressed={billing === "monthly"}
                onClick={() => setBilling("monthly")}
                className={`cursor-pointer px-4 py-1.5 text-sm font-medium rounded-md transition-all ${
                  billing === "monthly"
                    ? "bg-white text-foreground shadow-sm"
                    : "text-slate-600 hover:text-slate-900"
                }`}
              >
                Monthly
              </button>
              <button
                type="button"
                aria-pressed={billing === "annual"}
                onClick={() => setBilling("annual")}
                className={`cursor-pointer px-4 py-1.5 text-sm font-medium rounded-md transition-all ${
                  billing === "annual"
                    ? "bg-white text-foreground shadow-sm"
                    : "text-slate-600 hover:text-slate-900"
                }`}
              >
                Annual{" "}
                <span className="text-xs text-amber-700 font-semibold">Save 17%</span>
              </button>
            </div>
          </div>

          <div
            ref={pricingRef}
            className="grid md:grid-cols-3 gap-4 max-w-5xl mx-auto"
          >
            {plans.map((plan) => (
              <div
                key={plan.name}
                className={`pricing-card relative rounded-xl border p-5 transition-all duration-200 ${
                  plan.popular
                    ? "border-amber-500/50 bg-white shadow-lg shadow-amber-500/10 scale-[1.02]"
                    : "border-slate-200 bg-white hover:border-slate-300"
                }`}
              >
                {plan.popular && (
                  <div className="absolute -top-2.5 left-1/2 -translate-x-1/2 inline-flex items-center rounded-full bg-amber-500 px-3 py-0.5 text-[10px] font-semibold text-slate-900">
                    Recommended
                  </div>
                )}

                <h3 className="text-base font-semibold">{plan.name}</h3>
                <p className="text-xs text-slate-500 mt-1 mb-3">
                  {plan.description}
                </p>

                <div className="mb-4">
                  {plan.price !== null ? (
                    <>
                      <span className="text-2xl sm:text-3xl font-bold">₹{plan.price}</span>
                      <span className="text-sm text-slate-500">
                        /{billing === "monthly" ? "mo" : "mo, billed annually"}
                      </span>
                      {billing === "annual" && (
                        <p className="text-xs text-emerald-700 mt-1">
                          ₹{parseInt(plan.price.replace(/,/g, "")) * 10}/yr — 2 months free
                        </p>
                      )}
                    </>
                  ) : (
                    <span className="text-2xl sm:text-3xl font-bold">Custom</span>
                  )}
                </div>

                <a
                  href={plan.href}
                  className={`block text-center rounded-lg py-2.5 text-sm font-semibold transition-all ${
                    plan.popular
                      ? "bg-amber-500 text-slate-900 hover:bg-amber-600"
                      : "border border-slate-200 text-foreground hover:bg-slate-50"
                  }`}
                >
                  {plan.cta}
                </a>

                <ul className="mt-4 space-y-2">
                  {plan.features.map((feature) => (
                    <li key={feature} className="flex items-start gap-2 text-xs sm:text-sm text-slate-600">
                      <Check className="h-4 w-4 text-amber-600 mt-0.5 shrink-0" aria-hidden="true" focusable="false" />
                      {feature}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>

          <div className="mt-8 max-w-5xl mx-auto rounded-xl border border-slate-200 bg-white p-5 text-xs sm:text-sm text-slate-600 leading-relaxed">
            <p className="font-semibold text-slate-900 mb-1">Billing notes</p>
            <p>
              Prices are in Indian Rupees (₹) and exclude taxes where applicable — see our{" "}
              <a href="/terms-of-service/" className="underline text-slate-900">
                Terms of Service
              </a>{" "}
              and{" "}
              <a href="/refund-policy/" className="underline text-slate-900">
                Refund Policy
              </a>
              . Annual billing is 10× the monthly price, charged upfront for the year (2 months
              free). There is no setup fee. Payment processing for your bookings goes through
              Razorpay and its fees are separate from your plan — see the{" "}
              <a href="/terms-of-service/#payments" className="underline text-slate-900">
                payments section
              </a>{" "}
              of our Terms.
            </p>
          </div>
        </div>
      </section>

      <section id="faq" className="py-20 bg-slate-50/50 border-t border-slate-100">
        <div ref={faqRef} className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-10">
            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
              Frequently Asked{" "}
              <span className="text-gradient">Questions</span>
            </h2>
          </div>

          <div className="space-y-2">
            {faqs.map((faq, i) => (
              <div
                key={i}
                className={`rounded-lg border overflow-hidden transition-colors duration-200 ${
                  openFaq === i ? "border-amber-500/40 bg-white" : "border-slate-200 bg-white"
                }`}
              >
                <button
                  onClick={() => toggleFaq(i)}
                  className="cursor-pointer flex items-center justify-between w-full p-4 text-left"
                  aria-expanded={openFaq === i}
                >
                  <span className={`text-sm font-medium pr-4 transition-colors ${
                    openFaq === i ? "text-amber-700" : ""
                  }`}>
                    {faq.q}
                  </span>
                  <ChevronDown
                    aria-hidden="true"
                    focusable="false"
                    className={`h-4 w-4 shrink-0 transition-all duration-300 ${
                      openFaq === i ? "rotate-180 text-amber-700" : "text-slate-500"
                    }`}
                  />
                </button>
                <div
                  className={`overflow-hidden transition-all duration-300 ${
                    openFaq === i ? "max-h-48 opacity-100" : "max-h-0 opacity-0"
                  }`}
                >
                  <p className="px-4 pb-4 text-xs sm:text-sm text-slate-600 leading-relaxed">
                    {faq.a}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>
    </>
  )
}
