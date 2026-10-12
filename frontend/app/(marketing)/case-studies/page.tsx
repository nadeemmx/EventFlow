import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import SectionHeader from "@/components/marketing/SectionHeader"

export const metadata = createMetadata({
  title: "Customers",
  description: "Customer stories from event venue businesses using EventFlow.",
  path: "/case-studies",
})

export default function CustomersPage() {
  return (
    <>
      <PageHero
        title="Customer"
        highlight="Case Studies"
        description="See how event venue businesses use EventFlow to manage bookings, payments, and customer relationships."
      />

      <section className="bg-slate-50/50 py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Customer Success Stories"
            description="Written case studies are being prepared"
          />
          <div className="mx-auto max-w-2xl rounded-2xl border border-slate-200 bg-white p-8 sm:p-10 text-center">
            <h3 className="text-xl font-bold text-slate-900 mb-3">Case studies coming soon</h3>
            <p className="text-sm text-slate-600 leading-relaxed">
              We are still writing up customer stories with verified results. We will only publish
              figures that a customer has approved, so there is nothing to show here yet. If you
              use EventFlow and would like to take part, email{" "}
              <a
                href="mailto:hello@eventflow.com"
                className="font-medium text-amber-700 hover:text-amber-800 transition-colors"
              >
                hello@eventflow.com
              </a>
              .
            </p>
          </div>
        </div>
      </section>

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Customer stories"
            description="Quotes are collected directly from the people who use EventFlow"
          />
          <div className="mx-auto max-w-2xl rounded-2xl border border-slate-200 bg-white p-8 sm:p-10 text-center">
            <p className="text-sm text-slate-600 leading-relaxed">
              Customer stories are being collected — email us at{" "}
              <a
                href="mailto:hello@eventflow.com"
                className="font-medium text-amber-700 hover:text-amber-800 transition-colors"
              >
                hello@eventflow.com
              </a>{" "}
              if you would like to be featured. We do not publish attributed quotes or numbers we
              cannot verify.
            </p>
          </div>
        </div>
      </section>

      <PageCTA
        title="Try EventFlow With Your Venue"
        highlight="Get Started Today"
        description="Create an account and see how EventFlow fits the way your venue works."
      />
    </>
  )
}
