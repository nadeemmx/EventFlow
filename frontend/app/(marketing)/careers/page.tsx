import { createMetadata } from "@/lib/seo"
import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import SectionHeader from "@/components/marketing/SectionHeader"
import CareersApplyForm from "@/components/marketing/CareersApplyForm"

export const metadata = createMetadata({
  title: "Careers",
  description: "Join EventFlow and help transform the event venue industry",
  path: "/careers",
})

type Position = {
  title: string
  location: string
  type: string
  department: string
  description: string
  requirements: string[]
}

const positions: Position[] = []

export default function CareersPage() {
  return (
    <>
      <PageHero
        title="Join Us in Transforming"
        highlight="Event Venues"
        description="Build the future of venue management with a small, remote-first team."
      />

      <section className="bg-slate-50/50 py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Our Culture"
            description="How we work and what we value"
          />
          <div className="mx-auto max-w-3xl grid gap-6 sm:grid-cols-3">
            <div className="rounded-2xl border border-slate-200 bg-white p-6 text-center">
              <div className="mb-3 text-3xl">🌍</div>
              <h3 className="text-lg font-bold text-slate-900 mb-2">Remote-First</h3>
              <p className="text-sm text-slate-600">Work from wherever you are most productive. We do not require an office.</p>
            </div>
            <div className="rounded-2xl border border-slate-200 bg-white p-6 text-center">
              <div className="mb-3 text-3xl">📈</div>
              <h3 className="text-lg font-bold text-slate-900 mb-2">Growth Mindset</h3>
              <p className="text-sm text-slate-600">You will work on a product that is still being shaped, with room to learn and take on new areas.</p>
            </div>
            <div className="rounded-2xl border border-slate-200 bg-white p-6 text-center">
              <div className="mb-3 text-3xl">💡</div>
              <h3 className="text-lg font-bold text-slate-900 mb-2">Innovation</h3>
              <p className="text-sm text-slate-600">Every team member drives impact. We ship, learn from feedback, and continuously improve the platform.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Benefits & Perks"
            description="What we can offer, stated plainly"
          />
          <div className="mx-auto max-w-3xl rounded-2xl border border-slate-200 bg-white p-8">
            <p className="text-sm text-slate-700 leading-relaxed">
              Benefits, compensation, and work arrangements are agreed per role and confirmed in
              writing during the hiring process — we would rather tell you the real package for a
              real opening than list perks on a page that may not apply to you. Ask us anything
              about pay, leave, or setup when you get in touch.
            </p>
          </div>
        </div>
      </section>

      <section className="bg-slate-50/50 py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="Open Positions"
            description="Current roles are listed here as they open up"
          />
          <div className="space-y-6">
            {positions.length === 0 && (
              <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center">
                <h3 className="text-xl font-bold text-slate-900 mb-2">No open roles right now</h3>
                <p className="text-sm text-slate-600 leading-relaxed max-w-xl mx-auto">
                  We do not have any positions listed at the moment. If you would like to be
                  considered for future roles, send your resume to{" "}
                  <a
                    href="mailto:hello@eventflow.com"
                    className="font-medium text-amber-700 hover:text-amber-800 transition-colors"
                  >
                    hello@eventflow.com
                  </a>{" "}
                  and tell us what you do best.
                </p>
              </div>
            )}
            {positions.map((position) => (
              <div key={position.title} className="rounded-2xl border border-slate-200 bg-white overflow-hidden">
                <div className="p-8">
                  <div className="flex flex-wrap items-start justify-between gap-4 mb-4">
                    <div>
                      <h3 className="text-xl font-bold text-slate-900">{position.title}</h3>
                      <p className="text-sm text-slate-500">{position.department} · {position.location} · {position.type}</p>
                    </div>
                    <span className="inline-block rounded-full bg-amber-500/10 px-3 py-1 text-xs font-semibold text-amber-700">
                      {position.department}
                    </span>
                  </div>
                  <p className="text-sm text-slate-600 mb-4">{position.description}</p>
                  <div>
                    <h4 className="text-sm font-bold text-slate-900 mb-2">Requirements</h4>
                    <ul className="space-y-1.5">
                      {position.requirements.map((req) => (
                        <li key={req} className="flex items-start gap-2 text-sm text-slate-600">
                          <span className="mt-1.5 h-1.5 w-1.5 rounded-full bg-amber-500 flex-shrink-0" />
                          {req}
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="py-20">
        <div className="mx-auto max-w-2xl px-4 sm:px-6 lg:px-8">
          <SectionHeader
            title="General Applications"
            description="No role listed? Send us your details and we will keep them in mind for current and future openings"
          />
          <CareersApplyForm positions={positions.map((p) => p.title)} />
        </div>
      </section>

      <PageCTA
        title="Want to Know More?"
        highlight="Talk to Us"
        description="Not seeing the right role? Send us a note anyway — we are happy to hear from people who know venues."
        buttonText="Get in Touch"
        buttonHref="/contact"
      />
    </>
  )
}
