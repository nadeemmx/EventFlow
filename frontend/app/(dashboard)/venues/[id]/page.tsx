import VenueDetailClient from "./client";

export function generateStaticParams() {
  return [{ id: "new" }];
}

export default function VenueDetailPage() {
  return <VenueDetailClient />;
}
