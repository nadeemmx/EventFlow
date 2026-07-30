import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"

export const metadata = createMetadata({
  title: "Cookie Policy",
  description: "EventFlow Cookie Policy. Learn about how we use cookies and similar tracking technologies on our platform.",
  path: "/cookie-policy",
})

const sections = [
  {
    title: "What Are Cookies",
    content:
      "Cookies are small text files that are placed on your device when you visit a website. They are widely used to make websites work more efficiently and provide information to website owners. Cookies enable the website to remember your actions and preferences over a period of time, so you do not have to re-enter them each time you return. Similar technologies such as local storage, pixels, and web beacons serve similar purposes.",
  },
  {
    title: "How We Use Cookies",
    content:
      "EventFlow uses cookies to enhance your experience, improve platform performance, and deliver relevant communications. Specifically, we use cookies for authentication and security to keep you logged in and protect your account. We use analytics cookies to understand how you interact with our platform, which helps us improve features and usability. We use functional cookies to remember your preferences and settings. Marketing cookies help us measure the effectiveness of our advertising campaigns.",
  },
  {
    title: "Types of Cookies We Use",
    content:
      "Strictly Necessary Cookies: These are essential for the platform to function properly. They enable core features such as account authentication, session management, and security. Without these cookies, the platform cannot operate correctly. Performance Cookies: These collect anonymous information about how you use our platform, such as which pages you visit most often and any error messages you encounter. This data helps us improve performance. Functionality Cookies: These remember your preferences and settings, such as language and region. Targeting Cookies: These track your browsing habits to deliver advertising relevant to you and your interests.",
  },
  {
    title: "Third-Party Cookies",
    content:
      "Some cookies on EventFlow are placed by trusted third-party services. We use Google Analytics to understand platform usage patterns. We may use advertising platforms such as Google Ads and LinkedIn to promote our services. These third parties may place cookies on your device. We do not control these cookies and recommend reviewing the privacy policies of these providers. We do not sell your personal data to third parties through cookies.",
  },
  {
    title: "Managing Cookies",
    content:
      "You can control and manage cookies in several ways. Most web browsers allow you to view, block, or delete cookies through their settings. You can set your browser to reject all cookies or to alert you when a cookie is being placed. Please note that blocking essential cookies may impair the functionality of our platform. You can also opt out of Google Analytics by installing the Google Analytics Opt-out Browser Add-on. To manage marketing cookies, you can visit the Network Advertising Initiative opt-out page.",
  },
  {
    title: "Updates to This Policy",
    content:
      "We may update this Cookie Policy from time to time to reflect changes in technology, regulation, or our practices. When we make material changes, we will notify you through the platform or via email. Your continued use of EventFlow after such changes constitutes acceptance of the updated policy. We encourage you to review this policy periodically. The date of the most recent update is indicated at the top of this policy.",
  },
  {
    title: "Contact Us",
    content:
      "If you have questions about our use of cookies or this Cookie Policy, please contact us at privacy@eventflow.com. You may also write to us at: EventFlow Inc., 100 Innovation Drive, Suite 300, San Francisco, CA 94105, United States.",
  },
]

export default function CookiePolicyPage() {
  return (
    <>
      <PageHero
        title="Cookie Policy"
        highlight=""
        description="Last updated: June 15, 2026. Learn about how EventFlow uses cookies and how you can manage them."
      />

      <section className="py-16 bg-slate-50/50">
        <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
          <p className="text-slate-600 leading-relaxed mb-8">
            This Cookie Policy explains what cookies are, how EventFlow uses them, and how you
            can manage your preferences. By continuing to use our platform, you consent to our
            use of cookies in accordance with this policy.
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
        title="Have questions about"
        highlight="cookies?"
        description="Our privacy team is available to answer any questions about how we use tracking technologies."
        buttonText="Contact Us"
        buttonHref="mailto:privacy@eventflow.com"
      />
    </>
  )
}
