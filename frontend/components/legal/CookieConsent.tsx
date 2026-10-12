"use client"

import { useEffect, useRef, useState } from "react"
import Link from "next/link"
import { Cookie, Settings, X } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import {
  DEFAULT_CATEGORIES,
  OPEN_CONSENT_EVENT,
  type ConsentCategories,
  readConsent,
  writeConsent,
} from "@/lib/consent"

const CATEGORIES: {
  key: keyof ConsentCategories
  title: string
  description: string
  required?: boolean
}[] = [
  {
    key: "essential",
    title: "Strictly necessary",
    description:
      "Required for sign-in, security and core platform operation. These cannot be switched off.",
    required: true,
  },
  {
    key: "preferences",
    title: "Preferences",
    description:
      "Remembers choices such as your theme so the product looks the way you left it.",
  },
  {
    key: "analytics",
    title: "Analytics",
    description:
      "Helps us understand how the product is used. EventFlow does not currently load any analytics tools; this option is reserved for future use and stays off until you turn it on.",
  },
  {
    key: "marketing",
    title: "Marketing",
    description:
      "Used to measure advertising. EventFlow does not currently load any advertising or marketing trackers; this option is reserved for future use and stays off until you turn it on.",
  },
]

export default function CookieConsent() {
  const [visible, setVisible] = useState(false)
  const [managing, setManaging] = useState(false)
  const [categories, setCategories] = useState<ConsentCategories>(DEFAULT_CATEGORIES)
  const panelRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    const stored = readConsent()
    if (stored) {
      setCategories(stored.categories)
    } else {
      setVisible(true)
    }
    const open = () => {
      const current = readConsent()
      setCategories(current ? current.categories : DEFAULT_CATEGORIES)
      setManaging(true)
      setVisible(true)
      window.setTimeout(() => panelRef.current?.focus(), 0)
    }
    window.addEventListener(OPEN_CONSENT_EVENT, open)
    return () => window.removeEventListener(OPEN_CONSENT_EVENT, open)
  }, [])

  if (!visible) return null

  const save = (next: ConsentCategories) => {
    writeConsent(next)
    setCategories(next)
    setVisible(false)
    setManaging(false)
  }

  const toggle = (key: keyof ConsentCategories, checked: boolean) => {
    if (key === "essential") return
    setCategories((prev) => ({ ...prev, [key]: checked }))
  }

  return (
    <div
      ref={panelRef}
      tabIndex={-1}
      role="region"
      aria-label="Cookie consent"
      className="fixed inset-x-0 bottom-0 z-50 border-t border-slate-200 bg-white shadow-[0_-8px_24px_rgba(15,23,42,0.08)] focus:outline-none"
    >
      <div className="mx-auto max-w-5xl px-4 py-4 sm:px-6 sm:py-5">
        <div className="flex items-start justify-between gap-4">
          <div className="flex items-start gap-3">
            <Cookie className="mt-0.5 h-5 w-5 shrink-0 text-amber-500" aria-hidden="true" focusable="false" />
            <div>
              <h2 className="text-sm font-semibold text-slate-900">
                Your cookie and storage choices
              </h2>
              <p className="mt-1 text-sm text-slate-600">
                EventFlow uses strictly necessary storage to keep you signed in and to secure
                your account. Optional categories stay off unless you choose them — we do not
                use advertising trackers, and no optional tool is loaded before you decide.
                Read the{" "}
                <Link href="/cookie-policy/" className="underline text-slate-900">
                  Cookie Policy
                </Link>{" "}
                and{" "}
                <Link href="/privacy-policy/" className="underline text-slate-900">
                  Privacy Policy
                </Link>
                .
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => setVisible(false)}
            className="hidden rounded p-1 text-slate-500 hover:text-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-500 sm:block"
            aria-label="Close this banner without saving a choice; you will be asked again"
          >
            <X className="h-4 w-4" aria-hidden="true" focusable="false" />
          </button>
        </div>

        {managing && (
          <fieldset className="mt-4 space-y-3 border-t border-slate-200 pt-4">
            <legend className="px-1 text-sm font-semibold text-slate-900">
              Manage preferences
            </legend>
            {CATEGORIES.map((category) => (
              <div key={category.key} className="flex items-start gap-3">
                <Checkbox
                  id={`consent-${category.key}`}
                  checked={categories[category.key]}
                  disabled={category.required}
                  onCheckedChange={(checked) => toggle(category.key, checked === true)}
                  aria-describedby={`consent-${category.key}-desc`}
                />
                <div className="grid gap-1">
                  <label
                    htmlFor={`consent-${category.key}`}
                    className="text-sm font-medium leading-none text-slate-900 peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
                  >
                    {category.title}
                    {category.required && (
                      <span className="ml-2 text-xs font-normal text-slate-500">
                        always on
                      </span>
                    )}
                  </label>
                  <p id={`consent-${category.key}-desc`} className="text-xs text-slate-600">
                    {category.description}
                  </p>
                </div>
              </div>
            ))}
          </fieldset>
        )}

        <div className="mt-4 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-end">
          {!managing ? (
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="justify-center text-slate-700"
              onClick={() => setManaging(true)}
            >
              <Settings className="mr-2 h-4 w-4" aria-hidden="true" focusable="false" />
              Manage preferences
            </Button>
          ) : (
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="justify-center"
              onClick={() => save(categories)}
            >
              Save preferences
            </Button>
          )}
          <Button
            type="button"
            variant="outline"
            size="sm"
            className="justify-center"
            onClick={() => save({ ...DEFAULT_CATEGORIES, preferences: false })}
          >
            Reject non-essential
          </Button>
          <Button
            type="button"
            size="sm"
            className="justify-center"
            onClick={() =>
              save({
                essential: true,
                preferences: true,
                analytics: true,
                marketing: true,
              })
            }
          >
            Accept all
          </Button>
        </div>
      </div>
    </div>
  )
}

export function CookiePreferencesButton() {
  const open = () => {
    window.dispatchEvent(new CustomEvent(OPEN_CONSENT_EVENT))
  }
  return (
    <button
      type="button"
      onClick={open}
      className="text-sm text-slate-400 transition-colors hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-500"
    >
      Cookie preferences
    </button>
  )
}
