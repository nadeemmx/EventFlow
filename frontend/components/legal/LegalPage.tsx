import PageHero from "@/components/marketing/PageHero"
import PageCTA from "@/components/marketing/PageCTA"
import type { ReactNode } from "react"

export function LegalSection({
  id,
  title,
  children,
}: {
  id: string
  title: string
  children: ReactNode
}) {
  return (
    <section id={id} className="scroll-mt-24">
      <h2 className="text-xl font-semibold text-slate-900 mb-3">{title}</h2>
      <div className="space-y-3 text-slate-600 leading-relaxed">{children}</div>
    </section>
  )
}

export function LegalList({ children }: { children: ReactNode }) {
  return <ul className="list-disc space-y-2 pl-5">{children}</ul>
}

export default function LegalPage({
  title,
  highlight,
  description,
  updated,
  children,
  cta,
}: {
  title: string
  highlight: string
  description: string
  updated?: string
  children: ReactNode
  cta?: {
    title: string
    highlight: string
    description: string
    buttonText: string
    buttonHref: string
  }
}) {
  return (
    <>
      <PageHero
        title={title}
        highlight={highlight}
        description={updated ? `Last updated: ${updated}. ${description}` : description}
      />

      <section className="py-16 bg-slate-50/50">
        <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 space-y-10">
          {children}
        </div>
      </section>

      {cta && (
        <PageCTA
          title={cta.title}
          highlight={cta.highlight}
          description={cta.description}
          buttonText={cta.buttonText}
          buttonHref={cta.buttonHref}
        />
      )}
    </>
  )
}
