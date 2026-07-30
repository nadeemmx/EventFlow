import InvoiceDetailClient from "./client";

export function generateStaticParams() {
  return [{ id: "new" }];
}

export default function InvoiceDetailPage() {
  return <InvoiceDetailClient />;
}
