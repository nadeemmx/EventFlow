"use client"

import { useState } from "react"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import SectionHeader from "@/components/marketing/SectionHeader"
import PrivacyConsent from "@/components/legal/PrivacyConsent"
import { submitContactJson } from "@/lib/contact"

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
  const [timeSlot, setTimeSlot] = useState("")
  const [ack, setAck] = useState(false)
  const [ackError, setAckError] = useState<string | undefined>()
  const [error, setError] = useState<string | null>(null)
  const [reference, setReference] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    if (!ack) {
      setAckError("Please confirm you have read the privacy notice.")
      return
    }
    setAckError(undefined)
    const details = [
      form.message,
      form.venueSize ? `Venue size: ${form.venueSize}` : "",
      timeSlot ? `Preferred time slot: ${timeSlot}` : "",
    ]
      .filter(Boolean)
      .join("\n\n")
    setSubmitting(true)
    try {
      const ref = await submitContactJson({
        source: "demo",
        name: form.name,
        email: form.email,
        phone: form.phone,
        company: form.venueName,
        subject: "Demo request",
        message: details || "Please get in touch to schedule a demo.",
        privacy_acknowledged: true,
      })
      setReference(ref)
    } catch (err) {
      setError(err instanceof Error ? err.message : "We could not submit your request.")
    } finally {
      setSubmitting(false)
    }
  }

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
              <form className="space-y-5 mt-8" onSubmit={handleSubmit} noValidate>
                {reference ? (
                  <div role="status" aria-live="polite" className="rounded-xl border border-slate-200 bg-white p-6 text-center">
                    <h3 className="text-base font-semibold text-slate-900">Request received</h3>
                    <p className="mt-2 text-sm text-slate-600">
                      Thanks — your reference is <strong className="font-mono">{reference}</strong>.
                      We will email you to confirm a time slot.
                    </p>
                  </div>
                ) : null}
                {error && (
                  <div role="alert" className="rounded-md bg-destructive/10 p-3 text-sm text-destructive">
                    {error}
                  </div>
                )}
                <div>
                  <label htmlFor="name" className="block text-sm font-medium text-slate-900 mb-1">
                    Full Name <span className="text-red-500" aria-hidden="true">*</span>
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
                    Work Email <span className="text-red-500" aria-hidden="true">*</span>
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
                    Phone Number <span className="text-red-500" aria-hidden="true">*</span>
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
                <PrivacyConsent
                  idPrefix="demo"
                  ackChecked={ack}
                  onAckChange={(checked) => {
                    setAck(checked)
                    if (checked) setAckError(undefined)
                  }}
                  ackError={ackError}
                  compact
                />
                <button
                  type="submit"
                  disabled={submitting}
                  className="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-amber-500 px-6 py-3.5 text-sm font-semibold text-slate-900 hover:bg-amber-600 transition-all hover:shadow-lg hover:shadow-amber-500/30 disabled:opacity-60"
                >
                  {submitting ? "Submitting…" : "Book My Demo"}
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
                <fieldset className="mt-8">
                  <legend className="sr-only">Preferred demo time</legend>
                  <div className="grid grid-cols-2 gap-2">
                    {timeSlots.map((slot) => (
                      <label
                        key={slot}
                        className="flex cursor-pointer items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-xs text-slate-700 transition-all has-[:checked]:border-amber-500 has-[:checked]:bg-amber-50 has-[:checked]:text-amber-800"
                      >
                        <input
                          type="radio"
                          name="timeSlot"
                          value={slot}
                          checked={timeSlot === slot}
                          onChange={() => setTimeSlot(slot)}
                          className="accent-amber-500"
                        />
                        {slot}
                      </label>
                    ))}
                  </div>
                </fieldset>
                <p className="text-xs text-slate-500 mt-3">
                  All times are in Indian Standard Time (UTC +5:30). Need a different time? Leave a note in the message field.
                </p>
              </div>

              <div className="rounded-2xl border border-slate-200 bg-white p-6">
                <h3 className="text-base font-semibold text-slate-900 mb-3">How it works</h3>
                <ol className="list-decimal space-y-2 pl-5 text-sm text-slate-600">
                  <li>You send the form with a preferred time slot.</li>
                  <li>We confirm the slot by email (slots are subject to availability).</li>
                  <li>We run a 30-minute walkthrough tailored to your venue.</li>
                </ol>
                <p className="text-xs text-slate-500 mt-3">
                  Demo slots are handled by our team, Monday to Friday. Pick a time above or leave
                  a note in the message field.
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
                desc: "See your bookings on a calendar, colour-coded by event type — weddings, corporate, social — so gaps are easy to spot.",
              },
              {
                title: "Lead Pipeline",
                desc: "Track every enquiry from first contact to signed contract, with notes and follow-ups attached to each lead.",
              },
              {
                title: "Payment Reconciliation",
                desc: "Match payments to invoices and see outstanding balances, and send payment reminders to customers.",
              },
              {
                title: "Analytics Dashboard",
                desc: "Reports for revenue, occupancy, and lead conversion, with CSV export.",
              },
              {
                title: "Staff & Vendor Hub",
                desc: "Assign team tasks and track vendor contracts from a single place.",
              },
            ].map((item) => (
              <div
                key={item.title}
                className="rounded-xl border border-slate-200 bg-white p-6 transition-all hover:-translate-y-1 hover:shadow-lg hover:shadow-amber-500/10"
              >
                <div className="mb-3 h-36 rounded-lg bg-gradient-to-br from-slate-100 to-slate-200 flex items-center justify-center border border-slate-200">
                  <span className="text-xs text-slate-500 font-medium uppercase tracking-wider">{item.title}</span>
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
        buttonHref="/contact/"
      />
    </>
  )
}
