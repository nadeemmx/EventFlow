import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"

export const metadata = createMetadata({
  title: "Blog",
  description: "Insights and tips for event venue owners",
  path: "/blog",
})

export default function BlogPage() {
  return (
    <>
      <PageHero
        title="Insights for Venue"
        highlight="Owners"
        description="Practical tips, industry trends, and advice to help you run a successful event venue."
      />

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="mx-auto max-w-2xl rounded-2xl border border-slate-200 bg-white p-8 sm:p-10 text-center">
            <span className="inline-block rounded-full bg-amber-500/10 px-3 py-1 text-xs font-semibold text-amber-700 mb-4">
              Coming soon
            </span>
            <h2 className="text-2xl font-bold text-slate-900 mb-3">Articles are on the way</h2>
            <p className="text-sm text-slate-600 leading-relaxed">
              We have not published anything here yet. When we do, every article will have a real
              author and a real date — nothing is being pre-filled. In the meantime, our{" "}
              <a href="/docs" className="font-medium text-amber-700 hover:text-amber-800 transition-colors">
                documentation
              </a>{" "}
              covers how EventFlow works, and you can reach us through the{" "}
              <a href="/help-center" className="font-medium text-amber-700 hover:text-amber-800 transition-colors">
                help center
              </a>
              .
            </p>
          </div>
        </div>
      </section>

      <PageCTA
        title="See What EventFlow Can Do"
        highlight="Read the Docs"
        description="Explore the documentation to learn how bookings, invoices, and payments work in EventFlow."
        buttonText="View Documentation"
        buttonHref="/docs"
      />
    </>
  )
}
