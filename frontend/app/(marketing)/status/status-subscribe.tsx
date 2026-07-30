"use client"

import { Bell } from "lucide-react"

export default function StatusSubscribe() {
  return (
    <section className="py-16 bg-slate-50/50">
      <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 text-center">
        <Bell className="w-10 h-10 text-amber-500 mx-auto mb-4" />
        <h2 className="text-2xl font-bold text-slate-900 mb-2">Subscribe to Status Updates</h2>
        <p className="text-slate-600 mb-6 max-w-md mx-auto">
          Get notified via email when we experience an incident or perform scheduled maintenance.
        </p>
        <form
          className="flex flex-col sm:flex-row gap-3 max-w-md mx-auto"
          onSubmit={(e) => e.preventDefault()}
        >
          <input
            type="email"
            placeholder="your@email.com"
            className="flex-1 px-4 py-3 rounded-xl border border-slate-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-amber-500/50"
          />
          <button
            type="submit"
            className="inline-flex items-center justify-center gap-2 rounded-xl bg-amber-500 px-6 py-3 text-sm font-semibold text-slate-900 hover:bg-amber-600 transition-all"
          >
            Subscribe
          </button>
        </form>
      </div>
    </section>
  )
}
