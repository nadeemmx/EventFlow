"use client"

import { useEffect, useRef } from "react"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"
import {
  CalendarCheck,
  CreditCard,
  BarChart3,
  FileText,
  Bell,
  Shield,
} from "lucide-react"

gsap.registerPlugin(ScrollTrigger)

const capabilities = [
  {
    icon: CalendarCheck,
    title: "Clear Booking Records",
    description: "Every booking keeps its dates, amounts, status, and customer in one record you can check before confirming.",
  },
  {
    icon: CreditCard,
    title: "Payment Tracking",
    description: "Payments collected through Razorpay are verified by signature and recorded against the booking and invoice.",
  },
  {
    icon: BarChart3,
    title: "Actionable Insights",
    description: "Revenue, occupancy, and lead reports show where the business stands — filter by date range or venue.",
  },
  {
    icon: FileText,
    title: "GST-Ready Invoicing",
    description: "Generate invoices with your GST details applied, export them as PDFs, and email them to clients.",
  },
  {
    icon: Bell,
    title: "Automated Reminders",
    description: "Email, WhatsApp, and in-app notifications keep your team and customers informed at every stage.",
  },
  {
    icon: Shield,
    title: "Security Controls",
    description: "Role-based access, JWT sessions, encrypted credentials, and audit logs keep access accountable.",
  },
]

export default function Testimonials() {
  const sectionRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.from(sectionRef.current!.querySelectorAll(".cap-card"), {
        y: 30,
        opacity: 0,
        duration: 0.5,
        stagger: 0.08,
        ease: "power3.out",
        scrollTrigger: {
          trigger: sectionRef.current,
          start: "top 80%",
        },
      })
    }, sectionRef)
    return () => ctx.revert()
  }, [])

  return (
    <section id="testimonials" ref={sectionRef} className="py-20 bg-slate-50/50">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
            Built for{" "}
            <span className="text-gradient">Venue Teams</span>
          </h2>
          <p className="mt-3 text-slate-600 max-w-xl mx-auto">
            What EventFlow actually does for the people running the venue, day to day.
          </p>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {capabilities.map((cap) => {
            const Icon = cap.icon
            return (
              <div
                key={cap.title}
                className="cap-card rounded-xl border border-slate-200 bg-white p-6 transition-all duration-200 hover:border-slate-300 hover:shadow-md"
              >
                <div className="flex items-center justify-center w-10 h-10 rounded-lg bg-amber-500/10 text-amber-600 mb-4">
                  <Icon className="h-5 w-5" />
                </div>
                <h3 className="text-sm font-semibold mb-1.5">{cap.title}</h3>
                <p className="text-xs text-slate-600 leading-relaxed">
                  {cap.description}
                </p>
              </div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
