import CustomerDetailClient from "./client";

export function generateStaticParams() {
  return [{ id: "new" }];
}

export default function CustomerDetailPage() {
  return <CustomerDetailClient />;
}
