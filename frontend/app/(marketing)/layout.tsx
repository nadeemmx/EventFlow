import SiteHeader from "@/components/marketing/SiteHeader"
import Footer from "@/components/landing/Footer"

export default function MarketingLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <>
      <SiteHeader />
      <main id="main-content" tabIndex={-1} className="min-h-screen pt-14">
        {children}
      </main>
      <Footer />
    </>
  )
}
