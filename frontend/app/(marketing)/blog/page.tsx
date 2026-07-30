import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"

export const metadata = createMetadata({
  title: "Blog",
  description: "Insights and tips for event venue owners",
  path: "/blog",
})

const articles = [
  {
    title: "10 Ways to Increase Venue Bookings in 2026",
    excerpt: "Discover proven strategies to fill your calendar this year, from dynamic pricing and strategic partnerships to AI-powered lead scoring and automated follow-ups.",
    date: "Jun 15, 2026",
    category: "Growth",
    readTime: "8 min read",
    author: "Neha Kapoor",
  },
  {
    title: "The Complete Guide to Venue Management Software",
    excerpt: "Everything you need to know about choosing and implementing a venue management platform, including feature checklists, ROI calculations, and migration tips.",
    date: "Jun 10, 2026",
    category: "Operations",
    readTime: "12 min read",
    author: "Rahul Verma",
  },
  {
    title: "How to Automate Your Venue Booking Process",
    excerpt: "Learn how to eliminate manual booking workflows with automation rules, online self-service portals, and integrated calendar sync across all your channels.",
    date: "Jun 5, 2026",
    category: "Technology",
    readTime: "6 min read",
    author: "Vikram Joshi",
  },
  {
    title: "5 Revenue Streams Every Venue Owner Should Explore",
    excerpt: "Beyond basic rental fees, discover untapped revenue opportunities like vendor commissions, premium add-ons, event insurance, and recurring membership programs.",
    date: "May 28, 2026",
    category: "Growth",
    readTime: "7 min read",
    author: "Neha Kapoor",
  },
  {
    title: "Why Your Venue Needs a CRM System",
    excerpt: "A dedicated CRM helps you track leads, personalize communication, and build lasting relationships that turn first-time bookers into loyal repeat customers.",
    date: "May 20, 2026",
    category: "Marketing",
    readTime: "5 min read",
    author: "Ananya Patel",
  },
  {
    title: "The Future of Event Technology Trends",
    excerpt: "From AI-powered virtual tours to blockchain-based contract management, explore the emerging technologies that will shape the event venue industry in the coming years.",
    date: "May 12, 2026",
    category: "Technology",
    readTime: "9 min read",
    author: "Vikram Joshi",
  },
  {
    title: "How to Reduce No-Shows and Cancellations",
    excerpt: "Implement smart deposit policies, automated reminders, and flexible rescheduling options to minimize revenue loss from last-minute cancellations and no-shows.",
    date: "May 5, 2026",
    category: "Operations",
    readTime: "6 min read",
    author: "Ananya Patel",
  },
  {
    title: "Building a Premium Brand for Your Event Venue",
    excerpt: "Elevate your venue's brand with professional photography, compelling storytelling, consistent online presence, and a guest experience that earns five-star reviews.",
    date: "Apr 28, 2026",
    category: "Marketing",
    readTime: "7 min read",
    author: "Neha Kapoor",
  },
]

function BlogCard({ article }: { article: typeof articles[number] }) {
  return (
    <article className="group rounded-2xl border border-slate-200 bg-white overflow-hidden hover:border-amber-500/30 hover:shadow-lg hover:shadow-amber-500/5 transition-all">
      <div className="p-6 sm:p-8">
        <div className="flex items-center gap-3 mb-4">
          <span className="inline-block rounded-full bg-amber-500/10 px-3 py-1 text-xs font-semibold text-amber-700">
            {article.category}
          </span>
          <span className="text-xs text-slate-400">{article.date}</span>
        </div>
        <h3 className="text-lg font-bold text-slate-900 mb-2 group-hover:text-amber-600 transition-colors">
          {article.title}
        </h3>
        <p className="text-sm text-slate-600 leading-relaxed mb-4 line-clamp-3">
          {article.excerpt}
        </p>
        <div className="flex items-center justify-between text-xs text-slate-400">
          <span>By {article.author}</span>
          <span>{article.readTime}</span>
        </div>
      </div>
    </article>
  )
}

export default function BlogPage() {
  return (
    <>
      <PageHero
        title="Insights for Venue"
        highlight="Owners"
        description="Practical tips, industry trends, and expert advice to help you run a successful event venue."
      />

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {articles.map((article) => (
              <BlogCard key={article.title} article={article} />
            ))}
          </div>
        </div>
      </section>

      <PageCTA
        title="Stay Ahead of the Curve"
        highlight="Subscribe to Our Newsletter"
        description="Get the latest venue management insights delivered to your inbox every month."
        buttonText="Subscribe"
      />
    </>
  )
}
