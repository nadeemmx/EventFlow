"use client"

import { useEffect, useRef } from "react"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"
import {
  CalendarCheck,
  Users,
  Target,
  Building2,
  CreditCard,
  FileText,
  Bell,
  BarChart3,
  UserCog,
  Package,
  FileSignature,
} from "lucide-react"

gsap.registerPlugin(ScrollTrigger)

const features = [
  {
    icon: CalendarCheck,
    title: "Booking Management",
    description: "See venue availability on a shared calendar and keep each booking scheduled in one place.",
  },
  {
    icon: Users,
    title: "Customer Management",
    description: "Centralized customer profiles with contact history, preferences, and communication logs for every event.",
  },
  {
    icon: Target,
    title: "Lead Management",
    description: "Capture, track, and convert leads with a built-in CRM, with follow-up reminders and lead tracking.",
  },
  {
    icon: Building2,
    title: "Venue Management",
    description: "Manage multiple venues with capacity tracking, pricing tiers, and availability calendars.",
  },
  {
    icon: CreditCard,
    title: "Payments",
    description: "Accept payments via UPI, cards, and net banking. Track dues, process refunds, and reconcile with ease.",
  },
  {
    icon: FileText,
    title: "Invoices",
    description: "Generate GST invoices from your bookings, send them to customers, and track payments against them.",
  },
  {
    icon: Bell,
    title: "Notifications",
    description: "Reminders and updates via email and WhatsApp. Keep customers and staff informed at every stage.",
  },
  {
    icon: BarChart3,
    title: "Reports & Dashboard",
    description: "Revenue reports, occupancy trends, and business insights. Make data-driven decisions for your venue.",
  },
  {
    icon: UserCog,
    title: "Staff Management",
    description: "Assign roles and manage your team from a single dashboard.",
  },
  {
    icon: Package,
    title: "Inventory Management",
    description: "Track equipment, supplies, and stock levels. Allocate resources per booking and avoid shortages.",
  },
  {
    icon: FileSignature,
    title: "Contracts & Quotations",
    description: "Create and send contracts and quotations, and record contract sign-off against each booking.",
  },
]

export default function Features() {
  const sectionRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.from(sectionRef.current!.querySelectorAll(".feature-card"), {
        y: 30,
        opacity: 0,
        duration: 0.5,
        stagger: 0.06,
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
    <section id="features" ref={sectionRef} className="py-20">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
            Everything You Need to{" "}
            <span className="text-gradient">Run Events</span>
          </h2>
          <p className="mt-3 text-slate-600 max-w-xl mx-auto">
            A complete platform for venue owners who want to streamline operations and grow their business.
          </p>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {features.map((feature) => {
            const Icon = feature.icon
            return (
              <div
                key={feature.title}
                className="feature-card rounded-xl border border-slate-200 bg-white p-5 transition-all duration-200 hover:border-slate-300 hover:shadow-md hover:-translate-y-0.5"
              >
                <div className="flex items-center justify-center w-10 h-10 rounded-lg bg-amber-500/10 text-amber-600 mb-4">
                  <Icon className="h-5 w-5" />
                </div>
                <h3 className="text-sm font-semibold mb-1.5">{feature.title}</h3>
                <p className="text-xs text-slate-600 leading-relaxed">
                  {feature.description}
                </p>
              </div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
