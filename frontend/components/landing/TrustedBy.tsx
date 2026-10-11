"use client"

import { useEffect, useRef } from "react"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"
import {
  Building2,
  CalendarCheck,
  CreditCard,
  Shield,
  Zap,
  Phone,
} from "lucide-react"

gsap.registerPlugin(ScrollTrigger)

const trustItems = [
  { icon: Building2, label: "Built for Event Venues" },
  { icon: CalendarCheck, label: "Bookings, Leads & Invoices" },
  { icon: CreditCard, label: "Razorpay Payments" },
  { icon: Shield, label: "Role-Based Access Control" },
  { icon: Zap, label: "Email & WhatsApp Alerts" },
  { icon: Phone, label: "Support by Email" },
]

export default function TrustedBy() {
  const sectionRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.from(sectionRef.current!.querySelectorAll(".trust-item"), {
        y: 20,
        opacity: 0,
        duration: 0.5,
        stagger: 0.06,
        ease: "power2.out",
        scrollTrigger: {
          trigger: sectionRef.current,
          start: "top 85%",
        },
      })
    }, sectionRef)
    return () => ctx.revert()
  }, [])

  return (
    <section ref={sectionRef} className="py-12 border-y border-slate-100 bg-slate-50/50">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <p className="text-xs font-medium text-slate-500 uppercase tracking-[0.12em] text-center mb-6">
          Designed for modern venue businesses
        </p>
        <div className="flex flex-wrap items-center justify-center gap-x-8 gap-y-3">
          {trustItems.map((item) => {
            const Icon = item.icon
            return (
              <div
                key={item.label}
                className="trust-item flex items-center gap-2 text-sm font-medium text-slate-500"
              >
                <Icon className="h-4 w-4 text-amber-500/60" />
                {item.label}
              </div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
