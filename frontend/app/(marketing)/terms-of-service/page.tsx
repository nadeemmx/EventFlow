import { createMetadata } from "@/lib/seo"
import LegalPage, { LegalSection, LegalList } from "@/components/legal/LegalPage"
import BusinessField from "@/components/legal/BusinessField"
import { business } from "@/lib/business"

export const metadata = createMetadata({
  title: "Terms of Service",
  description:
    "The terms that apply when you use EventFlow for your venue or event business, including accounts, billing and cancellation.",
  path: "/terms-of-service",
})

export default function TermsOfServicePage() {
  return (
    <LegalPage
      title="Terms of"
      highlight="Service"
      description="These terms govern your use of EventFlow. Read them together with our Privacy Policy, Refund Policy and Cookie Policy."
      updated={business.policyEffectiveDate}
      cta={{
        title: "Need anything",
        highlight: "clarified?",
        description:
          "Our team is happy to explain how billing, cancellation or data handling works before you sign up.",
        buttonText: "Contact us",
        buttonHref: `mailto:${business.generalEmail}`,
      }}
    >
      <LegalSection id="acceptance" title="1. Acceptance of these terms">
        <p>
          By creating an account or using EventFlow (&quot;the Service&quot;), you agree to
          these Terms of Service. If you use the Service for a business, you confirm that you
          have authority to bind that business, and &quot;you&quot; means that business. If
          you do not agree, do not use the Service.
        </p>
        <p>
          These terms are operated by <BusinessField value={business.legalName} label="Legal entity name" />{" "}
          (<BusinessField value={business.address} label="Registered address" />
          ). Governing law and dispute venue are set out in section 16 and are pending
          confirmation of the operating entity&apos;s jurisdiction.
        </p>
      </LegalSection>

      <LegalSection id="eligibility" title="2. Eligibility and age">
        <p>
          You must be at least 18 years old and capable of entering a binding contract to use
          the Service. The Service is intended for business use; it is not directed at
          children and accounts are not created for children. We do not currently run age
          verification — eligibility is a condition of use rather than a check we perform.
        </p>
      </LegalSection>

      <LegalSection id="accounts" title="3. Your account">
        <LegalList>
          <li>
            Provide accurate registration information and keep your email address current —
            it is your sign-in identity and where we send service notices.
          </li>
          <li>
            Keep your password confidential. You are responsible for activity that happens
            under your account until you notify us of unauthorised use.
          </li>
          <li>
            Notify us promptly at{" "}
            <a
              href={`mailto:${business.supportEmail}`}
              className="underline text-slate-900"
            >
              {business.supportEmail}
            </a>{" "}
            if you believe your account has been compromised.
          </li>
          <li>
            One account is for one business; do not share credentials outside your
            organisation or resell access without a separate written agreement.
          </li>
        </LegalList>
      </LegalSection>

      <LegalSection id="business-responsibilities" title="4. Venue and business owner responsibilities">
        <p>
          As the business operating on EventFlow, you are responsible for:
        </p>
        <LegalList>
          <li>
            The lawfulness of the personal data you enter about your customers, leads and
            staff — including having a valid basis to share it with us as your processor.
          </li>
          <li>
            Sending your own customers any notices your business is legally required to give
            (privacy notices, marketing consent, GST disclosures).
          </li>
          <li>
            The accuracy of bookings, invoices, quotations and tax details you generate
            through the Service.
          </li>
          <li>
            Managing access for your team members and the roles you grant them inside the
            product.
          </li>
        </LegalList>
      </LegalSection>

      <LegalSection id="acceptable-use" title="5. Acceptable use">
        <p>You agree not to:</p>
        <LegalList>
          <li>Use the Service for unlawful purposes or to violate others&apos; rights.</li>
          <li>
            Attempt to gain unauthorised access to other tenants&apos; data, probe or breach
            security, or interfere with the Service&apos;s operation.
          </li>
          <li>
            Scrape, harvest or copy data at scale, resell or sublicense the Service, or use
            it to build a competing product, except as permitted by law.
          </li>
          <li>
            Upload malicious code, or files that violate the law or third-party rights.
          </li>
          <li>
            Misrepresent your identity or your affiliation with any person or business.
          </li>
        </LegalList>
      </LegalSection>

      <LegalSection id="subscriptions" title="6. Subscription plans and billing">
        <LegalList>
          <li>
            Plans, features and prices are those shown on our{" "}
            <a href="/pricing/" className="underline text-slate-900">
              Pricing page
            </a>{" "}
            at the time you subscribe. Free trial details (length, features and what happens
            when it ends) are shown at signup:{" "}
            <BusinessField label="Trial terms" />.
          </li>
          <li>
            Subscription fees are billed in advance for the billing period you choose
            (monthly or annual). Prices are listed in Indian Rupees unless stated otherwise
            and exclude taxes you are responsible for.
          </li>
          <li>
            Your subscription runs for the paid term you select. Access continues until the
            end of that term. Whether a plan renews and charges automatically, and any
            renewal notice period, is:{" "}
            <BusinessField label="Renewal / auto-charge rule" /> — we will confirm this before
            this page is published as final.
          </li>
          <li>
            If a payment fails or a subscription expires, access may be restricted until the
            account is brought up to date.
          </li>
          <li>
            We may change prices or plan contents; changes apply from your next renewal after
            we notify the account owner.
          </li>
          <li>
            Refunds are governed by the{" "}
            <a href="/refund-policy/" className="underline text-slate-900">
              Refund Policy
            </a>
            .
          </li>
        </LegalList>
      </LegalSection>

      <LegalSection id="payments" title="7. Payments">
        <p>
          Payments are handled by our payment partner, Razorpay, whose terms and privacy
          policy apply to the payment itself. We receive payment status and transaction
          references; we do not store your card number, CVV or UPI credentials. You are
          responsible for all applicable taxes on the fees, and we charge tax where required
          by law.
        </p>
      </LegalSection>

      <LegalSection id="service" title="8. The service">
        <p>
          We work to keep EventFlow available and accurate, but the Service is provided on an
          &quot;as available&quot; basis. We may modify, add or remove features, and we may
          suspend the Service for maintenance or security. We do not promise uninterrupted or
          error-free operation, and any availability commitments only apply if they are set
          out in a separate written agreement with your business.
        </p>
      </LegalSection>

      <LegalSection id="suspension" title="9. Suspension and termination">
        <LegalList>
          <li>
            You may stop using EventFlow at any time. To close your account and understand
            what happens to your data, submit a request on our{" "}
            <a href="/privacy-request/" className="underline text-slate-900">
              privacy requests page
            </a>
            . Cancellation of a paid plan takes effect at the end of the paid term; details
            are in the <a href="/refund-policy/" className="underline text-slate-900">Refund Policy</a>.
          </li>
          <li>
            We may suspend or terminate access for material breach of these terms, non-payment,
            or where required by law, with notice where reasonably possible.
          </li>
          <li>
            On termination you lose access to the Service. Data deletion follows our Privacy
            Policy, subject to records we must keep by law. Data export before closure
            (format and window): <BusinessField label="Data export window" />.
          </li>
        </LegalList>
      </LegalSection>

      <LegalSection id="your-data" title="10. Your data and content">
        <p>
          You keep ownership of the data you and your business put into EventFlow. You grant
          us only the rights needed to store, process and back up that data to provide the
          Service to you and as otherwise described in our Privacy Policy. We do not use your
          customer data for our own marketing, and we do not sell it.
        </p>
      </LegalSection>

      <LegalSection id="ip" title="11. Intellectual property">
        <p>
          EventFlow — the software, design, branding and documentation — remains the property
          of EventFlow and its licensors. These terms do not transfer any ownership to you.
          You receive a limited, non-exclusive right to use the Service during your
          subscription. If you send us feedback, we may use it without obligation to you.
        </p>
      </LegalSection>

      <LegalSection id="third-parties" title="12. Third-party services">
        <p>
          The Service integrates with third parties such as Razorpay (payments) and, where
          enabled by your business, WhatsApp messaging providers and your chosen email
          provider. Their services are governed by their own terms. We are not responsible
          for the acts or omissions of third parties, though we remain responsible for our
          own obligations under these terms.
        </p>
      </LegalSection>

      <LegalSection id="disclaimers" title="13. Disclaimers">
        <p>
          Except as expressly stated in these terms, the Service is provided without other
          warranties, whether express or implied, including implied warranties of
          merchantability, fitness for a particular purpose and non-infringement, to the
          maximum extent permitted by law. Nothing in these terms excludes rights you may
          have under mandatory consumer or statutory law.
        </p>
      </LegalSection>

      <LegalSection id="liability" title="14. Limitation of liability">
        <p>
          To the maximum extent permitted by law, EventFlow is not liable for indirect,
          incidental, special, consequential or punitive damages, or for loss of profits,
          revenue, goodwill or data, arising from your use of the Service. Our total aggregate
          liability for claims relating to the Service is limited to the fees you paid to us
          in the 12 months before the event giving rise to the claim. These limits do not
          apply where liability cannot be limited by law.
        </p>
        <p>
          <em className="text-slate-500">
            This section is subject to review by the operating entity&apos;s legal counsel
            before publication as final.
          </em>
        </p>
      </LegalSection>

      <LegalSection id="indemnity" title="15. Indemnity">
        <p>
          You will defend and indemnify EventFlow against claims arising from your data being
          unlawful (for example data you had no right to collect), your misuse of the Service,
          or your breach of these terms, to the extent permitted by law. This does not cover
          claims caused by our own breach.
        </p>
      </LegalSection>

      <LegalSection id="law" title="16. Governing law and disputes">
        <p>
          These terms are governed by the laws of:{" "}
          <BusinessField value={business.jurisdiction} label="Governing jurisdiction" />.
          Disputes will be handled in the courts of:{" "}
          <BusinessField value={business.disputeVenue} label="Dispute venue" />.
        </p>
        <p>
          Before filing a claim, please contact us so we can try to resolve it — most issues
          are settled by a message to{" "}
          <a
            href={`mailto:${business.supportEmail}`}
            className="underline text-slate-900"
          >
            {business.supportEmail}
          </a>
          .
        </p>
        <p>
          <em className="text-slate-500">
            Jurisdiction and venue must be confirmed by the business owner against the
            operating entity&apos;s actual location before these terms are relied upon.
          </em>
        </p>
      </LegalSection>

      <LegalSection id="changes" title="17. Changes to these terms">
        <p>
          We may update these terms as the Service evolves or the law changes. The date at the
          top shows the latest version. For material changes that affect existing
          subscriptions, we will give account owners reasonable advance notice. Continued use
          after a change takes effect means you accept the updated terms.
        </p>
      </LegalSection>

      <LegalSection id="contact" title="18. Contact">
        <p>
          <BusinessField value={business.legalName} label="Legal entity name" />,{" "}
          <BusinessField value={business.address} label="Registered address" />. General{" "}
          <a
            href={`mailto:${business.generalEmail}`}
            className="underline text-slate-900"
          >
            {business.generalEmail}
          </a>
          , support{" "}
          <a
            href={`mailto:${business.supportEmail}`}
            className="underline text-slate-900"
          >
            {business.supportEmail}
          </a>
          , phone <BusinessField value={business.phone} label="Phone number" />.
        </p>
      </LegalSection>
    </LegalPage>
  )
}
