"use client"

import { useState } from "react"
import { Bell, CheckCircle2 } from "lucide-react"

import { submitContactJson } from "@/lib/contact"
import PrivacyConsent from "@/components/legal/PrivacyConsent"

export default function StatusSubscribe() {
  const [email, setEmail] = useState("")
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
    setSubmitting(true)
    try {
      const ref = await submitContactJson({
        source: "status",
        name: "Status subscriber",
        email,
        subject: "Status updates subscription",
        message: "Please send me notifications about incidents and scheduled maintenance.",
        privacy_acknowledged: true,
      })
      setReference(ref)
    } catch (err) {
      setError(err instanceof Error ? err.message : "We could not subscribe you right now.")
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <section className="py-16 bg-slate-50/50">
      <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 text-center">
        <Bell className="w-10 h-10 text-amber-500 mx-auto mb-4" aria-hidden="true" focusable="false" />
        <h2 className="text-2xl font-bold text-slate-900 mb-2">Ask for status updates</h2>
        <p className="text-slate-600 mb-6 max-w-md mx-auto">
          Leave your email and we will notify you about incidents and maintenance.
        </p>

        {reference ? (
          <div
            role="status"
            aria-live="polite"
            className="mx-auto max-w-md rounded-2xl border border-slate-200 bg-white p-6"
          >
            <CheckCircle2 className="mx-auto mb-2 h-6 w-6 text-green-600" aria-hidden="true" focusable="false" />
            <p className="text-sm text-slate-700">
              Thanks — your request has been recorded. Reference:{" "}
              <strong className="font-mono">{reference}</strong>.
            </p>
          </div>
        ) : (
          <form className="mx-auto max-w-md space-y-4 text-left" onSubmit={handleSubmit} noValidate>
            {error && (
              <div role="alert" className="rounded-md bg-destructive/10 p-3 text-sm text-destructive text-center">
                {error}
              </div>
            )}
            <div className="flex flex-col sm:flex-row gap-3">
              <label htmlFor="status-email" className="sr-only">
                Email address
              </label>
              <input
                id="status-email"
                type="email"
                required
                autoComplete="email"
                placeholder="your@email.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="flex-1 px-4 py-3 rounded-xl border border-slate-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-amber-500/50"
              />
              <button
                type="submit"
                disabled={submitting}
                className="inline-flex items-center justify-center gap-2 rounded-xl bg-amber-500 px-6 py-3 text-sm font-semibold text-slate-900 hover:bg-amber-600 transition-all disabled:opacity-60"
              >
                {submitting ? "Sending…" : "Request updates"}
              </button>
            </div>
            <PrivacyConsent
              idPrefix="status"
              ackChecked={ack}
              onAckChange={(checked) => {
                setAck(checked)
                if (checked) setAckError(undefined)
              }}
              ackError={ackError}
              compact
            />
          </form>
        )}
      </div>
    </section>
  )
}
