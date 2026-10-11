import { createMetadata } from "@/lib/seo"
import LegalPage, { LegalSection, LegalList } from "@/components/legal/LegalPage"
import BusinessField from "@/components/legal/BusinessField"
import { business } from "@/lib/business"

export const metadata = createMetadata({
  title: "GDPR & Data Protection",
  description:
    "How EventFlow approaches GDPR-style data protection: controller/processor roles, legal bases, your rights, transfers and breach handling.",
  path: "/gdpr",
})

export default function GdprPage() {
  return (
    <LegalPage
      title="Data"
      highlight="Protection"
      description="How EventFlow handles personal data in line with GDPR principles, and how to exercise your rights. Formal compliance certification has not been obtained — this page states what we actually do."
      updated={business.policyEffectiveDate}
      cta={{
        title: "Exercise your",
        highlight: "data rights",
        description:
          "Submit an access, correction, deletion or portability request online. We verify and track every request.",
        buttonText: "Submit a request",
        buttonHref: "/privacy-request",
      }}
    >
      <LegalSection id="roles" title="1. Controller and processor roles">
        <p>
          For account, billing, website and support data, EventFlow acts as{" "}
          <strong className="text-slate-900">data controller</strong>. Operating entity:{" "}
          <BusinessField value={business.legalName} label="Legal entity name" /> (
          <BusinessField value={business.address} label="Registered address" />
          ).
        </p>
        <p>
          For the personal data that venue businesses enter about their own customers, leads
          and staff, EventFlow acts as{" "}
          <strong className="text-slate-900">data processor</strong>, processing only on the
          documented instructions of that business. Requests about customer records held by a
          venue should be directed to that venue first; we will support them when instructed.
        </p>
        <p>
          Data protection contact:{" "}
          <a
            href={`mailto:${business.privacyEmail}`}
            className="underline text-slate-900"
          >
            {business.privacyEmail}
          </a>
          . A formally appointed Data Protection Officer or EU representative, where required:{" "}
          <BusinessField label="DPO / EU representative details" />.
        </p>
      </LegalSection>

      <LegalSection id="data" title="2. Data we process">
        <LegalList>
          <li>
            As controller — registration details (name, email, mobile, password hash, business
            name), sign-in technical data (IP address, user agent), support correspondence and
            billing records.
          </li>
          <li>
            As processor — the business records our customers choose to store: customers,
            leads, bookings, venues, invoices, payments, staff and vendors.
          </li>
          <li>
            We process only what is needed to run the service and do not use personal data for
            unrelated purposes. This website currently collects no behavioural analytics data.
          </li>
        </LegalList>
      </LegalSection>

      <LegalSection id="bases" title="3. Legal bases">
        <LegalList>
          <li>
            <strong className="text-slate-900">Contract</strong> — providing and billing the
            service you or your business signed up for.
          </li>
          <li>
            <strong className="text-slate-900">Legitimate interests</strong> — platform
            security, abuse prevention, audit logging and product improvement using
            aggregated, non-identifying operational data.
          </li>
          <li>
            <strong className="text-slate-900">Legal obligation</strong> — financial and tax
            record keeping.
          </li>
          <li>
            <strong className="text-slate-900">Consent</strong> — only for optional storage
            categories on this website and any future optional communications. Consent is
            freely given, recorded with a timestamp, and withdrawable without affecting
            essential service functions. We do not currently send marketing email.
          </li>
        </LegalList>
      </LegalSection>

      <LegalSection id="rights" title="4. Your rights">
        <p>
          Depending on your situation you may have rights to access, rectify, erase, restrict
          or object to processing, to receive your data in a portable format, and to withdraw
          consent. You may also complain to your local supervisory authority.
        </p>
        <p>
          Submit requests on our{" "}
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
          . We verify identity before acting, confirm receipt, aim to complete requests within
          30 days, and keep a record of each request and its status. Some records (invoices,
          payment and audit history) may be retained where the law requires it — we tell you
          what applies to your request.
        </p>
      </LegalSection>

      <LegalSection id="transfers" title="5. International transfers">
        <p>
          Primary hosting region:{" "}
          <BusinessField label="Hosting region" />. Where personal data is transferred outside
          your country — for example through payment, messaging or font providers — we rely on
          the safeguards required by applicable law (such as standard contractual clauses
          where they apply) and we keep the list of providers in our Privacy Policy current.
          The definitive hosting location and transfer analysis require confirmation from the
          business owner before this section is final.
        </p>
      </LegalSection>

      <LegalSection id="breach" title="6. Breach handling">
        <p>
          If a personal data breach is likely to result in a risk to individuals, we will
          notify the relevant supervisory authority within the timeframes required by
          applicable law (72 hours under the GDPR where it applies) and inform affected users
          where the law requires it, with the information the law specifies. Suspected
          breaches should be reported to{" "}
          <a
            href={`mailto:${business.privacyEmail}`}
            className="underline text-slate-900"
          >
            {business.privacyEmail}
          </a>
          .
        </p>
      </LegalSection>

      <LegalSection id="security" title="7. Security measures">
        <p>
          We apply the measures described in section 9 of our{" "}
          <a href="/privacy-policy/" className="underline text-slate-900">
            Privacy Policy
          </a>
          : transport encryption, salted password hashing, encrypted storage of integration
          secrets, per-tenant data isolation, role-based access control, audit logging and
          sign-in throttling. We do not claim a formal certification (such as SOC 2) or an
          independent penetration test, because neither has been completed.
        </p>
      </LegalSection>

      <LegalSection id="dpas" title="8. Processor obligations">
        <p>
          When we process on behalf of a venue business we act only on that business&apos;s
          instructions, restrict our own use of the data, apply appropriate security measures,
          help the business meet its own obligations (including data subject requests), and
          delete or return data when the engagement ends, subject to legal retention
          requirements. A written data processing agreement is available on request to
          business customers.
        </p>
      </LegalSection>

      <LegalSection id="scope" title="9. Status of this page">
        <p>
          This page describes EventFlow&apos;s current practices against GDPR principles. It
          is not a legal certification, and the jurisdiction in which EventFlow is established
          determines which obligations apply directly to us. Get independent legal advice if
          you need a formal compliance opinion.
        </p>
      </LegalSection>
    </LegalPage>
  )
}
