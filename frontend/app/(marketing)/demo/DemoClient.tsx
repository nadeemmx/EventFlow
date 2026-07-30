"use client"

import { useState } from "react"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import SectionHeader from "@/components/marketing/SectionHeader"

const venueSizes = [
  "Single venue (under 5,000 sq ft)",
  "Single venue (5,000 - 20,000 sq ft)",
  "Single venue (over 20,000 sq ft)",
  "2-5 venues",
  "6-10 venues",
  "10+ venues",
]

const timeSlots = [
  "9:00 AM - 10:00 AM IST",
  "10:00 AM - 11:00 AM IST",
  "11:00 AM - 12:00 PM IST",
  "12:00 PM - 1:00 PM IST",
  "2:00 PM - 3:00 PM IST",
  "3:00 PM - 4:00 PM IST",
  "4:00 PM - 5:00 PM IST",
  "5:00 PM - 6:00 PM IST",
]

export default function DemoClient() {
  const [form, setForm] = useState({
    name: "",
    email: "",
    phone: "",
    venueName: "",
    venueSize: "",
    message: "",
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    setForm({ ...form, [e.target.name]: e.target.value })
  }

  return (
    <>
      <PageHero
        title="See EventFlow in"
        highlight="Action"
        description="Book a personalised 30-minute walkthrough. We will show you how EventFlow fits your venue's unique workflow."
      />

      <section className="py-20 bg-slate-50/50">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid gap-12 lg:grid-cols-2">
            <div>
              <SectionHeader
                title="Tell Us About"
                highlight="Your Venue"
                description="Fill in the details and we will tailor the demo to your needs."
              />
              <form className="space-y-5 mt-8" onSubmit={(e) => e.preventDefault()}>
                <div>
                  <label htmlFor="name" className="block text-sm font-medium text-slate-900 mb-1">
                    Full Name <span className="text-red-500">*</span>
                  </label>
                  <input
                    id="name"
                    name="name"
                    type="text"
                    required
                    value={form.name}
                    onChange={handleChange}
                    className="block w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 placeholder-slate-400 focus:border-amber-500 focus:outline-none focus:ring-2 focus:ring-amber-500/20"
                    placeholder="Ravi Sharma"
                  />
                </div>
                <div>
                  <label htmlFor="email" className="block text-sm font-medium text-slate-900 mb-1">
                    Work Email <span className="text-red-500">*</span>
                  </label>
                  <input
                    id="email"
                    name="email"
                    type="email"
                    required
                    value={form.email}
                    onChange={handleChange}
                    className="block w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 placeholder-slate-400 focus:border-amber-500 focus:outline-none focus:ring-2 focus:ring-amber-500/20"
                    placeholder="ravi@myvenue.com"
                  />
                </div>
                <div>
                  <label htmlFor="phone" className="block text-sm font-medium text-slate-900 mb-1">
                    Phone Number <span className="text-red-500">*</span>
                  </label>
                  <input
                    id="phone"
                    name="phone"
                    type="tel"
                    required
                    value={form.phone}
                    onChange={handleChange}
                    className="block w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 placeholder-slate-400 focus:border-amber-500 focus:outline-none focus:ring-2 focus:ring-amber-500/20"
                    placeholder="+91 98765 43210"
                  />
                </div>
                <div>
                  <label htmlFor="venueName" className="block text-sm font-medium text-slate-900 mb-1">
                    Venue Name
                  </label>
                  <input
                    id="venueName"
                    name="venueName"
                    type="text"
                    value={form.venueName}
                    onChange={handleChange}
                    className="block w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 placeholder-slate-400 focus:border-amber-500 focus:outline-none focus:ring-2 focus:ring-amber-500/20"
                    placeholder="Grand Palace Banquets"
                  />
                </div>
                <div>
                  <label htmlFor="venueSize" className="block text-sm font-medium text-slate-900 mb-1">
                    Venue Size / Type
                  </label>
                  <select
                    id="venueSize"
                    name="venueSize"
                    value={form.venueSize}
                    onChange={handleChange}
                    className="block w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 focus:border-amber-500 focus:outline-none focus:ring-2 focus:ring-amber-500/20"
                  >
                    <option value="">Select an option</option>
                    {venueSizes.map((s) => (
                      <option key={s} value={s}>{s}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label htmlFor="message" className="block text-sm font-medium text-slate-900 mb-1">
                    Anything specific you want to see?
                  </label>
                  <textarea
                    id="message"
                    name="message"
                    rows={4}
                    value={form.message}
                    onChange={handleChange}
                    className="block w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 placeholder-slate-400 focus:border-amber-500 focus:outline-none focus:ring-2 focus:ring-amber-500/20 resize-y"
                    placeholder="We are particularly interested in..."
                  />
                </div>
                <button
                  type="submit"
                  className="inline-flex w-full items-center justify-center rounded-xl bg-amber-500 px-6 py-3.5 text-sm font-semibold text-slate-900 hover:bg-amber-600 transition-all hover:shadow-lg hover:shadow-amber-500/30"
                >
                  Book My Demo
                </button>
              </form>
            </div>

            <div className="space-y-10">
              <div>
                <SectionHeader
                  title="Pick Your Preferred"
                  highlight="Time Slot"
                  description="Choose a time that works for you. All demos are 30 minutes."
                />
                <div className="grid grid-cols-2 gap-2 mt-8">
                  {timeSlots.map((slot) => (
                    <label
                      key={slot}
                      className="flex cursor-pointer items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-xs text-slate-700 transition-all has-[:checked]:border-amber-500 has-[:checked]:bg-amber-50 has-[:checked]:text-amber-800"
                    >
                      <input type="radio" name="timeSlot" value={slot} className="accent-amber-500" />
                      {slot}
                    </label>
                  ))}
                </div>
                <p className="text-xs text-slate-500 mt-3">
                  All times are in Indian Standard Time (UTC +5:30). Need a different time? Leave a note in the message field.
                </p>
              </div>

              <div className="rounded-2xl border border-slate-200 bg-white p-6">
                <h3 className="text-base font-semibold text-slate-900 mb-3">Availability Preview</h3>
                <div className="rounded-lg border border-slate-100 bg-slate-50 p-4">
                  <div className="flex items-center justify-between mb-3">
                    <span className="text-xs font-medium text-slate-600">Today</span>
                    <span className="text-xs font-medium text-slate-600">
                      <svg className="inline h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 6.75h12M8.25 12h12m-12 5.25h12M3.75 6.75h.007v.008H3.75V6.75zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zM3.75 12h.007v.008H3.75V12zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm-.375 5.25h.007v.008H3.75v-.008zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z" />
                      </svg>
                      5 slots remaining
                    </span>
                  </div>
                  <div className="space-y-1.5">
                    <div className="h-2.5 rounded-full bg-amber-500 w-full" />
                    <div className="h-2.5 rounded-full bg-amber-500 w-3/4" />
                    <div className="h-2.5 rounded-full bg-amber-500 w-5/6" />
                    <div className="h-2.5 rounded-full bg-slate-200 w-2/3" />
                    <div className="h-2.5 rounded-full bg-slate-200 w-1/2" />
                  </div>
                  <div className="flex justify-between mt-2 text-[10px] text-slate-400">
                    <span>9 AM</span>
                    <span>12 PM</span>
                    <span>3 PM</span>
                    <span>6 PM</span>
                  </div>
                </div>
                <p className="text-xs text-slate-500 mt-3">
                  Our team runs demos Monday to Friday. Most slots go quickly — book early for the best availability.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="A Peek Inside"
            highlight="Your Dashboard"
            description="Here is what you will see after onboarding. Every screen is designed for clarity and speed."
          />
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {[
              {
                title: "Booking Dashboard",
                desc: "See all upcoming and pending bookings at a glance. Filter by venue, date, or status. Take action with one click.",
              },
              {
                title: "Calendar View",
                desc: "Drag-and-drop events across your venue spaces. Colour-coded by event type — weddings, corporate, social — so you never double-book.",
              },
              {
                title: "Lead Pipeline",
                desc: "Track every enquiry from first call to signed contract. Stage-based kanban view with deal value and probability.",
              },
              {
                title: "Payment Reconciliation",
                desc: "Match payments to invoices automatically. See outstanding balances and send payment reminders in bulk.",
              },
              {
                title: "Analytics Dashboard",
                desc: "Real-time KPIs for revenue, occupancy, lead conversion, and average event spend. Export reports with one click.",
              },
              {
                title: "Staff & Vendor Hub",
                desc: "Assign teams, track vendor contracts, and manage schedules from a single pane. Every event has a clear resource map.",
              },
            ].map((item) => (
              <div
                key={item.title}
                className="rounded-xl border border-slate-200 bg-white p-6 transition-all hover:-translate-y-1 hover:shadow-lg hover:shadow-amber-500/10"
              >
                <div className="mb-3 h-36 rounded-lg bg-gradient-to-br from-slate-100 to-slate-200 flex items-center justify-center border border-slate-200">
                  <span className="text-xs text-slate-400 font-medium uppercase tracking-wider">{item.title}</span>
                </div>
                <h3 className="text-base font-semibold text-slate-900">{item.title}</h3>
                <p className="mt-1 text-sm text-slate-600 leading-relaxed">{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <PageCTA
        title="Ready for a Personalised Tour?"
        highlight="Book Your Demo"
        description="No slides, no scripts. Just a live walkthrough of EventFlow configured for your venue."
        buttonText="Book a Demo"
        buttonHref="#top"
      />
    </>
  )
}
