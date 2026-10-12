"use client"

import { useMemo, useState } from "react"
import {
  Search,
  BookOpen,
  CreditCard,
  Calendar,
  Settings,
  LifeBuoy,
  Puzzle,
} from "lucide-react"

const categories = [
  { icon: BookOpen, title: "Getting Started", blurb: "Set up your venues, team, and account.", color: "text-amber-700" },
  { icon: CreditCard, title: "Account & Billing", blurb: "Plans, invoices, and subscription questions.", color: "text-emerald-700" },
  { icon: Calendar, title: "Bookings", blurb: "Create, edit, and manage bookings.", color: "text-blue-700" },
  { icon: Settings, title: "Payments", blurb: "Razorpay payments, refunds, and records.", color: "text-purple-700" },
  { icon: Puzzle, title: "Integrations", blurb: "Email, WhatsApp, and the REST API.", color: "text-cyan-700" },
  { icon: LifeBuoy, title: "Troubleshooting", blurb: "Common problems and how to resolve them.", color: "text-red-700" },
]

const topics = [
  {
    title: "How to Create Your First Booking",
    brief: "Step-by-step guide to setting up a venue profile and accepting your first booking request.",
  },
  {
    title: "Understanding Payment Processing & Fees",
    brief: "Learn how payments work, processing times, and how to view your transaction history.",
  },
  {
    title: "Setting Up Notifications",
    brief: "Configure email and WhatsApp notifications for booking confirmations, cancellations, and payment events.",
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
    brief: "Link your website to EventFlow and use the REST API for custom integrations.",
  },
]

const matches = (haystack: string, needle: string) =>
  haystack.toLowerCase().includes(needle.trim().toLowerCase())

export default function HelpCenterClient() {
  const [query, setQuery] = useState("")

  const filteredCategories = useMemo(
    () =>
      query.trim()
        ? categories.filter((c) => matches(`${c.title} ${c.blurb}`, query))
        : categories,
    [query],
  )
  const filteredTopics = useMemo(
    () =>
      query.trim() ? topics.filter((t) => matches(`${t.title} ${t.brief}`, query)) : topics,
    [query],
  )

  const statusText = query.trim()
    ? `${filteredCategories.length} ${
        filteredCategories.length === 1 ? "category" : "categories"
      } and ${filteredTopics.length} ${filteredTopics.length === 1 ? "topic" : "topics"} found.`
    : `Showing all ${categories.length} categories and ${topics.length} topics.`

  return (
    <>
      {/* Search */}
      <section className="pb-16 bg-slate-50/50">
        <div className="mx-auto max-w-2xl px-4 sm:px-6 lg:px-8 -mt-8">
          <div className="relative">
            <Search
              className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-500"
              aria-hidden="true"
              focusable="false"
            />
            <input
              type="search"
              id="help-center-search"
              aria-label="Search help center topics"
              placeholder="Search topics and guides..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="w-full pl-12 pr-4 py-4 rounded-xl border border-slate-200 bg-white shadow-sm text-sm focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500"
            />
          </div>
          <p role="status" aria-live="polite" className="mt-3 text-sm text-slate-600">
            {statusText}
          </p>
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

          {filteredCategories.length === 0 ? (
            <p className="text-center text-sm text-slate-600">
              No categories match your search.
            </p>
          ) : (
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {filteredCategories.map((cat) => (
                <div
                  key={cat.title}
                  className="bg-white rounded-xl border border-slate-200 p-6"
                >
                  <cat.icon
                    className={`w-8 h-8 ${cat.color} mb-3`}
                    aria-hidden="true"
                    focusable="false"
                  />
                  <h3 className="font-semibold text-slate-900 mb-1">{cat.title}</h3>
                  <p className="text-sm text-slate-500">{cat.blurb}</p>
                </div>
              ))}
            </div>
          )}
        </div>
      </section>

      {/* Popular Articles */}
      <section className="py-16 bg-slate-50/50">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
              Topics We Get <span className="text-gradient">Asked About</span>
            </h2>
            <p className="mt-3 text-slate-600 max-w-xl mx-auto">
              These guides are being written. Until each one is published, contact us and we will
              answer directly.
            </p>
          </div>

          {filteredTopics.length === 0 ? (
            <p className="text-center text-sm text-slate-600">
              No topics match your search — contact us and we will answer directly.
            </p>
          ) : (
            <div className="grid sm:grid-cols-2 gap-6">
              {filteredTopics.map((topic) => (
                <div
                  key={topic.title}
                  className="bg-white rounded-xl border border-slate-200 p-6"
                >
                  <h3 className="font-semibold text-slate-900 mb-1">{topic.title}</h3>
                  <p className="text-sm text-slate-600">{topic.brief}</p>
                  <span className="inline-flex items-center gap-1 text-sm text-slate-500 font-medium mt-3">
                    Guide coming soon
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </section>
    </>
  )
}
