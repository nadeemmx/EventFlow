import { createMetadata } from "@/lib/seo"
import LegalPage, { LegalSection, LegalList } from "@/components/legal/LegalPage"
import BusinessField from "@/components/legal/BusinessField"
import { business } from "@/lib/business"

export const metadata = createMetadata({
  title: "Refund Policy",
  description:
    "How EventFlow subscription billing, cancellations, duplicate payments and refund requests work.",
  path: "/refund-policy",
})

export default function RefundPolicyPage() {
  return (
    <LegalPage
      title="Refund"
      highlight="Policy"
      description="How billing, cancellation and refunds work for EventFlow subscriptions. Items still marked for decision are highlighted so nothing is promised that has not been agreed."
      updated={business.policyEffectiveDate}
      cta={{
        title: "Request a",
        highlight: "refund?",
        description:
          "Email our billing team with your account email and transaction reference and we will confirm next steps.",
        buttonText: `Email ${business.refundsEmail}`,
        buttonHref: `mailto:${business.refundsEmail}`,
      }}
    >
      <LegalSection id="scope" title="1. What this policy covers">
        <p>
          This policy applies to subscription fees paid for EventFlow by venue and event
          businesses. It does not cover payments your business collects from its own
          customers through the platform — those are between your business and its customers.
        </p>
      </LegalSection>

      <LegalSection id="billing" title="2. How billing works">
        <LegalList>
          <li>
            Subscriptions are billed in advance for the period you choose — monthly or
            annual — at the price shown on the{" "}
            <a href="/pricing/" className="underline text-slate-900">
              Pricing page
            </a>{" "}
            when you subscribe, plus any applicable tax.
          </li>
          <li>
            Payment is collected through our payment partner, Razorpay, using the payment
            method you provide there.
          </li>
          <li>
            Your plan runs until the end of the period you paid for. Renewal terms (whether a
            plan renews and charges automatically) are:{" "}
            <BusinessField label="Renewal / auto-charge rule" />.
          </li>
          <li>
            Free trial terms — length, included features and what happens when the trial
            ends — are: <BusinessField label="Trial terms" />.
          </li>
        </LegalList>
      </LegalSection>

      <LegalSection id="cancellation" title="3. Cancellation">
        <LegalList>
          <li>
            You can cancel at any time by contacting{" "}
            <a
              href={`mailto:${business.refundsEmail}`}
              className="underline text-slate-900"
            >
              {business.refundsEmail}
            </a>{" "}
            from your account email. (Self-service cancellation in the product:{" "}
            <BusinessField label="Self-service cancellation availability" />
            .)
          </li>
          <li>
            Cancellation stops future renewal charges. It takes effect at the end of the
            period you have already paid for, so the Service stays available until then.
          </li>
          <li>
            Cancelling does not automatically delete your data — see the{" "}
            <a href="/privacy-request/" className="underline text-slate-900">
              privacy requests page
            </a>{" "}
            and our <a href="/privacy-policy/" className="underline text-slate-900">Privacy Policy</a>.
          </li>
        </LegalList>
      </LegalSection>

      <LegalSection id="eligibility" title="4. When a refund is available">
        <p>We will refund a charge when any of the following applies:</p>
        <LegalList>
          <li>
            <strong className="text-slate-900">Duplicate payment</strong> — the same invoice
            or subscription was charged twice; the duplicate is refunded in full.{" "}
            <BusinessField label="Owner decision: confirm duplicate-charge rule" />
          </li>
          <li>
            <strong className="text-slate-900">Failed or incomplete payment</strong> — money
            was taken but the subscription was never activated; the amount is refunded in
            full.
          </li>
          <li>
            <strong className="text-slate-900">Billing error</strong> — you were overcharged
            or charged for a plan you did not select; the difference is refunded.
          </li>
          <li>
            <strong className="text-slate-900">Cooling-off or statutory right</strong> —
            where the law of your jurisdiction gives you a right to a refund or withdrawal
            period, that right applies in addition to this policy.
          </li>
        </LegalList>
        <p>
          For cancellations after a paid period has started, mid-term or pro-rata refunds are:{" "}
          <BusinessField label="Owner decision: pro-rata / change-of-mind refund rule" />.
          This decision must be approved by the business owner before this policy is
          published as final — no refund guarantee is implied until then.
        </p>
      </LegalSection>

      <LegalSection id="non-refundable" title="5. When a refund is not available">
        <p>
          Except where a refund is required by law, fees already paid for a period you have
          used are not refundable, and we do not refund for:
        </p>
        <LegalList>
          <li>
            Partial use of a paid billing period after cancellation (unless the decision above
            states otherwise).
          </li>
          <li>Downgrades between plans mid-period.</li>
          <li>
            Accounts suspended for breach of the{" "}
            <a href="/terms-of-service/" className="underline text-slate-900">
              Terms of Service
            </a>
            .
          </li>
          <li>
            Unused periods arising from your own decision not to use the Service while the
            account remains active.
          </li>
        </LegalList>
      </LegalSection>

      <LegalSection id="how-to-request" title="6. How to request a refund">
        <p>
          Email{" "}
          <a
            href={`mailto:${business.refundsEmail}`}
            className="underline text-slate-900"
          >
            {business.refundsEmail}
          </a>{" "}
          with:
        </p>
        <LegalList>
          <li>The email address registered to your EventFlow account.</li>
          <li>The payment or transaction reference from your receipt.</li>
          <li>The reason for the request.</li>
        </LegalList>
        <p>
          We acknowledge requests within:{" "}
          <BusinessField label="Owner decision: acknowledgement window" /> and decide on
          eligible requests within:{" "}
          <BusinessField label="Owner decision: decision window" />. Approved refunds are sent
          to the original payment method. From our side processing takes{" "}
          <BusinessField label="Owner decision: processing time" />; your bank or payment
          provider may take additional time to post it to your statement.
        </p>
      </LegalSection>

      <LegalSection id="disputes" title="7. Payment disputes and chargebacks">
        <p>
          If you believe a charge is wrong, contact us first at{" "}
          <a
            href={`mailto:${business.refundsEmail}`}
            className="underline text-slate-900"
          >
            {business.refundsEmail}
          </a>{" "}
          so we can resolve it quickly. Raising a chargeback with your bank before contacting
          us may delay resolution while the payment provider investigates. Amounts we are
          found not to owe will be re-billed with notice.
        </p>
      </LegalSection>

      <LegalSection id="currency" title="8. Currency">
        <p>
          Refunds are issued in the same currency as the original payment (Indian Rupees
          unless otherwise stated).
        </p>
      </LegalSection>

      <LegalSection id="legal" title="9. Legal status of this policy">
        <p>
          This document describes EventFlow&apos;s intended billing practices. It does not
          limit statutory rights you may have under applicable consumer or contract law.
          Sections marked for owner decision are not commitments until confirmed, and the
          full policy requires legal review before it is treated as final.
        </p>
      </LegalSection>

      <LegalSection id="contact" title="10. Contact">
        <p>
          Refund and billing questions:{" "}
          <a
            href={`mailto:${business.refundsEmail}`}
            className="underline text-slate-900"
          >
            {business.refundsEmail}
          </a>
          . General support:{" "}
          <a
            href={`mailto:${business.supportEmail}`}
            className="underline text-slate-900"
          >
            {business.supportEmail}
          </a>
          . Business details: <BusinessField value={business.legalName} label="Legal entity name" />,{" "}
          <BusinessField value={business.address} label="Registered address" />.
        </p>
      </LegalSection>
    </LegalPage>
  )
}
