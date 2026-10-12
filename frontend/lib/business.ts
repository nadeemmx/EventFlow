/**
 * Business/legal configuration for EventFlow policy pages.
 *
 * Values come from NEXT_PUBLIC_* environment variables (inlined at build time).
 * Any value that has not been provided by the business owner renders as a
 * clearly marked placeholder — we never invent legal entity details.
 *
 * See .env.example for the full list.
 */

function env(name: string): string | undefined {
  const value = process.env[name]
  const trimmed = value?.trim()
  return trimmed ? trimmed : undefined
}

export const business = {
  /** Product / trading name — safe to use, it is the product itself. */
  brandName: "EventFlow",

  /** Legal entity name (must be provided by the owner — never invented). */
  legalName: env("NEXT_PUBLIC_BUSINESS_LEGAL_NAME"),

  /** Registered / published business address. */
  address: env("NEXT_PUBLIC_BUSINESS_ADDRESS"),

  /** Company registration or incorporation number, if applicable. */
  registrationNumber: env("NEXT_PUBLIC_BUSINESS_REGISTRATION_NUMBER"),

  /** Tax identifier (e.g. GSTIN) — only if verified. */
  taxId: env("NEXT_PUBLIC_BUSINESS_TAX_ID"),

  supportEmail: env("NEXT_PUBLIC_BUSINESS_SUPPORT_EMAIL") ?? "support@eventflow.com",
  privacyEmail: env("NEXT_PUBLIC_BUSINESS_PRIVACY_EMAIL") ?? "privacy@eventflow.com",
  refundsEmail: env("NEXT_PUBLIC_BUSINESS_REFUNDS_EMAIL") ?? "support@eventflow.com",
  generalEmail: env("NEXT_PUBLIC_BUSINESS_GENERAL_EMAIL") ?? "hello@eventflow.com",
  phone: env("NEXT_PUBLIC_BUSINESS_PHONE"),

  /** Governing law / jurisdiction for Terms (must be provided by the owner). */
  jurisdiction: env("NEXT_PUBLIC_BUSINESS_JURISDICTION"),

  /** Court venue for disputes (must be provided by the owner). */
  disputeVenue: env("NEXT_PUBLIC_BUSINESS_DISPUTE_VENUE"),

  /** Effective date shown on policy pages. */
  policyEffectiveDate:
    env("NEXT_PUBLIC_BUSINESS_POLICY_EFFECTIVE_DATE") ?? "2026-09-25",
} as const

/** True when a legally significant value has not been supplied yet. */
export function needsOwnerInput(value: string | undefined): value is undefined {
  return value === undefined
}

/**
 * Returns the value, or a visible marker when the owner has not supplied it.
 * Use with <BusinessField> so the marker is styled as an obvious placeholder.
 */
export function businessValue(value: string | undefined, label: string): string {
  return value ?? `[${label} — to be provided by EventFlow]`
}
