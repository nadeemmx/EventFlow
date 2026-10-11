"use client"

import Navbar from "@/components/landing/Navbar"
import Hero from "@/components/landing/Hero"
import TrustedBy from "@/components/landing/TrustedBy"
import Features from "@/components/landing/Features"
import Workflow from "@/components/landing/Workflow"
import DashboardShowcase from "@/components/landing/DashboardShowcase"
import Testimonials from "@/components/landing/Testimonials"
import PricingFAQ from "@/components/landing/PricingFAQ"
import CTA from "@/components/landing/CTA"
import Footer from "@/components/landing/Footer"

export default function Home() {
  return (
    <>
      <Navbar />
      <main id="main-content" tabIndex={-1} className="relative">
        <Hero />
        <TrustedBy />
        <Features />
        <Workflow />
        <DashboardShowcase />
        <Testimonials />
        <PricingFAQ />
        <CTA />
      </main>
      <Footer />
    </>
  )
}
