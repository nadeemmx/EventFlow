import { createMetadata } from "@/lib/seo"
import LegalPage, { LegalSection, LegalList } from "@/components/legal/LegalPage"
import BusinessField from "@/components/legal/BusinessField"
import { business } from "@/lib/business"

export const metadata = createMetadata({
  title: "Cookie Policy",
  description:
    "What cookies and browser storage EventFlow actually uses, and how to control your choices.",
  path: "/cookie-policy",
})

const storageItems = [
  {
    name: "access_token",
    type: "Local storage",
    purpose: "Keeps you signed in to the web app (JWT access token).",
    duration: "Until you sign out, the token expires, or sign-in state is cleared.",
    category: "Essential",
  },
  {
    name: "refresh_token",
    type: "Local storage",
    purpose: "Renews your session when the access token expires.",
    duration: "Until you sign out or the refresh token expires (24 hours).",
    category: "Essential",
  },
  {
    name: "user",
    type: "Local storage",
    purpose: "Basic profile shown in the interface (name, email, role, tenant).",
    duration: "Until you sign out.",
    category: "Essential",
  },
  {
    name: "eventflow_cookie_consent",
    type: "Local storage",
    purpose: "Records your cookie choices, the version of this policy and the date you chose.",
    duration: "Until you change your choices or clear site data.",
    category: "Essential",
  },
  {
    name: "theme",
    type: "Local storage",
    purpose: "Remembers light or dark appearance.",
    duration: "Persistent until changed or site data is cleared.",
    category: "Preferences",
  },
  {
    name: "sessionid",
    type: "Cookie (HttpOnly)",
    purpose:
      "Sign-in session for the Django administration site at /admin/ — used by administrators only, never by the web app.",
    duration: "Browser session.",
    category: "Essential",
  },
]

export default function CookiePolicyPage() {
  return (
    <LegalPage
      title="Cookie"
      highlight="Policy"
      description="An accurate list of what this website stores in your browser today — nothing more. Optional categories stay off until you turn them on."
      updated={business.policyEffectiveDate}
      cta={{
        title: "Change your",
        highlight: "choices any time",
        description:
          "Open cookie preferences from the footer of our marketing pages and from the dashboard sidebar to review or update what you allow.",
        buttonText: "Cookie Policy questions",
        buttonHref: `mailto:${business.privacyEmail}`,
      }}
    >
      <LegalSection id="what" title="1. What cookies and similar technologies are">
        <p>
          Cookies are small text files a website asks your browser to store. Similar
          technologies include local storage, which lets a site keep data in your browser
          without sending it to the server on every request, and session storage. This policy
          covers both cookies and local storage.
        </p>
      </LegalSection>

      <LegalSection id="current" title="2. What EventFlow uses today">
        <p>
          As of the date at the top of this page, the EventFlow website and web application
          set <strong className="text-slate-900">no analytics cookies, no advertising
          cookies and no social-media trackers</strong>, and load no third-party analytics or
          advertising scripts. What we do store:
        </p>
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-sm">
            <caption className="sr-only">
              Storage used by EventFlow, its purpose, duration and category
            </caption>
            <thead>
              <tr className="border-b border-slate-300 text-left text-slate-900">
                <th scope="col" className="py-2 pr-4 font-semibold">Name</th>
                <th scope="col" className="py-2 pr-4 font-semibold">Type</th>
                <th scope="col" className="py-2 pr-4 font-semibold">Purpose</th>
                <th scope="col" className="py-2 pr-4 font-semibold">Duration</th>
                <th scope="col" className="py-2 font-semibold">Category</th>
              </tr>
            </thead>
            <tbody className="text-slate-600">
              {storageItems.map((item) => (
                <tr key={item.name} className="border-b border-slate-200 align-top">
                  <th scope="row" className="py-3 pr-4 font-mono text-xs font-medium text-slate-900">
                    {item.name}
                  </th>
                  <td className="py-3 pr-4">{item.type}</td>
                  <td className="py-3 pr-4">{item.purpose}</td>
                  <td className="py-3 pr-4">{item.duration}</td>
                  <td className="py-3">{item.category}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p>
          Because auth tokens are stored in local storage rather than HttpOnly cookies, they
          are readable by scripts running on the page. We mitigate this with strict output
          practices and security headers, and we are evaluating moving tokens to HttpOnly
          cookies — see section 7.
        </p>
      </LegalSection>

      <LegalSection id="third-party" title="3. Third-party requests from this website">
        <LegalList>
          <li>
            <strong className="text-slate-900">Google Fonts</strong> — the site loads the
            Inter typeface from fonts.googleapis.com / fonts.gstatic.com. Your browser
            requests those files directly, so Google receives your IP address. Google may set
            its own cookies in the process; we do not control them.
          </li>
          <li>
            <strong className="text-slate-900">No other third-party scripts</strong> — no
            analytics, advertising, chat widget, tag manager or social embed is loaded on this
            website.
          </li>
          <li>
            <strong className="text-slate-900">Payment pages</strong> — when you pay, Razorpay
            handles the checkout. Any storage it uses is governed by Razorpay&apos;s own
            policy.
          </li>
        </LegalList>
      </LegalSection>

      <LegalSection id="choices" title="4. Your choices and how consent works">
        <LegalList>
          <li>
            A consent banner appears when we have no record of your choice. It explains the
            categories and offers three equal options: <em>Accept all</em>,{" "}
            <em>Reject non-essential</em> and <em>Manage preferences</em>.
          </li>
          <li>
            Optional categories are never pre-selected, and no optional technology loads
            before you make a choice. Browsing or scrolling the site is not treated as
            consent.
          </li>
          <li>
            Essential storage always stays on because the product cannot function without it —
            rejecting non-essential categories does not sign you out or break core features.
          </li>
          <li>
            You can change your mind at any time using{" "}
            <strong className="text-slate-900">Cookie preferences</strong> in the footer of
            our marketing pages, and from the dashboard sidebar. Your choice is stored with the
            policy version and a timestamp.
          </li>
        </LegalList>
      </LegalSection>

      <LegalSection id="browser" title="5. Browser controls">
        <p>
          You can also delete or block storage through your browser settings. Blocking all
          storage will sign you out and prevent you from staying signed in. Most browsers
          let you clear data for a single site, which is the simplest way to reset both your
          session and your consent record.
        </p>
      </LegalSection>

      <LegalSection id="updates" title="6. Updates to this policy">
        <p>
          If we ever add analytics, advertising or other optional technologies, they will be
          listed here first, the consent banner will describe them, and they will remain off
          until you opt in. We update the &quot;last updated&quot; date whenever this policy
          changes.
        </p>
      </LegalSection>

      <LegalSection id="security-note" title="7. Why we are revising storage">
        <p>
          We previously described analytics and advertising cookies that this site does not
          use, and treated continued browsing as consent — both have been removed. We are also
          reviewing whether authentication tokens can move from local storage to HttpOnly
          cookies for stronger protection against script-based theft; that change will be
          documented here when it ships.
        </p>
      </LegalSection>

      <LegalSection id="contact" title="8. Contact">
        <p>
          Questions about cookies or storage:{" "}
          <a
            href={`mailto:${business.privacyEmail}`}
            className="underline text-slate-900"
          >
            {business.privacyEmail}
          </a>
          . Business details: <BusinessField value={business.legalName} label="Legal entity name" />,{" "}
          <BusinessField value={business.address} label="Registered address" />. See also our{" "}
          <a href="/privacy-policy/" className="underline text-slate-900">
            Privacy Policy
          </a>
          .
        </p>
      </LegalSection>
    </LegalPage>
  )
}
