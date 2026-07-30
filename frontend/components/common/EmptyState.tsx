import type { LucideIcon } from "lucide-react"
import { Button } from "@/components/ui/button"

interface EmptyStateProps {
  icon: LucideIcon
  title: string
  description?: string
  action?: {
    label: string
    onClick: () => void
  }
}

export function EmptyState({
  icon: Icon,
  title,
  description,
  action,
}: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
      <div className="flex items-center justify-center w-12 h-12 rounded-full bg-slate-200 mb-4">
        <Icon className="h-6 w-6 text-slate-600" />
      </div>
      <h3 className="text-sm font-semibold text-foreground ">{title}</h3>
      {description && (
        <p className="mt-1 text-sm text-slate-600 max-w-sm">
          {description}
        </p>
      )}
      {action && (
        <Button
          variant="outline"
          size="sm"
          className="mt-4 cursor-pointer"
          onClick={action.onClick}
        >
          {action.label}
        </Button>
      )}
    </div>
  )
}
