"use client"

import { useState, useEffect, useRef } from "react"
import { Menu, X } from "lucide-react"
import { motion, AnimatePresence } from "framer-motion"

const navLinks = [
  { label: "Features", href: "/features" },
  { label: "Pricing", href: "/pricing" },
  { label: "Demo", href: "/demo" },
  { label: "Blog", href: "/blog" },
]

export default function SiteHeader() {
  const [scrolled, setScrolled] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)
  const toggleRef = useRef<HTMLButtonElement>(null)
  const menuRef = useRef<HTMLElement>(null)
  const wasOpen = useRef(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 20)
    window.addEventListener("scroll", onScroll, { passive: true })
    return () => window.removeEventListener("scroll", onScroll)
  }, [])

  useEffect(() => {
    if (mobileOpen) {
      wasOpen.current = true
      menuRef.current?.querySelector<HTMLAnchorElement>("a")?.focus()
      const onKeyDown = (e: KeyboardEvent) => {
        if (e.key === "Escape") setMobileOpen(false)
      }
      window.addEventListener("keydown", onKeyDown)
      return () => window.removeEventListener("keydown", onKeyDown)
    }
    if (wasOpen.current) {
      wasOpen.current = false
      toggleRef.current?.focus()
    }
  }, [mobileOpen])

  return (
    <header
      className={`fixed top-0 inset-x-0 z-50 transition-all duration-300 ${
        scrolled ? "bg-white/80 backdrop-blur-xl border-b border-slate-200 shadow-sm" : "bg-transparent"
      }`}
    >
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-14 items-center justify-between">
          <a href="/" className="flex items-center gap-2">
            <div className="flex items-center justify-center w-7 h-7 rounded-lg bg-amber-500 text-slate-900 font-bold text-xs">
              EF
            </div>
            <span className="font-bold text-base tracking-tight">EventFlow</span>
          </a>

          <nav className="hidden md:flex items-center gap-7" aria-label="Primary">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="text-sm text-slate-600 hover:text-slate-900 transition-colors"
              >
                {link.label}
              </a>
            ))}
          </nav>

          <div className="hidden md:flex items-center gap-3">
            <a
              href="/login"
              className="text-sm font-medium text-slate-600 hover:text-slate-900 transition-colors"
            >
              Sign In
            </a>
            <a
              href="/signup"
              className="inline-flex items-center justify-center rounded-lg bg-amber-500 px-4 py-1.5 text-sm font-semibold text-slate-900 hover:bg-amber-600 transition-all"
            >
              Create your account
            </a>
          </div>

          <button
            ref={toggleRef}
            type="button"
            className="md:hidden cursor-pointer p-2 text-slate-600 hover:text-slate-900"
            onClick={() => setMobileOpen(!mobileOpen)}
            aria-label="Toggle menu"
            aria-expanded={mobileOpen}
            aria-controls="mobile-menu"
          >
            {mobileOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
        </div>
      </div>

      <AnimatePresence>
        {mobileOpen && (
          <motion.nav
            id="mobile-menu"
            aria-label="Mobile navigation"
            ref={menuRef}
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            className="md:hidden border-t border-slate-200 bg-white"
          >
            <div className="px-4 py-4 space-y-3">
              {navLinks.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  onClick={() => setMobileOpen(false)}
                  className="block text-sm text-slate-600 hover:text-slate-900 transition-colors py-2"
                >
                  {link.label}
                </a>
              ))}
              <div className="pt-2 flex flex-col gap-2">
                <a
                  href="/login"
                  className="text-center text-sm font-medium text-slate-600 hover:text-slate-900 transition-colors py-2"
                >
                  Sign In
                </a>
                <a
                  href="/signup"
                  className="text-center rounded-lg bg-amber-500 px-4 py-2.5 text-sm font-semibold text-slate-900 hover:bg-amber-600 transition-all"
                >
                  Create your account
                </a>
              </div>
            </div>
          </motion.nav>
        )}
      </AnimatePresence>
    </header>
  )
}
