"use client"

import { useEffect, useRef } from "react"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"
import { Target, CalendarCheck, FileSignature, CreditCard, PartyPopper, FileText } from "lucide-react"

gsap.registerPlugin(ScrollTrigger)

const steps = [
  { icon: Target, label: "Lead" },
  { icon: CalendarCheck, label: "Booking" },
  { icon: FileSignature, label: "Contract" },
  { icon: CreditCard, label: "Payment" },
  { icon: PartyPopper, label: "Event" },
  { icon: FileText, label: "Invoice" },
]

export default function Workflow() {
  const sectionRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.from(sectionRef.current!.querySelectorAll(".wf-step"), {
        scale: 0.8,
        opacity: 0,
        duration: 0.4,
        stagger: 0.1,
        ease: "back.out(1.7)",
        scrollTrigger: {
          trigger: sectionRef.current,
          start: "top 80%",
        },
      })
    }, sectionRef)
    return () => ctx.revert()
  }, [])

  return (
    <section ref={sectionRef} className="py-20 bg-slate-50/50">
      <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
            From Lead to{" "}
            <span className="text-gradient">Revenue</span>
          </h2>
          <p className="mt-3 text-slate-600 max-w-xl mx-auto">
            A streamlined workflow that takes you from first inquiry to final invoice.
          </p>
        </div>

        <div className="flex flex-col md:flex-row items-center justify-center gap-0 md:gap-1">
          {steps.map((step, i) => {
            const Icon = step.icon
            return (
              <div key={step.label} className="wf-step flex items-center gap-2 md:gap-0">
                <div className="flex flex-col items-center">
                  <div className="flex items-center justify-center w-12 h-12 sm:w-14 sm:h-14 rounded-xl bg-amber-500/10 text-amber-600 shadow-sm transition-transform duration-300 hover:scale-110">
                    <Icon className="h-5 w-5 sm:h-6 sm:w-6" />
                  </div>
                  <span className="text-[11px] font-medium mt-1.5 text-slate-600">
                    {step.label}
                  </span>
                </div>
                {i < steps.length - 1 && (
                  <div className="wf-line hidden md:block w-6 sm:w-8 h-0.5 bg-gradient-to-r from-amber-500/40 to-transparent mx-1 mt-[-1.5rem]" />
                )}
                {i < steps.length - 1 && (
                  <div className="md:hidden w-0.5 h-5 bg-gradient-to-b from-amber-500/40 to-transparent mx-auto" />
                )}
              </div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
