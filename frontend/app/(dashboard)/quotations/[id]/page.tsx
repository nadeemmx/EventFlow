import QuotationDetailClient from "./client"
export function generateStaticParams() {
  return [{ id: "new" }];
}
export default function Page() { return <QuotationDetailClient /> }
