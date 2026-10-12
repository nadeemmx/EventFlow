export const CONSENT_VERSION = "1.0"
export const CONSENT_STORAGE_KEY = "eventflow_cookie_consent"
export const OPEN_CONSENT_EVENT = "eventflow:open-cookie-consent"

export type ConsentCategories = {
  essential: true
  preferences: boolean
  analytics: boolean
  marketing: boolean
}

export type ConsentRecord = {
  version: string
  timestamp: string
  categories: ConsentCategories
}

export const DEFAULT_CATEGORIES: ConsentCategories = {
  essential: true,
  preferences: false,
  analytics: false,
  marketing: false,
}

export function readConsent(): ConsentRecord | null {
  if (typeof window === "undefined") return null
  try {
    const raw = window.localStorage.getItem(CONSENT_STORAGE_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw) as ConsentRecord
    if (!parsed || typeof parsed !== "object" || !parsed.categories) return null
    return {
      version: parsed.version ?? CONSENT_VERSION,
      timestamp: parsed.timestamp ?? new Date().toISOString(),
      categories: { ...DEFAULT_CATEGORIES, ...parsed.categories, essential: true },
    }
  } catch {
    return null
  }
}

export function writeConsent(categories: ConsentCategories): ConsentRecord {
  const record: ConsentRecord = {
    version: CONSENT_VERSION,
    timestamp: new Date().toISOString(),
    categories: { ...categories, essential: true },
  }
  if (typeof window !== "undefined") {
    window.localStorage.setItem(CONSENT_STORAGE_KEY, JSON.stringify(record))
    window.dispatchEvent(new CustomEvent("eventflow:consent-changed", { detail: record }))
  }
  return record
}

/**
 * Consent check for optional technologies. Nothing may be loaded before a
 * stored consent record grants the relevant category.
 */
export function hasConsent(category: keyof ConsentCategories): boolean {
  if (category === "essential") return true
  const record = readConsent()
  return Boolean(record && record.categories[category])
}
