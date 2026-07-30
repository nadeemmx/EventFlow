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
      <main className="min-h-screen pt-14">{children}</main>
      <Footer />
    </>
  )
}
