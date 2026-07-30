import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import {
  Search,
  BookOpen,
  CreditCard,
  Calendar,
  Settings,
  LifeBuoy,
  Puzzle,
  ArrowRight,
} from "lucide-react"

export const metadata = createMetadata({
  title: "Help Center",
  description: "Find answers to common questions about EventFlow. Browse knowledge base articles, guides, and tutorials for venue management.",
  path: "/help-center",
})

const categories = [
  { icon: BookOpen, title: "Getting Started", count: 12, color: "text-amber-500" },
  { icon: CreditCard, title: "Account & Billing", count: 8, color: "text-emerald-500" },
  { icon: Calendar, title: "Bookings", count: 15, color: "text-blue-500" },
  { icon: Settings, title: "Payments", count: 9, color: "text-purple-500" },
  { icon: Puzzle, title: "Integrations", count: 11, color: "text-cyan-500" },
  { icon: LifeBuoy, title: "Troubleshooting", count: 14, color: "text-red-500" },
]

const popularArticles = [
  {
    title: "How to Create Your First Booking",
    brief: "Step-by-step guide to setting up a venue profile and accepting your first booking request.",
  },
  {
    title: "Understanding Payment Processing & Fees",
    brief: "Learn how payments work, processing times, and how to view your transaction history.",
  },
  {
    title: "Setting Up Webhook Notifications",
    brief: "Configure real-time webhooks to receive booking confirmations, cancellations, and payment events.",
  },
  {
    title: "Managing Multiple Venue Locations",
    brief: "Tips for organizing and managing multiple event spaces under a single EventFlow account.",
  },
  {
    title: "Cancellation & Refund Policies",
    brief: "How to configure automatic cancellation policies, refund rules, and deposit requirements.",
  },
  {
    title: "Integrating with Your Website",
    brief: "Embed EventFlow booking widgets directly into your existing website with a few lines of code.",
  },
]

export default function HelpCenterPage() {
  return (
    <>
      <PageHero
        title="Help Center"
        highlight=""
        description="Find answers, get support, and make the most of EventFlow for your venue."
      />

      {/* Search */}
      <section className="pb-16 bg-slate-50/50">
        <div className="mx-auto max-w-2xl px-4 sm:px-6 lg:px-8 -mt-8">
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
            <input
              type="text"
              placeholder="Search articles, guides, and tutorials..."
              className="w-full pl-12 pr-4 py-4 rounded-xl border border-slate-200 bg-white shadow-sm text-sm focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500"
            />
          </div>
        </div>
      </section>

      {/* Categories */}
      <section className="py-16">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
              Browse by <span className="text-gradient">Category</span>
            </h2>
            <p className="mt-3 text-slate-600 max-w-xl mx-auto">
              Find the right help topic organized by category.
            </p>
          </div>

          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {categories.map((cat) => (
              <a
                key={cat.title}
                href="#"
                className="bg-white rounded-xl border border-slate-200 p-6 hover:border-amber-500/40 hover:shadow-lg transition-all group"
              >
                <cat.icon className={`w-8 h-8 ${cat.color} mb-3`} />
                <h3 className="font-semibold text-slate-900 mb-1 group-hover:text-amber-600 transition-colors">
                  {cat.title}
                </h3>
                <p className="text-sm text-slate-500">{cat.count} articles</p>
              </a>
            ))}
          </div>
        </div>
      </section>

      {/* Popular Articles */}
      <section className="py-16 bg-slate-50/50">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
              Popular <span className="text-gradient">Articles</span>
            </h2>
            <p className="mt-3 text-slate-600 max-w-xl mx-auto">
              Our most-read help articles to get you started quickly.
            </p>
          </div>

          <div className="grid sm:grid-cols-2 gap-6">
            {popularArticles.map((article) => (
              <a
                key={article.title}
                href="#"
                className="bg-white rounded-xl border border-slate-200 p-6 hover:border-amber-500/40 hover:shadow-md transition-all group"
              >
                <h3 className="font-semibold text-slate-900 mb-1 group-hover:text-amber-600 transition-colors">
                  {article.title}
                </h3>
                <p className="text-sm text-slate-600">{article.brief}</p>
                <span className="inline-flex items-center gap-1 text-sm text-amber-600 font-medium mt-3 group-hover:gap-2 transition-all">
                  Read more <ArrowRight className="w-3 h-3" />
                </span>
              </a>
            ))}
          </div>
        </div>
      </section>

      {/* Contact Support */}
      <section className="py-20">
        <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 text-center">
          <LifeBuoy className="w-12 h-12 text-amber-500 mx-auto mb-4" />
          <h2 className="text-3xl font-bold text-slate-900 mb-2">Still need help?</h2>
          <p className="text-slate-600 mb-8 max-w-md mx-auto">
            Our support team is available 24/7. Reach out and we will get back to you within 2 hours.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <a
              href="#"
              className="inline-flex items-center justify-center gap-2 rounded-xl bg-amber-500 px-7 py-3.5 text-base font-semibold text-slate-900 hover:bg-amber-600 transition-all"
            >
              Contact Support
            </a>
            <a
              href="#"
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
        description="Join thousands of venues using EventFlow to streamline bookings, payments, and operations."
        buttonText="Get Started Free"
        buttonHref="/login"
      />
    </>
  )
}
