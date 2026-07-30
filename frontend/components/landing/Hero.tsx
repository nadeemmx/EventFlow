"use client"

import { useEffect, useRef } from "react"
import { ArrowRight, PlayCircle, TrendingUp, CalendarCheck, IndianRupee, Users, CheckCircle } from "lucide-react"
import { gsap } from "gsap"

export default function Hero() {
  const containerRef = useRef<HTMLDivElement>(null)
  const textRef = useRef<HTMLDivElement>(null)
  const mockupRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const ctx = gsap.context(() => {
      const tl = gsap.timeline({ defaults: { ease: "power3.out" } })
      tl.from(textRef.current!.querySelectorAll(".anim-up"), {
        y: 40, opacity: 0, duration: 0.8, stagger: 0.12,
      })
      tl.from(mockupRef.current!.querySelectorAll(".mockup-el"), {
        y: 30, opacity: 0, duration: 0.6, stagger: 0.08,
      }, "-=0.4")
    }, containerRef)
    return () => ctx.revert()
  }, [])

  return (
    <section ref={containerRef} className="pt-24 pb-16 sm:pt-28 sm:pb-20 overflow-hidden">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid lg:grid-cols-2 gap-10 lg:gap-14 items-center">
          <div ref={textRef} className="space-y-6">
            <h1 className="anim-up text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight leading-[1.08]">
              Run Your Entire Event Venue Business
              <br />
              <span className="text-gradient">From One Dashboard</span>
            </h1>

            <p className="anim-up text-base sm:text-lg text-slate-600 leading-relaxed max-w-lg">
              Manage bookings, leads, CRM, invoices, payments, vendors, staff and analytics in one platform.
            </p>

            <div className="anim-up flex flex-col sm:flex-row items-start gap-3 pt-2">
              <a
                href="/login"
                className="group inline-flex items-center gap-2 rounded-xl bg-amber-500 px-6 py-3 text-sm font-semibold text-slate-900 hover:bg-amber-600 transition-all hover:shadow-lg hover:shadow-amber-500/25"
              >
                Start Free Trial
                <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
              </a>
              <a
                href="#demo"
                className="group inline-flex items-center gap-2 rounded-xl border-2 border-slate-200 px-6 py-3 text-sm font-semibold text-slate-700 hover:border-slate-300 hover:bg-slate-50 transition-all"
              >
                <PlayCircle className="h-4 w-4" />
                Book Demo
              </a>
            </div>

            <div className="anim-up flex items-center gap-6 pt-2">
              {[
                { number: "500+", label: "Venues" },
                { number: "50K+", label: "Events" },
                { number: "99.9%", label: "Uptime" },
              ].map((stat) => (
                <div key={stat.label} className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-amber-500" />
                  <div className="text-sm">
                    <span className="font-semibold text-slate-900">{stat.number}</span>{" "}
                    <span className="text-slate-500">{stat.label}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div ref={mockupRef} className="relative">
            <div className="mockup-el relative">
              <div className="relative rounded-xl border border-slate-200 bg-white shadow-xl shadow-slate-200/50 overflow-hidden">
                <div className="flex items-center gap-1.5 px-4 py-2.5 border-b border-slate-100">
                  <div className="w-2.5 h-2.5 rounded-full bg-red-400/60" />
                  <div className="w-2.5 h-2.5 rounded-full bg-yellow-400/60" />
                  <div className="w-2.5 h-2.5 rounded-full bg-green-400/60" />
                  <div className="ml-3 text-xs font-medium text-slate-500">EventFlow Dashboard</div>
                </div>

                <div className="p-4 space-y-3">
                  <div className="grid grid-cols-3 gap-2.5">
                    {[
                      { label: "Revenue", value: "₹4,82,000", icon: IndianRupee, change: "+12.5%", up: true },
                      { label: "Bookings", value: "48", icon: CalendarCheck, change: "+8.2%", up: true },
                      { label: "Leads", value: "124", icon: Users, change: "+23.1%", up: true },
                    ].map((stat) => {
                      const Icon = stat.icon
                      return (
                        <div key={stat.label} className="rounded-lg border border-slate-100 bg-slate-50/50 p-3">
                          <div className="flex items-center justify-between mb-1.5">
                            <Icon className="h-3.5 w-3.5 text-amber-500" />
                            <span className={`text-[10px] font-semibold ${stat.up ? "text-success" : "text-red-500"}`}>{stat.change}</span>
                          </div>
                          <p className="text-[10px] text-slate-500">{stat.label}</p>
                          <p className="text-sm font-bold text-slate-900">{stat.value}</p>
                        </div>
                      )
                    })}
                  </div>

                  <div className="rounded-lg border border-slate-100 bg-slate-50/50 p-3">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs font-medium text-slate-600">Weekly Revenue</span>
                      <TrendingUp className="h-3 w-3 text-success" />
                    </div>
                    <div className="flex items-end gap-1 h-14">
                      {[40, 55, 45, 70, 85, 65, 90].map((h, i) => (
                        <div key={i} className="flex-1 flex flex-col items-center gap-1">
                          <div className="w-full rounded-sm bg-gradient-to-t from-amber-500 to-amber-300 transition-all duration-500" style={{ height: `${h}%` }} />
                        </div>
                      ))}
                    </div>
                    <div className="flex justify-between mt-1">
                      {["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((d) => (
                        <span key={d} className="text-[8px] text-slate-400">{d}</span>
                      ))}
                    </div>
                  </div>

                  <div className="rounded-lg border border-slate-100 bg-slate-50/50 p-3">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs font-medium text-slate-600">Today&apos;s Schedule</span>
                      <span className="text-[10px] text-amber-600 font-semibold">3 events</span>
                    </div>
                    <div className="space-y-1.5">
                      {[
                        { name: "Grand Wedding", time: "4:00 PM", status: "Confirmed" },
                        { name: "Corporate Gala", time: "7:00 PM", status: "Confirmed" },
                      ].map((event) => (
                        <div key={event.name} className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <div className="w-1.5 h-1.5 rounded-full bg-success" />
                            <p className="text-xs font-medium text-slate-900">{event.name}</p>
                          </div>
                          <div className="flex items-center gap-2">
                            <span className="text-[10px] text-slate-500">{event.time}</span>
                            <span className="text-[10px] font-medium text-success">{event.status}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
