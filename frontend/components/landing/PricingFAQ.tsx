"use client"

import { useState, useEffect, useRef } from "react"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"
import { Check, ChevronDown } from "lucide-react"

gsap.registerPlugin(ScrollTrigger)

const plans = [
  {
    name: "Starter",
    price: "499",
    description: "For small venues getting started",
    features: [
      "Up to 50 events per month",
      "Basic CRM",
      "Calendar management",
      "Payment tracking",
      "Email support",
    ],
    cta: "Start Free Trial",
    popular: false,
  },
  {
    name: "Growth",
    price: "1,499",
    description: "For growing venues with multiple teams",
    features: [
      "Unlimited events",
      "Advanced CRM & lead scoring",
      "Calendar with auto-scheduling",
      "Payment processing",
      "Invoice generation",
      "Reports & analytics",
      "Staff management",
      "Priority support",
    ],
    cta: "Start Free Trial",
    popular: true,
  },
  {
    name: "Enterprise",
    price: "4,999",
    description: "For large venues and venue chains",
    features: [
      "Everything in Growth",
      "Multi-venue management",
      "Vendor management",
      "Custom integrations",
      "API access",
      "Dedicated account manager",
      "99.99% SLA",
      "24/7 phone support",
    ],
    cta: "Contact Sales",
    popular: false,
  },
]

const faqs = [
  {
    q: "How does the free trial work?",
    a: "Start your 14-day free trial with no credit card required. You get full access to all Growth features. No commitments, cancel anytime.",
  },
  {
    q: "Can I manage multiple venues?",
    a: "Yes. Our Enterprise plan supports multi-venue management with unified dashboards, cross-venue reporting, and centralized customer management.",
  },
  {
    q: "What payment methods do you support?",
    a: "We support all major payment methods including UPI, credit/debit cards, net banking, and bank transfers.",
  },
  {
    q: "How long does onboarding take?",
    a: "Most venues are fully set up within a week. We provide guided onboarding, import tools, and dedicated support throughout.",
  },
  {
    q: "Can I customize invoices?",
    a: "Yes. Add your logo, brand colors, and custom fields to invoices, receipts, and customer communications.",
  },
  {
    q: "Is my data secure?",
    a: "Enterprise-grade security with AES-256 encryption, regular backups, and SOC 2 compliance.",
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
              No hidden fees. No surprise charges. Scale your plan as you grow.
            </p>

            <div className="inline-flex items-center gap-2 mt-6 p-1 rounded-lg bg-slate-100">
              <button
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
                onClick={() => setBilling("annual")}
                className={`cursor-pointer px-4 py-1.5 text-sm font-medium rounded-md transition-all ${
                  billing === "annual"
                    ? "bg-white text-foreground shadow-sm"
                    : "text-slate-600 hover:text-slate-900"
                }`}
              >
                Annual{" "}
                <span className="text-xs text-amber-600 font-semibold">Save 20%</span>
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
                    Most Popular
                  </div>
                )}

                <h3 className="text-base font-semibold">{plan.name}</h3>
                <p className="text-xs text-slate-500 mt-1 mb-3">
                  {plan.description}
                </p>

                <div className="mb-4">
                  <span className="text-2xl sm:text-3xl font-bold">₹{plan.price}</span>
                  <span className="text-sm text-slate-500">
                    /{billing === "monthly" ? "mo" : "mo, billed annually"}
                  </span>
                </div>

                <a
                  href="/login"
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
                      <Check className="h-4 w-4 text-amber-500 mt-0.5 shrink-0" />
                      {feature}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
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
                    openFaq === i ? "text-amber-600" : ""
                  }`}>
                    {faq.q}
                  </span>
                  <ChevronDown
                    className={`h-4 w-4 shrink-0 transition-all duration-300 ${
                      openFaq === i ? "rotate-180 text-amber-600" : "text-slate-400"
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
