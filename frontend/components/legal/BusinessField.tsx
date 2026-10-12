import { business, businessValue } from "@/lib/business"

/**
 * Renders a business detail from lib/business.ts.
 * Missing owner-supplied values are shown as an obvious placeholder so that
 * placeholder legal information can never be mistaken for real company data.
 */
export default function BusinessField({
  value,
  label,
  className = "",
}: {
  value?: string
  label: string
  className?: string
}) {
  const resolved = value ?? businessValue(undefined, label)
  const isPlaceholder = value === undefined

  if (!isPlaceholder) {
    return <span className={className}>{resolved}</span>
  }

  return (
    <span
      className={`rounded border border-dashed border-amber-500/70 bg-amber-50 px-1.5 py-0.5 font-medium text-amber-700 ${className}`}
      title="This detail has not been provided by the business owner yet."
    >
      {resolved}
    </span>
  )
}

export function supportEmail() {
  return business.supportEmail
}
