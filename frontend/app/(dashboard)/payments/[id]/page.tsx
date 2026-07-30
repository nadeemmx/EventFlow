import PaymentDetailClient from "./client";

export function generateStaticParams() {
  return [{ id: "new" }];
}

export default function PaymentDetailPage() {
  return <PaymentDetailClient />;
}
