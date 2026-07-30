export default function SectionHeader({
  title,
  highlight,
  description,
}: {
  title: string
  highlight?: string
  description: string
}) {
  return (
    <div className="text-center mb-12">
      <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
        {title}{" "}
        {highlight && <span className="text-gradient">{highlight}</span>}
      </h2>
      <p className="mt-3 text-slate-600 max-w-xl mx-auto">
        {description}
      </p>
    </div>
  )
}
