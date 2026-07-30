import StaffDetailClient from "./client";

export function generateStaticParams() {
  return [{ id: "new" }];
}

export default function StaffDetailPage() {
  return <StaffDetailClient />;
}
