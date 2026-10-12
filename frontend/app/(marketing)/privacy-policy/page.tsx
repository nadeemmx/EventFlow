import { createMetadata } from "@/lib/seo"
import LegalPage, { LegalSection, LegalList } from "@/components/legal/LegalPage"
import BusinessField from "@/components/legal/BusinessField"
import { business } from "@/lib/business"

export const metadata = createMetadata({
  title: "Privacy Policy",
  description:
    "How EventFlow collects, uses, stores and protects personal data across the venue management platform.",
  path: "/privacy-policy",
})

export default function PrivacyPolicyPage() {
  return (
    <LegalPage
      title="Privacy"
      highlight="Policy"
      description="This policy explains what personal data EventFlow handles, why, and the choices you have. It reflects how the product actually works today."
      updated={business.policyEffectiveDate}
      cta={{
        title: "Questions or data",
        highlight: "requests?",
        description:
          "Submit a privacy request online, or contact our privacy team directly. We acknowledge every request.",
        buttonText: "Submit a privacy request",
        buttonHref: "/privacy-request",
      }}
    >
      <LegalSection id="who-we-are" title="1. Who we are and what this covers">
        <p>
          EventFlow is a software-as-a-service platform for event lawn, marriage hall and
          banquet venue businesses. The website and platform are operated under the brand{" "}
          <strong className="text-slate-900">EventFlow</strong>
          (<BusinessField value={business.legalName} label="Legal entity name" />
          ). Registered details:{" "}
          <BusinessField value={business.address} label="Registered address" />.
        </p>
        <p>
          This policy covers personal data processed through this website and the EventFlow
          application. It does not cover the websites or services of our customers (venue
          businesses), which have their own privacy policies for the end customers they deal
          with directly.
        </p>
        <p>
          <strong className="text-slate-900">Roles:</strong> For account, billing and website
          data, EventFlow acts as the data controller. For the customer, lead and booking
          records that venue businesses enter into the platform, EventFlow acts as a data
          processor acting on that business&apos;s instructions.
        </p>
      </LegalSection>

      <LegalSection id="data-we-collect" title="2. Personal data we collect">
        <p>
          <strong className="text-slate-900">Account and business information</strong> — when
          a business registers we collect the owner&apos;s full name, email address and password
          (stored only as a salted hash), and, where you provide them, a mobile number and
          business name. Within the platform we also store profile details you choose to add.
        </p>
        <p>
          <strong className="text-slate-900">Business records you enter</strong> — names,
          phone numbers, email addresses, addresses and notes for your customers, leads,
          staff and vendors; booking, venue, package, invoice and contract details; payment
          amounts and transaction references. Your customers&apos; and staff&apos;s personal
          data is entered by your business; you are responsible for having a lawful basis to
          provide it to EventFlow.
        </p>
        <p>
          <strong className="text-slate-900">Technical and security data</strong> — we record
          IP address, user agent and timestamps when you sign in, and IP address against
          significant actions in the audit log. Server request logs record method, path,
          status code and timing (user identity is recorded as an internal identifier, not a
          name or email address).
        </p>
        <p>
          <strong className="text-slate-900">Payment data</strong> — payments are processed
          by our payment partner (see section 6). We store the amount, status, order and
          transaction references; we do not store card numbers, CVV or UPI PINs.
        </p>
        <p>
          <strong className="text-slate-900">Device storage</strong> — the web application
          stores your access token, refresh token, basic profile and interface preferences
          in your browser&apos;s local storage. See the{" "}
          <a href="/cookie-policy/" className="underline text-slate-900">
            Cookie Policy
          </a>{" "}
          for the full list and your choices.
        </p>
        <p>
          <strong className="text-slate-900">What we do not collect</strong> — EventFlow does
          not currently load analytics, advertising or social-media trackers, does not set
          marketing cookies, and does not knowingly collect data from children.
        </p>
      </LegalSection>

      <LegalSection id="purposes" title="3. Why we process it, and on what basis">
        <LegalList>
          <li>
            To provide the service you or your business signed up for — accounts, bookings,
            invoicing, payments, notifications (contract and legitimate interests).
          </li>
          <li>
            To secure the platform: authentication, brute-force protection, audit logging and
            abuse prevention (legitimate interests / legitimate purposes under applicable
            law).
          </li>
          <li>
            To bill, collect payment and maintain financial records (contract and legal
            obligation).
          </li>
          <li>
            To send transactional messages — sign-in, password reset, booking and payment
            notifications, service messages. These are necessary to run the service.
          </li>
          <li>
            To respond to support and privacy requests (legitimate interests / your request).
          </li>
          <li>
            To improve the product using aggregated, non-identifying operational data
            (legitimate interests).
          </li>
        </LegalList>
        <p>
          Where a processing activity relies on consent (for example optional storage
          categories on this website), consent is optional, can be refused, and can be
          changed later without affecting essential service functionality.
        </p>
      </LegalSection>

      <LegalSection id="minimisation" title="4. Data minimisation">
        <p>
          We ask only for data needed to run the service. Fields that are not required are
          marked as optional in the product, and we do not require sensitive personal data
          (such as government identity numbers) for ordinary use of EventFlow. Tax identifiers
          such as GSTIN are collected only where you issue tax-compliant invoices and choose
          to provide them.
        </p>
      </LegalSection>

      <LegalSection id="sharing" title="5. Who we share data with">
        <p>
          We do not sell personal data. We share data only with service providers needed to
          run EventFlow, under appropriate contractual safeguards:
        </p>
        <LegalList>
          <li>
            <strong className="text-slate-900">Payment processing</strong> — Razorpay
            (payment gateway) processes payment details when you make a payment. Their
            privacy policy applies to that processing.
          </li>
          <li>
            <strong className="text-slate-900">Email delivery</strong> — the SMTP provider
            configured by your business (or our mail service in development) delivers
            transactional emails.
          </li>
          <li>
            <strong className="text-slate-900">WhatsApp messaging</strong> — if enabled by
            your business, messages go through a WhatsApp Business provider such as Twilio,
            Gupshup or Meta.
          </li>
          <li>
            <strong className="text-slate-900">Hosting and infrastructure</strong> — the
            servers and file storage that host EventFlow, including the primary hosting
            region: <BusinessField label="Hosting region" />.
          </li>
          <li>
            <strong className="text-slate-900">Legal obligations</strong> — where disclosure
            is required by law, regulation, legal process or to protect the rights, safety
            or property of EventFlow or others.
          </li>
        </LegalList>
      </LegalSection>

      <LegalSection id="transfers" title="6. International transfers">
        <p>
          EventFlow and its primary hosting are operated from:{" "}
          <BusinessField label="Operating country" />. Some providers
          (for example payment, messaging or font services) may process data in other
          countries. Where a transfer occurs, we rely on the safeguards required by
          applicable data protection law. Confirm your hosting region with your deployment
          provider before relying on this section.
        </p>
      </LegalSection>

      <LegalSection id="retention" title="7. How long we keep it">
        <LegalList>
          <li>
            Account data — for the life of the account, then deleted or anonymised after a
            confirmed deletion request, subject to the legal exceptions in section 10.
          </li>
          <li>Sign-in session records — until logout or token expiry, whichever comes first.</li>
          <li>
            Password reset codes — expire within 1 hour and are then removed.
          </li>
          <li>
            Audit log entries — retained for up to 365 days, after which they are removed by a
            scheduled cleanup job (configured in deployment).
          </li>
          <li>
            Invoices, payments and tax records — retained for the period required by tax and
            accounting law:{" "}
            <BusinessField label="Financial retention period" />.
          </li>
          <li>Backups — rotated according to the infrastructure provider&apos;s schedule.</li>
        </LegalList>
        <p>
          Exact retention periods beyond those above are a business decision and will be
          confirmed by the data controller before this section is published as final.
        </p>
      </LegalSection>

      <LegalSection id="cookies" title="8. Cookies and similar technologies">
        <p>
          This website does not use advertising or analytics cookies. We use strictly
          necessary local storage for sign-in and security, a stored record of your cookie
          choices, and an interface preference. Optional categories stay off unless you turn
          them on, and nothing optional loads before you decide. Full detail is in our{" "}
          <a href="/cookie-policy/" className="underline text-slate-900">
            Cookie Policy
          </a>
          , where you can also change your choices.
        </p>
      </LegalSection>

      <LegalSection id="security" title="9. How we protect it">
        <LegalList>
          <li>Encryption in transit using TLS when served over HTTPS.</li>
          <li>
            Passwords stored as salted hashes; payment gateway, SMTP and WhatsApp secrets
            encrypted at rest (AES-256-GCM).
          </li>
          <li>
            Role-based access control inside the product, with per-tenant data isolation so
            businesses only see their own records.
          </li>
          <li>
            Audit logging of significant actions, sign-in throttling and brute-force
            lockout protection.
          </li>
          <li>Security headers (HSTS, content-type and frame protections) on production.</li>
        </LegalList>
        <p>
          No method of transmission or storage is completely secure. We work to fix
          vulnerabilities promptly, but we cannot guarantee absolute security. EventFlow has
          not yet obtained SOC 2 certification or an independent penetration test; we do not
          claim either.
        </p>
      </LegalSection>

      <LegalSection id="rights" title="10. Your rights">
        <p>
          Depending on where you live, you may have the right to access, correct, delete or
          receive a copy of your personal data, to restrict or object to certain processing,
          and to withdraw consent where processing is consent-based. You may also have the
          right to complain to your local data protection authority.
        </p>
        <p>
          To exercise any right, submit a request on our{" "}
          <a href="/privacy-request/" className="underline text-slate-900">
            privacy requests page
          </a>{" "}
          or email{" "}
          <a
            href={`mailto:${business.privacyEmail}`}
            className="underline text-slate-900"
          >
            {business.privacyEmail}
          </a>
          . We verify the requester before acting, aim to acknowledge requests promptly and
          to respond within 30 days. Contact for privacy matters:{" "}
          <BusinessField value={business.address} label="Postal address" />.
        </p>
      </LegalSection>

      <LegalSection id="deletion" title="11. Account closure and deletion">
        <p>
          You can request account closure from the privacy requests page. When we action a
          deletion request we remove or anonymise the personal data covered by it, subject to
          these exceptions:
        </p>
        <LegalList>
          <li>
            Invoices, payment records and tax documents that we must keep to comply with
            financial law.
          </li>
          <li>
            Security and audit records limited to what is necessary for fraud prevention and
            dispute handling.
          </li>
          <li>
            Data we still hold as a processor for a venue business — that business must
            instruct us separately as the controller of those records.
          </li>
        </LegalList>
        <p>
          Because deleting a business account also affects financial history, permanent
          deletion is reviewed by our team before it is executed rather than applied
          automatically.
        </p>
      </LegalSection>

      <LegalSection id="children" title="12. Children&apos;s data and age">
        <p>
          EventFlow is a business-to-business product. Accounts are for people aged 18 or
          over who are acting for a business. The platform is not directed at children, and
          we do not knowingly create accounts for children or collect children&apos;s
          personal data. If you believe a child has provided personal data to us, contact{" "}
          <a
            href={`mailto:${business.privacyEmail}`}
            className="underline text-slate-900"
          >
            {business.privacyEmail}
          </a>{" "}
          and we will remove it.
        </p>
      </LegalSection>

      <LegalSection id="marketing" title="13. Communications">
        <p>
          We currently send only transactional email: password resets, security notices,
          booking/payment notifications and messages your business configures for its own
          customers. We do not send marketing email today, so there is nothing to unsubscribe
          from. If we ever add promotional email, it will be optional, clearly separated from
          service messages, and every promotional message will include a working unsubscribe
          link. Security and service messages will always be sent regardless of marketing
          preferences.
        </p>
      </LegalSection>

      <LegalSection id="third-party-content" title="14. Third-party content on this website">
        <p>
          This website loads the Inter typeface from Google Fonts (fonts.googleapis.com), so
          your browser requests those files directly from Google and Google receives your IP
          address. We do not embed advertising, social-media widgets or analytics scripts.
          Links to other websites are provided for convenience; their own policies apply to
          them.
        </p>
      </LegalSection>

      <LegalSection id="changes" title="15. Changes to this policy">
        <p>
          We may update this policy to reflect changes in the product or the law. The
          &quot;last updated&quot; date at the top shows when it last changed. For material
          changes that affect existing accounts, we will notify account owners through the
          platform or by email before the change takes effect.
        </p>
      </LegalSection>

      <LegalSection id="contact" title="16. Contact us">
        <p>
          Privacy questions and requests:{" "}
          <a
            href={`mailto:${business.privacyEmail}`}
            className="underline text-slate-900"
          >
            {business.privacyEmail}
          </a>
          . General support:{" "}
          <a
            href={`mailto:${business.supportEmail}`}
            className="underline text-slate-900"
          >
            {business.supportEmail}
          </a>
          . Business details: <BusinessField value={business.legalName} label="Legal entity name" />,{" "}
          <BusinessField value={business.address} label="Registered address" />, phone{" "}
          <BusinessField value={business.phone} label="Phone number" />.
        </p>
      </LegalSection>
    </LegalPage>
  )
}
