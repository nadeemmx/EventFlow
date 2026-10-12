"use client"

import Link from "next/link"

/**
 * Privacy acknowledgement required by `POST /api/v1/contact/` and the
 * privacy request endpoint, plus an optional, unchecked-by-default
 * marketing opt-in (GDPR: consent must be a separate, explicit choice).
 */
export default function PrivacyConsent({
  idPrefix,
  ackChecked,
  onAckChange,
  ackError,
  marketingChecked,
  onMarketingChange,
  compact = false,
}: {
  idPrefix: string
  ackChecked: boolean
  onAckChange: (checked: boolean) => void
  ackError?: string
  marketingChecked?: boolean
  onMarketingChange?: (checked: boolean) => void
  compact?: boolean
}) {
  const ackId = `${idPrefix}-privacy-ack`
  const marketingId = `${idPrefix}-marketing-opt-in`

  return (
    <div className="space-y-3">
      <div className="flex items-start gap-3">
        <input
          id={ackId}
          type="checkbox"
          checked={ackChecked}
          onChange={(e) => onAckChange(e.target.checked)}
          aria-invalid={ackError ? true : undefined}
          aria-describedby={ackError ? `${ackId}-error` : undefined}
          className="mt-1 h-4 w-4 rounded border-slate-300 text-amber-500 focus:ring-amber-500"
        />
        <label htmlFor={ackId} className={`${compact ? "text-xs" : "text-sm"} text-slate-600`}>
          I have read the{" "}
          <Link href="/privacy-policy/" className="underline text-slate-900 hover:text-amber-700">
            Privacy Policy
          </Link>{" "}
          and agree that EventFlow may use these details to respond to my request.{" "}
          <span aria-hidden="true" className="text-slate-400">
            *
          </span>
        </label>
      </div>
      {ackError && (
        <p id={`${ackId}-error`} className="text-sm text-destructive" role="alert">
          {ackError}
        </p>
      )}

      {onMarketingChange && (
        <div className="flex items-start gap-3">
          <input
            id={marketingId}
            type="checkbox"
            checked={marketingChecked ?? false}
            onChange={(e) => onMarketingChange(e.target.checked)}
            className="mt-1 h-4 w-4 rounded border-slate-300 text-amber-500 focus:ring-amber-500"
          />
          <label htmlFor={marketingId} className={`${compact ? "text-xs" : "text-sm"} text-slate-600`}>
            Send me occasional product updates and event-industry tips.{" "}
            <span className="text-slate-500">(optional)</span>
          </label>
        </div>
      )}
    </div>
  )
}
