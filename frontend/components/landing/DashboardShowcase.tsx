"use client"

import { useEffect, useRef } from "react"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"
import { motion } from "framer-motion"
import { CalendarCheck, IndianRupee, Users, TrendingUp, Calendar } from "lucide-react"

gsap.registerPlugin(ScrollTrigger)

export default function DashboardShowcase() {
  const sectionRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.from(sectionRef.current!.querySelectorAll(".dash-metric"), {
        y: 20,
        opacity: 0,
        duration: 0.5,
        stagger: 0.08,
        ease: "power2.out",
        scrollTrigger: {
          trigger: sectionRef.current,
          start: "top 75%",
        },
      })
    }, sectionRef)
    return () => ctx.revert()
  }, [])

  return (
    <section id="demo" ref={sectionRef} className="py-20">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
            See What{" "}
            <span className="text-gradient">It Looks Like</span>
          </h2>
          <p className="mt-3 text-slate-600 max-w-xl mx-auto">
            A clean, intuitive dashboard that gives you full visibility into your venue business.
          </p>
        </div>

        <div className="relative rounded-xl border border-slate-200 bg-white shadow-xl shadow-slate-200/50 overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 py-2.5 border-b border-slate-100 bg-slate-50/50">
            <div className="w-2.5 h-2.5 rounded-full bg-red-400/60" />
            <div className="w-2.5 h-2.5 rounded-full bg-yellow-400/60" />
            <div className="w-2.5 h-2.5 rounded-full bg-green-400/60" />
            <div className="ml-3 text-xs font-medium text-slate-500">EventFlow Dashboard</div>
            <div className="ml-auto text-[10px] font-medium text-slate-500 uppercase tracking-wider">
              Sample data
            </div>
          </div>

          <div className="p-5 sm:p-6">
            <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-3 mb-4">
              {[
                { label: "Revenue MTD", value: "₹4,82,000", change: "+12.5%", icon: IndianRupee },
                { label: "Active Bookings", value: "48", change: "+8.2%", icon: CalendarCheck },
                { label: "New Leads", value: "124", change: "+23.1%", icon: Users },
                { label: "Occupancy Rate", value: "78%", change: "+5.3%", icon: TrendingUp },
              ].map((metric) => {
                const Icon = metric.icon
                return (
                  <div key={metric.label} className="dash-metric rounded-lg border border-slate-100 bg-slate-50/30 p-3.5">
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-xs text-slate-500">{metric.label}</span>
                      <Icon className="h-3.5 w-3.5 text-amber-500" />
                    </div>
                    <p className="text-lg font-bold text-slate-900">{metric.value}</p>
                    <p className="text-[11px] font-medium text-emerald-700">{metric.change} vs last month</p>
                  </div>
                )
              })}
            </div>

            <div className="grid sm:grid-cols-2 gap-3">
              <div className="rounded-lg border border-slate-100 bg-slate-50/30 p-3.5">
                <div className="flex items-center justify-between mb-3">
                  <span className="text-xs font-medium text-slate-600">Calendar Overview</span>
                  <Calendar className="h-3.5 w-3.5 text-slate-400" />
                </div>
                <div className="grid grid-cols-7 gap-1 text-center">
                  {["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map((d) => (
                    <span key={d} className="text-[9px] text-slate-500 font-medium">{d}</span>
                  ))}
                  {Array.from({ length: 35 }).map((_, i) => (
                    <div
                      key={i}
                      className={`text-[10px] py-1 rounded ${
                        i === 15 ? "bg-amber-500 text-slate-900 font-semibold" :
                        i % 7 === 0 || i % 7 === 6 ? "text-slate-500" : "text-slate-700"
                      }`}
                    >
                      {i + 1}
                    </div>
                  ))}
                </div>
              </div>

              <div className="rounded-lg border border-slate-100 bg-slate-50/30 p-3.5">
                <div className="flex items-center justify-between mb-3">
                  <span className="text-xs font-medium text-slate-600">Upcoming Events</span>
                </div>
                <div className="space-y-2">
                  {[
                    { name: "Grand Wedding", date: "Today, 4:00 PM", status: "Confirmed", color: "text-emerald-700" },
                    { name: "Corporate Gala", date: "Tomorrow, 7:00 PM", status: "Confirmed", color: "text-emerald-700" },
                    { name: "Birthday Bash", date: "Jul 2, 2:00 PM", status: "Tentative", color: "text-amber-700" },
                    { name: "Conference", date: "Jul 5, 9:00 AM", status: "Confirmed", color: "text-emerald-700" },
                  ].map((event) => (
                    <div key={event.name} className="flex items-center justify-between">
                      <div>
                        <p className="text-xs font-medium text-slate-900">{event.name}</p>
                        <p className="text-[10px] text-slate-500">{event.date}</p>
                      </div>
                      <span className={`text-[10px] font-medium ${event.color}`}>{event.status}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.2, duration: 0.5 }}
          className="mt-8 text-center"
        >
          <a
            href="/signup"
            className="inline-flex items-center gap-2 rounded-xl bg-amber-500 px-6 py-3 text-sm font-semibold text-slate-900 hover:bg-amber-600 transition-all hover:shadow-lg hover:shadow-amber-500/25"
          >
            Create your account
          </a>
        </motion.div>
      </div>
    </section>
  )
}
