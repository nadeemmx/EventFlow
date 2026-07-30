"use client"

import { useEffect, useRef } from "react"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"
import { Quote, Star } from "lucide-react"

gsap.registerPlugin(ScrollTrigger)

const testimonials = [
  {
    name: "Priya Sharma",
    role: "Owner, Grand Palace Banquet Hall",
    content:
      "EventFlow transformed how we manage events. We went from spreadsheets to a fully automated system in days. Our booking accuracy is 100% now, and we&apos;ve grown revenue by 40%.",
    rating: 5,
  },
  {
    name: "Rahul Verma",
    role: "Manager, Skyline Convention Center",
    content:
      "The calendar alone saved us from countless double-booking nightmares. Payment tracking and invoices are seamless. We manage 50+ events per month without a hitch.",
    rating: 5,
  },
  {
    name: "Anita Patel",
    role: "Director, Emerald Gardens",
    content:
      "We evaluated every venue management platform out there. EventFlow won on features, ease of use, and pricing. The reports give us insights we never had before.",
    rating: 5,
  },
]

export default function Testimonials() {
  const sectionRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.from(sectionRef.current!.querySelectorAll(".testimonial-card"), {
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
    <section id="testimonials" ref={sectionRef} className="py-20 bg-slate-50/50">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
            Trusted by{" "}
            <span className="text-gradient">Venue Owners</span>
          </h2>
          <p className="mt-3 text-slate-600 max-w-xl mx-auto">
            See why hundreds of venues across India choose EventFlow to run their business.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-4">
          {testimonials.map((t, i) => (
            <div
              key={i}
              className="testimonial-card rounded-xl border border-slate-200 bg-white p-6 transition-all duration-200 hover:border-slate-300 hover:shadow-md"
            >
              <Quote className="h-6 w-6 text-amber-500/20 mb-3" />
              <p className="text-sm text-slate-600 leading-relaxed mb-4">
                &ldquo;{t.content}&rdquo;
              </p>
              <div className="flex gap-0.5 mb-3">
                {Array.from({ length: t.rating }).map((_, ri) => (
                  <Star key={ri} className="h-3.5 w-3.5 fill-amber-500 text-amber-500" />
                ))}
              </div>
              <div>
                <div className="text-sm font-semibold">{t.name}</div>
                <div className="text-xs text-slate-500">{t.role}</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
