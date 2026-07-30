export const fonts = {
  heading: "'Inter', -apple-system, BlinkMacSystemFont, sans-serif",
  body: "'Inter', -apple-system, BlinkMacSystemFont, sans-serif",
}

export const spacing = {
  section: "py-24 sm:py-32",
  container: "mx-auto max-w-7xl px-4 sm:px-6 lg:px-8",
}

export const effects = {
  cardHover:
    "transition-all duration-300 hover:-translate-y-1 hover:shadow-lg hover:shadow-amber-500/10",
  amberBorder:
    "border border-amber-500/30 hover:border-amber-500/60",
  amberGlow:
    "shadow-[0_0_15px_rgba(245,158,11,0.15)]",
  textAmber: "text-amber-500",
  bgAmberLight: "bg-amber-500/10",
}

export const buttonVariants = {
  primary:
    "bg-amber-500 text-slate-900 hover:bg-amber-600 font-semibold transition-all duration-200 hover:shadow-lg hover:shadow-amber-500/25 hover:-translate-y-0.5",
  secondary:
    "bg-transparent border-2 border-amber-500 text-amber-500 hover:bg-amber-500 hover:text-slate-900 font-semibold transition-all duration-200",
  ghost:
    "bg-transparent text-slate-600 hover:text-slate-900 hover:bg-slate-200 transition-colors duration-200",
  cta: "bg-amber-500 text-slate-900 hover:bg-amber-600 font-bold transition-all duration-200 hover:shadow-xl hover:shadow-amber-500/30 hover:-translate-y-1",
}

export const cardVariants = {
  default:
    "bg-white rounded-xl border border-amber-500/20 shadow-sm",
  hover:
    "bg-white rounded-xl border border-amber-500/20 shadow-sm transition-all duration-300 hover:-translate-y-1 hover:shadow-lg hover:shadow-amber-500/10 hover:border-amber-500/40",
  dashboard:
    "bg-white rounded-xl border border-amber-500/10 shadow-sm transition-all duration-200 hover:border-amber-500/30 hover:shadow-md",
}
