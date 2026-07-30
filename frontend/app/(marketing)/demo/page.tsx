import { createMetadata } from "@/lib/seo"
import DemoClient from "./DemoClient"

export const metadata = createMetadata({
  title: "Book a Demo",
  description: "See EventFlow in action. Schedule a personalised walkthrough with our product team.",
  path: "/demo",
})

export default function DemoPage() {
  return <DemoClient />
}
