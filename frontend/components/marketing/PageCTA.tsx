export default function PageCTA({
  title,
  highlight,
  description,
  buttonText = "Create Your Account",
  buttonHref = "/signup",
}: {
  title: string
  highlight: string
  description: string
  buttonText?: string
  buttonHref?: string
}) {
  return (
    <section className="relative overflow-hidden bg-slate-900 py-20">
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-amber-500/5 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-1/4 w-80 h-80 bg-amber-500/5 rounded-full blur-3xl" />
      </div>
      <div className="relative mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 text-center">
        <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight text-white mb-4">
          {title}{" "}
          <br />
          <span className="text-gradient-dark">{highlight}</span>
        </h2>
        <p className="text-sm sm:text-base text-slate-400 max-w-md mx-auto mb-8 leading-relaxed">
          {description}
        </p>
        <a
          href={buttonHref}
          className="inline-flex items-center gap-2 rounded-xl bg-amber-500 px-7 py-3.5 text-base font-semibold text-slate-900 hover:bg-amber-600 transition-all hover:shadow-xl hover:shadow-amber-500/30"
        >
          {buttonText}
        </a>
      </div>
    </section>
  )
}
