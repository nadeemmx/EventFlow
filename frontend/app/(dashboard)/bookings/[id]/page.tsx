import BookingDetailClient from "./client";

export function generateStaticParams() {
  return [{ id: "new" }];
}

export default function BookingDetailPage() {
  return <BookingDetailClient />;
}
