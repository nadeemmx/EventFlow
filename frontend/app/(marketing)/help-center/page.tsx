import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import { LifeBuoy } from "lucide-react"
import HelpCenterClient from "./HelpCenterClient"

export const metadata = createMetadata({
  title: "Help Center",
  description: "Find answers to common questions about EventFlow. Browse topics and get in touch with support.",
  path: "/help-center",
})

export default function HelpCenterPage() {
  return (
    <>
      <PageHero
        title="Help Center"
        highlight=""
        description="Find answers, get support, and make the most of EventFlow for your venue."
      />

      <HelpCenterClient />

      {/* Contact Support */}
      <section className="py-20">
        <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 text-center">
          <LifeBuoy className="w-12 h-12 text-amber-700 mx-auto mb-4" aria-hidden="true" focusable="false" />
          <h2 className="text-3xl font-bold text-slate-900 mb-2">Still need help?</h2>
          <p className="text-slate-600 mb-8 max-w-md mx-auto">
            Reach out and we will get back to you as soon as we can.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <a
              href="/contact"
              className="inline-flex items-center justify-center gap-2 rounded-xl bg-amber-500 px-7 py-3.5 text-base font-semibold text-slate-900 hover:bg-amber-600 transition-all"
            >
              Contact Support
            </a>
            <a
              href="mailto:support@eventflow.com"
              className="inline-flex items-center justify-center gap-2 rounded-xl border border-slate-200 px-7 py-3.5 text-base font-semibold text-slate-700 hover:bg-slate-50 transition-all"
            >
              Email us at support@eventflow.com
            </a>
          </div>
        </div>
      </section>

      <PageCTA
        title="Ready to simplify"
        highlight="venue management?"
        description="Bring bookings, payments, and operations into one place with EventFlow."
        buttonText="Create Your Account"
        buttonHref="/signup"
      />
    </>
  )
}
