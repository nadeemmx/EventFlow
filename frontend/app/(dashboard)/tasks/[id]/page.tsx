import TaskDetailClient from "./client";

export function generateStaticParams() {
  return [{ id: "new" }];
}

export default function TaskDetailPage() {
  return <TaskDetailClient />;
}
