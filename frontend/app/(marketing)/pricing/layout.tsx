import { createMetadata } from "@/lib/seo"

export const metadata = createMetadata({
  title: "Pricing",
  description: "Simple, transparent pricing for event venues of every size",
  path: "/pricing",
})

export default function PricingLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return children
}
