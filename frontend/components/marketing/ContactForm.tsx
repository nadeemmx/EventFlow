"use client"

import { useState } from "react"
import { Send } from "lucide-react"

import { submitContactJson } from "@/lib/contact"
import PrivacyConsent from "@/components/legal/PrivacyConsent"

const inputClass =
  "w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-500/30 focus:border-amber-500"
const labelClass = "block text-sm font-medium text-slate-900 mb-1.5"

export default function ContactForm() {
  const [form, setForm] = useState({
    name: "",
    email: "",
    company: "",
    phone: "",
    subject: "",
    message: "",
  })
  const [ack, setAck] = useState(false)
  const [marketing, setMarketing] = useState(false)
  const [ackError, setAckError] = useState<string | undefined>()
  const [error, setError] = useState<string | null>(null)
  const [reference, setReference] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>
  ) => {
    setForm({ ...form, [e.target.name]: e.target.value })
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    if (!ack) {
      setAckError("Please confirm you have read the privacy notice.")
      return
    }
    setAckError(undefined)
    setSubmitting(true)
    try {
      const ref = await submitContactJson({
        source: "contact",
        name: form.name,
        email: form.email,
        company: form.company,
        phone: form.phone,
        subject: form.subject,
        message: form.message,
        privacy_acknowledged: true,
        marketing_opt_in: marketing,
      })
      setReference(ref)
      setForm({ name: "", email: "", company: "", phone: "", subject: "", message: "" })
      setMarketing(false)
    } catch (err) {
      setError(err instanceof Error ? err.message : "We could not send your message.")
    } finally {
      setSubmitting(false)
    }
  }

  if (reference) {
    return (
      <div
        role="status"
        aria-live="polite"
        className="rounded-2xl border border-slate-200 bg-white p-8 text-center"
      >
        <h3 className="text-lg font-semibold text-slate-900">Message sent</h3>
        <p className="mt-2 text-sm text-slate-600">
          Thanks — we have received your message. Reference:{" "}
          <strong className="font-mono">{reference}</strong>. We will reply by email.
        </p>
      </div>
    )
  }

  return (
    <form className="space-y-5" onSubmit={handleSubmit} noValidate>
      {error && (
        <div role="alert" className="rounded-md bg-destructive/10 p-3 text-sm text-destructive">
          {error}
        </div>
      )}
      <div className="grid gap-5 sm:grid-cols-2">
        <div>
          <label htmlFor="name" className={labelClass}>
            Name <span aria-hidden="true" className="text-red-500">*</span>
          </label>
          <input
            id="name"
            name="name"
            type="text"
            required
            autoComplete="name"
            value={form.name}
            onChange={handleChange}
            className={inputClass}
            placeholder="Your name"
          />
        </div>
        <div>
          <label htmlFor="email" className={labelClass}>
            Email <span aria-hidden="true" className="text-red-500">*</span>
          </label>
          <input
            id="email"
            name="email"
            type="email"
            required
            autoComplete="email"
            value={form.email}
            onChange={handleChange}
            className={inputClass}
            placeholder="you@example.com"
          />
        </div>
      </div>
      <div className="grid gap-5 sm:grid-cols-2">
        <div>
          <label htmlFor="company" className={labelClass}>
            Company <span className="text-slate-500">(optional)</span>
          </label>
          <input
            id="company"
            name="company"
            type="text"
            autoComplete="organization"
            value={form.company}
            onChange={handleChange}
            className={inputClass}
            placeholder="Your venue name"
          />
        </div>
        <div>
          <label htmlFor="phone" className={labelClass}>
            Phone <span className="text-slate-500">(optional)</span>
          </label>
          <input
            id="phone"
            name="phone"
            type="tel"
            autoComplete="tel"
            value={form.phone}
            onChange={handleChange}
            className={inputClass}
            placeholder="+91 98765 43210"
          />
        </div>
      </div>
      <div>
        <label htmlFor="subject" className={labelClass}>
          Subject <span className="text-slate-500">(optional)</span>
        </label>
        <select
          id="subject"
          name="subject"
          value={form.subject}
          onChange={handleChange}
          className={inputClass}
        >
          <option value="">Select a subject</option>
          <option value="General Inquiry">General Inquiry</option>
          <option value="Sales & Pricing">Sales &amp; Pricing</option>
          <option value="Technical Support">Technical Support</option>
          <option value="Partnership Opportunities">Partnership Opportunities</option>
          <option value="Request a Demo">Request a Demo</option>
        </select>
      </div>
      <div>
        <label htmlFor="message" className={labelClass}>
          Message <span aria-hidden="true" className="text-red-500">*</span>
        </label>
        <textarea
          id="message"
          name="message"
          rows={5}
          required
          maxLength={5000}
          value={form.message}
          onChange={handleChange}
          className={`${inputClass} resize-none`}
          placeholder="Tell us how we can help you..."
        />
      </div>

      <PrivacyConsent
        idPrefix="contact"
        ackChecked={ack}
        onAckChange={(checked) => {
          setAck(checked)
          if (checked) setAckError(undefined)
        }}
        ackError={ackError}
        marketingChecked={marketing}
        onMarketingChange={setMarketing}
      />

      <button
        type="submit"
        disabled={submitting}
        className="inline-flex w-full sm:w-auto items-center justify-center gap-2 rounded-xl bg-amber-500 px-8 py-3 text-sm font-semibold text-slate-900 hover:bg-amber-600 transition-all disabled:opacity-60"
      >
        {submitting ? (
          <span className="flex items-center gap-2">
            <span className="h-4 w-4 animate-spin rounded-full border-2 border-slate-900/30 border-t-slate-900" />
            Sending…
          </span>
        ) : (
          <span className="flex items-center gap-2">
            <Send className="h-4 w-4" aria-hidden="true" focusable="false" />
            Send Message
          </span>
        )}
      </button>
    </form>
  )
}
