"use client"

import { useRef, useState } from "react"
import { Upload } from "lucide-react"

import { submitContactForm } from "@/lib/contact"
import PrivacyConsent from "@/components/legal/PrivacyConsent"

const inputClass =
  "w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-500/30 focus:border-amber-500"
const labelClass = "block text-sm font-medium text-slate-900 mb-1.5"

export default function CareersApplyForm({ positions }: { positions: string[] }) {
  const [name, setName] = useState("")
  const [email, setEmail] = useState("")
  const [role, setRole] = useState("")
  const [note, setNote] = useState("")
  const [resume, setResume] = useState<File | null>(null)
  const [ack, setAck] = useState(false)
  const [ackError, setAckError] = useState<string | undefined>()
  const [error, setError] = useState<string | null>(null)
  const [reference, setReference] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    if (!ack) {
      setAckError("Please confirm you have read the privacy notice.")
      return
    }
    setAckError(undefined)

    const formData = new FormData()
    formData.append("source", "careers")
    formData.append("name", name)
    formData.append("email", email)
    formData.append("subject", role ? `Application — ${role}` : "General application")
    formData.append("message", note.trim() || `Application for ${role || "an open position"}.`)
    formData.append("privacy_acknowledged", "true")
    if (resume) formData.append("resume", resume)

    setSubmitting(true)
    try {
      const ref = await submitContactForm(formData)
      setReference(ref)
    } catch (err) {
      setError(err instanceof Error ? err.message : "We could not submit your application.")
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
        <h3 className="text-lg font-semibold text-slate-900">Application received</h3>
        <p className="mt-2 text-sm text-slate-600">
          Thanks for applying. Reference: <strong className="font-mono">{reference}</strong>. We
          will get back to you by email.
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
          <label htmlFor="careers-name" className={labelClass}>
            Full Name <span aria-hidden="true" className="text-red-500">*</span>
          </label>
          <input
            id="careers-name"
            type="text"
            required
            autoComplete="name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className={inputClass}
            placeholder="Your full name"
          />
        </div>
        <div>
          <label htmlFor="careers-email" className={labelClass}>
            Email <span aria-hidden="true" className="text-red-500">*</span>
          </label>
          <input
            id="careers-email"
            type="email"
            required
            autoComplete="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className={inputClass}
            placeholder="you@example.com"
          />
        </div>
      </div>
      <div>
        <label htmlFor="careers-role" className={labelClass}>
          Role <span className="text-slate-500">(optional)</span>
        </label>
        <select
          id="careers-role"
          value={role}
          onChange={(e) => setRole(e.target.value)}
          className={inputClass}
        >
          <option value="">Select a position</option>
          {positions.map((title) => (
            <option key={title} value={title}>
              {title}
            </option>
          ))}
          <option value="General application">Not listed — general application</option>
        </select>
      </div>
      <div>
        <label htmlFor="careers-note" className={labelClass}>
          Note <span className="text-slate-500">(optional)</span>
        </label>
        <textarea
          id="careers-note"
          rows={3}
          maxLength={5000}
          value={note}
          onChange={(e) => setNote(e.target.value)}
          className={`${inputClass} resize-none`}
          placeholder="A short intro, links to your portfolio or LinkedIn"
        />
      </div>
      <div>
        <span className={labelClass}>
          Resume / CV <span className="text-slate-500">(PDF, optional)</span>
        </span>
        <div className="rounded-xl border border-dashed border-slate-200 bg-white px-4 py-6 text-center">
          <input
            id="careers-resume"
            ref={fileInputRef}
            type="file"
            accept="application/pdf,.pdf"
            className="sr-only"
            onChange={(e) => setResume(e.target.files?.[0] ?? null)}
          />
          <label htmlFor="careers-resume" className="inline-flex cursor-pointer items-center gap-2 text-sm text-slate-600 hover:text-slate-900">
            <Upload className="h-4 w-4" aria-hidden="true" focusable="false" />
            {resume ? resume.name : "Choose a PDF file"}
          </label>
          <p className="mt-1 text-xs text-slate-500">
            {resume
              ? "Click to choose a different file"
              : "We only accept PDF resumes (max 10 MB)"}
          </p>
          {resume && (
            <button
              type="button"
              onClick={() => {
                setResume(null)
                if (fileInputRef.current) fileInputRef.current.value = ""
              }}
              className="mt-2 text-xs text-slate-500 underline hover:text-slate-700"
            >
              Remove file
            </button>
          )}
        </div>
      </div>

      <PrivacyConsent
        idPrefix="careers"
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
        className="w-full rounded-xl bg-amber-500 px-6 py-3 text-sm font-semibold text-slate-900 hover:bg-amber-600 transition-all disabled:opacity-60"
      >
        {submitting ? "Submitting…" : "Submit Application"}
      </button>
    </form>
  )
}
