import VendorDetailClient from "./client";

export function generateStaticParams() {
  return [{ id: "new" }];
}

export default function VendorDetailPage() {
  return <VendorDetailClient />;
}
