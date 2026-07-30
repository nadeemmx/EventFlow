"use client"

import { useEffect, useRef } from "react"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"

gsap.registerPlugin(ScrollTrigger)

const logos = [
  "Grand Palace", "Skyline", "Emerald Gardens", "Royal Oak",
  "Gold Crest", "Silver Sands", "Crystal Hall", "The Legacy",
]

export default function TrustedBy() {
  const sectionRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.from(sectionRef.current!.querySelectorAll(".logo-item"), {
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
          Trusted by event venues nationwide
        </p>
        <div className="flex flex-wrap items-center justify-center gap-x-10 gap-y-3">
          {logos.map((name) => (
            <div
              key={name}
              className="logo-item text-sm sm:text-base font-bold tracking-tight text-slate-300"
            >
              {name}
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
