import InventoryDetailClient from "./client";

export function generateStaticParams() {
  return [{ id: "new" }];
}

export default function InventoryDetailPage() {
  return <InventoryDetailClient />;
}
