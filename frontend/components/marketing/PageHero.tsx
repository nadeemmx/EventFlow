export default function PageHero({
  title,
  highlight,
  description,
}: {
  title: string
  highlight: string
  description: string
}) {
  return (
    <section className="pt-20 pb-16 sm:pt-24 sm:pb-20">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 text-center">
        <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight leading-[1.08]">
          {title}{" "}
          <span className="text-gradient">{highlight}</span>
        </h1>
        <p className="mt-4 text-base sm:text-lg text-slate-600 max-w-2xl mx-auto leading-relaxed">
          {description}
        </p>
      </div>
    </section>
  )
}
