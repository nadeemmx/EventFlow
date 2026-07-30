import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"

export const metadata = createMetadata({
  title: "Terms of Service",
  description: "EventFlow Terms of Service. Understand the terms governing your use of the EventFlow venue management platform.",
  path: "/terms-of-service",
})

const sections = [
  {
    title: "Acceptance of Terms",
    content:
      "By accessing or using the EventFlow platform, you agree to be bound by these Terms of Service. If you are using the platform on behalf of an organization, you represent that you have the authority to bind that organization to these terms. If you do not agree to all of these terms, you may not access or use the platform. These terms constitute a legally binding agreement between you and EventFlow Inc.",
  },
  {
    title: "Account Terms",
    content:
      "You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must provide accurate, current, and complete information during the registration process. You may not share your account credentials with unauthorized users. You must notify us immediately of any unauthorized use of your account. We reserve the right to disable accounts that violate our terms or applicable laws.",
  },
  {
    title: "Payment Terms",
    content:
      "Subscription fees are billed in advance on a monthly or annual basis, as selected during registration. All fees are non-refundable except as expressly stated in our refund policy. We may change our fees upon 30 days notice. Late payments may result in service suspension. You are responsible for all applicable taxes, and we will charge tax where required by law. Payment processing is handled by our third-party payment processors in compliance with PCI DSS standards.",
  },
  {
    title: "Cancellation",
    content:
      "You may cancel your account at any time through your account settings. Upon cancellation, your subscription will remain active until the end of the current billing period. We will retain your data for 30 days after cancellation, after which it will be permanently deleted unless required otherwise by law. Refunds for unused portions of subscriptions are not provided unless otherwise specified in a written agreement.",
  },
  {
    title: "Limitation of Liability",
    content:
      "To the maximum extent permitted by law, EventFlow and its affiliates shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of profits, data, or business opportunities, arising out of or related to your use of the platform. Our total liability for any claims under these terms shall not exceed the amount you have paid us in the twelve months preceding the claim. This limitation does not apply to liability for gross negligence, fraud, or death or personal injury.",
  },
  {
    title: "Termination",
    content:
      "We may terminate or suspend your account immediately, without prior notice, if you breach these terms or engage in conduct that we believe could harm the platform or other users. Upon termination, your right to use the platform ceases immediately. We will make reasonable efforts to provide you with a copy of your data within 30 days of termination, subject to applicable law. Sections relating to payment, limitation of liability, and governing law shall survive termination.",
  },
  {
    title: "Governing Law",
    content:
      "These terms shall be governed by and construed in accordance with the laws of the State of California, without regard to its conflict of law provisions. Any disputes arising out of or relating to these terms shall be resolved exclusively in the federal or state courts located in San Francisco, California. The United Nations Convention on Contracts for the International Sale of Goods does not apply to these terms.",
  },
]

export default function TermsOfServicePage() {
  return (
    <>
      <PageHero
        title="Terms of Service"
        highlight=""
        description="Last updated: June 15, 2026. Please read these terms carefully before using EventFlow."
      />

      <section className="py-16 bg-slate-50/50">
        <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
          <p className="text-slate-600 leading-relaxed mb-8">
            These Terms of Service govern your use of the EventFlow platform and services.
            By accessing or using EventFlow, you agree to be bound by these terms. If you are
            using the platform on behalf of a business or organization, you represent that you
            have the authority to accept these terms on their behalf.
          </p>

          <div className="space-y-10">
            {sections.map((section) => (
              <div key={section.title}>
                <h2 className="text-xl font-semibold text-slate-900 mb-3">{section.title}</h2>
                <p className="text-slate-600 leading-relaxed">{section.content}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <PageCTA
        title="Ready to agree and"
        highlight="get started?"
        description="Join thousands of venues simplifying their operations with EventFlow."
        buttonText="Create Account"
        buttonHref="/login"
      />
    </>
  )
}
