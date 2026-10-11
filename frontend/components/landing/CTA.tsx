"use client"

import { useEffect, useRef } from "react"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"
import { ArrowRight, PlayCircle } from "lucide-react"

gsap.registerPlugin(ScrollTrigger)

export default function CTA() {
  const sectionRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.from(sectionRef.current!.querySelectorAll(".cta-el"), {
        y: 30,
        opacity: 0,
        duration: 0.6,
        stagger: 0.1,
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
    <section ref={sectionRef} className="relative overflow-hidden bg-slate-900 py-20">
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-amber-500/5 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-1/4 w-80 h-80 bg-amber-500/5 rounded-full blur-3xl" />
      </div>

      <div className="relative mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 text-center">
        <h2 className="cta-el text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight text-white mb-4">
          Ready to Scale Your
          <br />
          <span className="text-gradient-dark">Venue Business?</span>
        </h2>

        <p className="cta-el text-sm sm:text-base text-slate-400 max-w-md mx-auto mb-8 leading-relaxed">
          Bring bookings, invoices, payments, and customers into one place, and spend less time
          chasing spreadsheets.
        </p>

        <div className="cta-el flex flex-col sm:flex-row items-center justify-center gap-3">
          <a
            href="/signup"
            className="inline-flex items-center gap-2 rounded-xl bg-amber-500 px-7 py-3.5 text-base font-semibold text-slate-900 hover:bg-amber-600 transition-all hover:shadow-xl hover:shadow-amber-500/30"
          >
            Create your account
            <ArrowRight className="h-4 w-4" />
          </a>
          <a
            href="#demo"
            className="inline-flex items-center gap-2 rounded-xl border border-white/10 px-7 py-3.5 text-base font-medium text-white/80 hover:bg-white/5 hover:border-white/20 transition-all"
          >
            <PlayCircle className="h-4 w-4" />
            Book Demo
          </a>
        </div>

        <p className="cta-el text-xs text-slate-500 mt-6">
          No credit card required to sign up.
        </p>
      </div>
    </section>
  )
}
